const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Group = require('../models/Group');
const Post = require('../models/Post');

// Create group
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, category, privacy } = req.body;
    const group = new Group({
      name, description, category, privacy,
      admin: req.user.id,
      members: [req.user.id]
    });
    await group.save();
    res.json(group);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get all groups (paginated)
router.get('/', auth, async (req, res) => {
  const groups = await Group.find().populate('admin', 'name');
  res.json(groups);
});

// Get group by ID
router.get('/:id', auth, async (req, res) => {
  const group = await Group.findById(req.params.id).populate('admin members', 'name avatar');
  if (!group) return res.status(404).json({ msg: 'Group not found' });
  res.json(group);
});

// Join group
router.post('/:id/join', auth, async (req, res) => {
  const group = await Group.findById(req.params.id);
  if (!group) return res.status(404).json({ msg: 'Group not found' });
  if (group.members.includes(req.user.id)) return res.status(400).json({ msg: 'Already a member' });
  group.members.push(req.user.id);
  await group.save();
  res.json({ msg: 'Joined' });
});

// Leave group
router.post('/:id/leave', auth, async (req, res) => {
  const group = await Group.findById(req.params.id);
  if (!group) return res.status(404).json({ msg: 'Group not found' });
  group.members = group.members.filter(id => id.toString() !== req.user.id);
  await group.save();
  res.json({ msg: 'Left' });
});

// Get posts in group
router.get('/:id/posts', auth, async (req, res) => {
  const posts = await Post.find({ group: req.params.id }).populate('user', 'name avatar').sort('-createdAt');
  res.json(posts);
});

module.exports = router;