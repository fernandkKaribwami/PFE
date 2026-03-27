const express = require('express');
const Post = require('../models/Post');
const router = express.Router();

// Get feed posts
router.get('/', async (req, res) => {
  try {
    const user = req.user;
    const posts = await Post.find({ user: { $in: user.following } }).populate('user').sort({ createdAt: -1 });
    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch feed' });
  }
});

module.exports = router;