const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const Notification = require('../models/Notification');

// Get own user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ msg: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get user profile by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ msg: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Update profile
router.put('/:id', auth, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== 'admin') {
    return res.status(403).json({ msg: 'Not authorized' });
  }
  const { name, bio, faculty, level, interests, avatar } = req.body;
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { name, bio, faculty, level, interests, avatar }, { new: true });
    res.json(user);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Follow
router.post('/follow/:id', auth, async (req, res) => {
  if (req.user.id === req.params.id) return res.status(400).json({ msg: 'Cannot follow yourself' });
  const userToFollow = await User.findById(req.params.id);
  const currentUser = await User.findById(req.user.id);
  if (!userToFollow || !currentUser) return res.status(404).json({ msg: 'User not found' });
  if (currentUser.following.includes(req.params.id)) return res.status(400).json({ msg: 'Already following' });

  currentUser.following.push(req.params.id);
  userToFollow.followers.push(req.user.id);
  await currentUser.save();
  await userToFollow.save();

  // Create notification
  const notification = new Notification({
    user: req.params.id,
    type: 'follow',
    referenceId: req.user.id,
    content: `${currentUser.name} started following you`
  });
  await notification.save();

  res.json({ msg: 'Followed' });
});

// Unfollow
router.post('/unfollow/:id', auth, async (req, res) => {
  const userToUnfollow = await User.findById(req.params.id);
  const currentUser = await User.findById(req.user.id);
  if (!userToUnfollow || !currentUser) return res.status(404).json({ msg: 'User not found' });

  currentUser.following = currentUser.following.filter(id => id.toString() !== req.params.id);
  userToUnfollow.followers = userToUnfollow.followers.filter(id => id.toString() !== req.user.id);
  await currentUser.save();
  await userToUnfollow.save();

  res.json({ msg: 'Unfollowed' });
});

// Block user (admin only)
router.post('/block/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ msg: 'Admin only' });
  const user = await User.findById(req.params.id);
  if (!user) return res.status(404).json({ msg: 'User not found' });
  user.blocked = !user.blocked;
  await user.save();
  res.json({ msg: `User ${user.blocked ? 'blocked' : 'unblocked'}` });
});

module.exports = router;