const express = require('express');

const auth = require('../middleware/auth');
const Story = require('../models/Story');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const { getRequestBody } = require('../utils/request');
const { createUpload, serializeUploadedFile } = require('../utils/uploads');
const { serializeStory } = require('../utils/serializers');

const router = express.Router();
const upload = createUpload({ prefix: 'story', fileSize: 25 * 1024 * 1024 });

const storyPopulateConfig = [
  {
    path: 'user',
    select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
    populate: { path: 'faculty', select: 'name slug image location' },
  },
];

const loadSerializedStory = async (storyId, currentUserId) => {
  const story = await Story.findById(storyId).populate(storyPopulateConfig);
  if (!story) {
    throw createHttpError(404, 'Story introuvable', 'STORY_NOT_FOUND');
  }

  return serializeStory(story, currentUserId);
};

router.get('/feed', auth, async (req, res) => {
  const currentUser = await User.findById(req.user.id).select('following');
  if (!currentUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const stories = await Story.find({
    user: {
      $in: [...currentUser.following, req.user.id],
    },
    expiresAt: { $gt: new Date() },
  })
    .sort({ createdAt: -1 })
    .populate(storyPopulateConfig)
    .lean();

  res.json({
    success: true,
    stories: stories.map((story) => serializeStory(story, req.user.id)),
  });
});

router.post('/', auth, upload.single('media'), async (req, res) => {
  const body = getRequestBody(req);
  const uploadedMedia = req.file ? serializeUploadedFile(req.file) : null;
  const mediaUrl = uploadedMedia?.url || body.mediaUrl || body.media;
  const mediaType = req.file?.mimetype || body.mediaType || uploadedMedia?.kind || 'image';
  const caption = (body.caption || '').toString().trim();

  if (!mediaUrl) {
    throw createHttpError(400, 'Un media est requis pour la story', 'STORY_MEDIA_REQUIRED');
  }

  const story = await Story.create({
    user: req.user.id,
    mediaUrl,
    mediaType,
    caption,
  });

  const serializedStory = await loadSerializedStory(story._id, req.user.id);
  const owner = await User.findById(req.user.id).select('followers');

  const io = req.app.get('io');
  if (io && owner) {
    const targetRoomIds = new Set([
      req.user.id.toString(),
      ...owner.followers.map((followerId) => followerId.toString()),
    ]);

    targetRoomIds.forEach((roomId) => {
      io.to(roomId).emit('storyCreated', serializedStory);
    });
  }

  res.status(201).json({
    success: true,
    message: 'Story publiee',
    story: serializedStory,
  });
});

router.post('/:id/view', auth, async (req, res) => {
  const story = await Story.findById(req.params.id);
  if (!story) {
    throw createHttpError(404, 'Story introuvable', 'STORY_NOT_FOUND');
  }

  if (story.expiresAt <= new Date()) {
    throw createHttpError(410, 'Cette story a expire', 'STORY_EXPIRED');
  }

  const hasViewed = story.viewers.some(
    (viewerId) => viewerId.toString() === req.user.id.toString()
  );

  if (!hasViewed) {
    story.viewers.push(req.user.id);
    await story.save();
  }

  res.json({
    success: true,
    story: await loadSerializedStory(req.params.id, req.user.id),
  });
});

router.delete('/:id', auth, async (req, res) => {
  const story = await Story.findById(req.params.id);
  if (!story) {
    throw createHttpError(404, 'Story introuvable', 'STORY_NOT_FOUND');
  }

  if (story.user.toString() !== req.user.id && req.user.role !== 'admin') {
    throw createHttpError(403, 'Action non autorisee', 'FORBIDDEN');
  }

  await story.deleteOne();

  const io = req.app.get('io');
  if (io) {
    io.to(story.user.toString()).emit('storyDeleted', {
      _id: story._id.toString(),
    });
  }

  res.json({
    success: true,
    message: 'Story supprimee',
  });
});

module.exports = router;
