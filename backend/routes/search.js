const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const Group = require('../models/Group');
const Faculty = require('../models/Faculty');

router.get('/', auth, async (req, res) => {
  const { q } = req.query;
  if (!q) return res.json({ users: [], posts: [], groups: [], faculties: [] });

  const users = await User.find({ name: { $regex: q, $options: 'i' } }).limit(5);
  const posts = await Post.find({ content: { $regex: q, $options: 'i' } }).limit(10).populate('user', 'name avatar');
  const groups = await Group.find({ name: { $regex: q, $options: 'i' } }).limit(5);
  const faculties = await Faculty.find({ name: { $regex: q, $options: 'i' } }).limit(5);

  res.json({ users, posts, groups, faculties });
});

module.exports = router;