const express = require('express');

const auth = require('../middleware/auth');
const Group = require('../models/Group');
const Post = require('../models/Post');
const { createHttpError } = require('../utils/httpError');
const { serializePost, serializeUserSummary } = require('../utils/serializers');

const router = express.Router();

router.post('/', auth, async (req, res) => {
  const { name, description, category, privacy } = req.body;

  const group = await Group.create({
    name,
    description,
    category,
    privacy,
    admin: req.user.id,
    members: [req.user.id],
  });

  res.status(201).json({
    success: true,
    message: 'Groupe cree',
    group,
  });
});

router.get('/', auth, async (req, res) => {
  const groups = await Group.find()
    .populate('admin', 'name avatar')
    .lean();

  res.json({
    success: true,
    groups,
  });
});

router.get('/:id', auth, async (req, res) => {
  const group = await Group.findById(req.params.id)
    .populate('admin', 'name avatar')
    .populate('members', 'name avatar email role')
    .lean();

  if (!group) {
    throw createHttpError(404, 'Groupe introuvable', 'GROUP_NOT_FOUND');
  }

  res.json({
    success: true,
    group,
  });
});

router.post('/:id/join', auth, async (req, res) => {
  const group = await Group.findById(req.params.id);
  if (!group) {
    throw createHttpError(404, 'Groupe introuvable', 'GROUP_NOT_FOUND');
  }

  if (group.members.some((id) => id.toString() === req.user.id)) {
    throw createHttpError(400, 'Utilisateur deja membre', 'ALREADY_MEMBER');
  }

  group.members.push(req.user.id);
  await group.save();

  res.json({
    success: true,
    message: 'Groupe rejoint',
  });
});

router.post('/:id/leave', auth, async (req, res) => {
  const group = await Group.findById(req.params.id);
  if (!group) {
    throw createHttpError(404, 'Groupe introuvable', 'GROUP_NOT_FOUND');
  }

  group.members = group.members.filter((id) => id.toString() !== req.user.id);
  await group.save();

  res.json({
    success: true,
    message: 'Groupe quitte',
  });
});

router.get('/:id/posts', auth, async (req, res) => {
  const posts = await Post.find({ group: req.params.id })
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .sort({ createdAt: -1 })
    .lean();

  res.json({
    success: true,
    posts: posts.map((post) => serializePost(post, req.user.id)),
  });
});

module.exports = router;
