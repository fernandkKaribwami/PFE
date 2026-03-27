const express = require('express');
const multer = require('multer');
const auth = require('../middleware/auth');
const Post = require('../models/Post');
const router = express.Router();


const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({ storage });

// Create post
router.post('/', upload.single('image'), auth, async (req, res) => {
  try {
    const { content, media, hashtags, mentions, group, faculty } = req.body;
    const post = new Post({
      user: req.user.id,
      content,
      media,
      hashtags,
      mentions,
      group,
      faculty
    });
    await post.save();
    res.json(post);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get feed (paginated)
router.get('/', auth, async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = 10;
  try {
    const user = await User.findById(req.user.id);
    const following = user.following;
    const posts = await Post.find({ user: { $in: [...following, req.user.id] } })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('user', 'name avatar')
      .populate('comments');
    res.json(posts);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Like/Unlike post
router.post('/:id/like', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ msg: 'Post not found' });
    const index = post.likes.indexOf(req.user.id);
    if (index === -1) {
      post.likes.push(req.user.id);
      await post.save();
      // Create notification if not self-like
      if (post.user.toString() !== req.user.id) {
        const notification = new Notification({
          user: post.user,
          type: 'like',
          referenceId: post._id,
          content: `Someone liked your post`
        });
        await notification.save();
      }
      res.json({ msg: 'Liked' });
    } else {
      post.likes.splice(index, 1);
      await post.save();
      res.json({ msg: 'Unliked' });
    }
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Comment on post
router.post('/:id/comment', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ msg: 'Post not found' });
    const comment = new Comment({
      user: req.user.id,
      post: req.params.id,
      content: req.body.content
    });
    await comment.save();
    post.comments.push(comment._id);
    await post.save();
    // Notification
    if (post.user.toString() !== req.user.id) {
      const notification = new Notification({
        user: post.user,
        type: 'comment',
        referenceId: post._id,
        content: `Someone commented on your post`
      });
      await notification.save();
    }
    res.json(comment);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get comments for a post
router.get('/:id/comments', auth, async (req, res) => {
  try {
    const comments = await Comment.find({ post: req.params.id }).populate('user', 'name avatar');
    res.json(comments);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Save post
router.post('/:id/save', auth, async (req, res) => {
  const Save = require('../models/Save');
  const existing = await Save.findOne({ user: req.user.id, post: req.params.id });
  if (existing) {
    await existing.deleteOne();
    res.json({ msg: 'Unsaved' });
  } else {
    const save = new Save({ user: req.user.id, post: req.params.id });
    await save.save();
    res.json({ msg: 'Saved' });
  }
});

// Report post
router.post('/:id/report', auth, async (req, res) => {
  const Report = require('../models/Report');
  const report = new Report({ user: req.user.id, post: req.params.id, reason: req.body.reason });
  await report.save();
  res.json({ msg: 'Reported' });
});

// Delete post (author or admin)
router.delete('/:id', auth, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) return res.status(404).json({ msg: 'Post not found' });
  if (post.user.toString() !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ msg: 'Not authorized' });
  }
  await post.deleteOne();
  res.json({ msg: 'Post deleted' });
});

module.exports = router;