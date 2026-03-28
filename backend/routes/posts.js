const express = require('express');

const auth = require('../middleware/auth');
const Comment = require('../models/Comment');
const Notification = require('../models/Notification');
const Post = require('../models/Post');
const Report = require('../models/Report');
const Save = require('../models/Save');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const { createAndEmitNotification, emitNotification } = require('../utils/notifications');
const { getRequestBody } = require('../utils/request');
const { createUpload } = require('../utils/uploads');
const {
  serializeComment,
  serializePost,
} = require('../utils/serializers');

const router = express.Router();
const upload = createUpload({ prefix: 'post', fileSize: 25 * 1024 * 1024 });

const postPopulateConfig = [
  {
    path: 'user',
    select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
    populate: { path: 'faculty', select: 'name slug image location' },
  },
  {
    path: 'mentions',
    select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
    populate: { path: 'faculty', select: 'name slug image location' },
  },
  {
    path: 'faculty',
    select: 'name slug image location',
  },
  {
    path: 'comments',
    options: { sort: { createdAt: -1 } },
    populate: {
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    },
  },
];

const normalizePostMedia = (req, media) => {
  const mediaItems = [];

  if (Array.isArray(media)) {
    mediaItems.push(...media.filter(Boolean));
  } else if (media) {
    mediaItems.push(media);
  }

  if (req.file) {
    mediaItems.unshift(`/uploads/${req.file.filename}`);
  }

  return Array.from(new Set(mediaItems));
};

const loadSerializedPost = async (postId, currentUserId) => {
  const post = await Post.findById(postId).populate(postPopulateConfig);
  if (!post) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  return serializePost(post, currentUserId);
};

router.post('/', auth, upload.single('image'), async (req, res) => {
  const body = getRequestBody(req);
  const { content, text, media, hashtags, mentions, group, faculty } = body;
  const normalizedContent = content || text || '';
  const normalizedMedia = normalizePostMedia(req, media);

  if (!normalizedContent.trim() && normalizedMedia.length === 0) {
    throw createHttpError(
      400,
      'Le post doit contenir du texte ou un media',
      'EMPTY_POST'
    );
  }

  const post = await Post.create({
    user: req.user.id,
    content: normalizedContent.trim(),
    media: normalizedMedia,
    hashtags: Array.isArray(hashtags)
      ? hashtags
      : typeof hashtags === 'string' && hashtags.length
        ? hashtags.split(',').map((item) => item.trim()).filter(Boolean)
        : [],
    mentions: Array.isArray(mentions)
      ? mentions
      : typeof mentions === 'string' && mentions.length
        ? mentions.split(',').map((item) => item.trim()).filter(Boolean)
        : [],
    group,
    faculty,
  });

  const serializedPost = await loadSerializedPost(post._id, req.user.id);

  const author = await User.findById(req.user.id).select('name followers');
  const followerIds = Array.isArray(author?.followers)
    ? author.followers
        .map((followerId) => followerId.toString())
        .filter((followerId) => followerId !== req.user.id.toString())
    : [];

  if (followerIds.length > 0) {
    const notifications = await Notification.insertMany(
      followerIds.map((followerId) => ({
        user: followerId,
        type: 'post',
        referenceId: post._id,
        content: `${author?.name || 'Un utilisateur'} a publie un nouveau post`,
      }))
    );

    notifications.forEach((notification) => {
      emitNotification(req.app, notification);
    });
  }

  res.status(201).json({
    success: true,
    message: 'Post cree avec succes',
    post: serializedPost,
  });
});

router.get('/', auth, async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));

  const currentUser = await User.findById(req.user.id).select('following');
  if (!currentUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  let filter = {
    user: { $in: [...currentUser.following, req.user.id] },
  };

  if (req.query.faculty) {
    filter = {
      $or: [{ faculty: req.query.faculty }, { user: req.user.id }],
    };
  }

  const totalPosts = await Post.countDocuments(filter);
  const posts = await Post.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate(postPopulateConfig)
    .lean();

  res.json({
    success: true,
    posts: posts.map((post) => serializePost(post, req.user.id)),
    pagination: {
      page,
      limit,
      total: totalPosts,
      hasMore: page * limit < totalPosts,
    },
  });
});

router.get('/user/:userId', auth, async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));
  const filter = { user: req.params.userId };

  const totalPosts = await Post.countDocuments(filter);
  const posts = await Post.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate(postPopulateConfig)
    .lean();

  res.json({
    success: true,
    posts: posts.map((post) => serializePost(post, req.user.id)),
    pagination: {
      page,
      limit,
      total: totalPosts,
      hasMore: page * limit < totalPosts,
    },
  });
});

router.post('/:id/like', auth, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  const currentIndex = post.likes.findIndex(
    (id) => id.toString() === req.user.id.toString()
  );

  let notification = null;

  if (currentIndex === -1) {
    post.likes.push(req.user.id);
    await post.save();

    if (post.user.toString() !== req.user.id.toString()) {
      const currentUser = await User.findById(req.user.id).select('name');
      notification = await createAndEmitNotification(req.app, {
        user: post.user,
        type: 'like',
        referenceId: post._id,
        content: `${currentUser?.name || 'Quelqu un'} a aime votre post`,
      });
    }
  } else {
    post.likes.splice(currentIndex, 1);
    await post.save();
  }

  const serializedPost = await loadSerializedPost(post._id, req.user.id);

  res.json({
    success: true,
    message: currentIndex === -1 ? 'Post aime' : 'Like retire',
    post: serializedPost,
    ...(notification ? { notification } : {}),
  });
});

router.post('/:id/comment', auth, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  const body = getRequestBody(req);
  const content = body.content || body.text;
  if (!content) {
    throw createHttpError(400, 'Commentaire requis', 'COMMENT_REQUIRED');
  }

  const comment = await Comment.create({
    user: req.user.id,
    post: req.params.id,
    content,
  });

  post.comments.push(comment._id);
  await post.save();

  let notification = null;
  if (post.user.toString() !== req.user.id.toString()) {
    const currentUser = await User.findById(req.user.id).select('name');
    notification = await createAndEmitNotification(req.app, {
      user: post.user,
      type: 'comment',
      referenceId: post._id,
      content: `${currentUser?.name || 'Quelqu un'} a commente votre post`,
    });
  }

  const populatedComment = await Comment.findById(comment._id)
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .lean();

  res.status(201).json({
    success: true,
    message: 'Commentaire ajoute',
    comment: serializeComment(populatedComment),
    ...(notification ? { notification } : {}),
  });
});

router.get('/:id/comments', auth, async (req, res) => {
  const comments = await Comment.find({ post: req.params.id })
    .sort({ createdAt: -1 })
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .lean();

  res.json({
    success: true,
    comments: comments.map((comment) => serializeComment(comment)),
  });
});

router.post('/:id/save', auth, async (req, res) => {
  const existingSave = await Save.findOne({
    user: req.user.id,
    post: req.params.id,
  });

  if (existingSave) {
    await existingSave.deleteOne();
    res.json({
      success: true,
      message: 'Post retire des sauvegardes',
    });
    return;
  }

  await Save.create({ user: req.user.id, post: req.params.id });
  res.json({
    success: true,
    message: 'Post sauvegarde',
  });
});

router.post('/:id/report', auth, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  const body = getRequestBody(req);
  const report = await Report.create({
    user: post.user,
    post: req.params.id,
    reportedBy: req.user.id,
    reason: body.reason,
    description: body.description || '',
  });

  res.status(201).json({
    success: true,
    message: 'Post signale',
    report: {
      _id: report._id.toString(),
      status: report.status,
    },
  });
});

router.delete('/:id', auth, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  if (post.user.toString() !== req.user.id && req.user.role !== 'admin') {
    throw createHttpError(403, 'Action non autorisee', 'FORBIDDEN');
  }

  await post.deleteOne();
  res.json({
    success: true,
    message: 'Post supprime',
  });
});

module.exports = router;
