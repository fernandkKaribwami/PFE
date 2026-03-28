const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const Group = require('../models/Group');
const Faculty = require('../models/Faculty');
const { serializePost, serializeUserSummary } = require('../utils/serializers');

router.get('/', auth, async (req, res) => {
  const { q } = req.query;
  if (!q) {
    res.json({ success: true, users: [], posts: [], groups: [], faculties: [] });
    return;
  }

  const users = await User.find({ name: { $regex: q, $options: 'i' } })
    .populate('faculty', 'name slug image location')
    .limit(5)
    .lean();
  const posts = await Post.find({ content: { $regex: q, $options: 'i' } })
    .limit(10)
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .lean();
  const groups = await Group.find({ name: { $regex: q, $options: 'i' } }).limit(5);
  const faculties = await Faculty.find({ name: { $regex: q, $options: 'i' } }).limit(5);

  res.json({
    success: true,
    users: users.map((user) => serializeUserSummary(user)),
    posts: posts.map((post) => serializePost(post, req.user.id)),
    groups,
    faculties,
  });
});

module.exports = router;
