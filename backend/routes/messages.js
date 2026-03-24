const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Message = require('../models/Message');
const User = require('../models/User');

// Send message
router.post('/', auth, async (req, res) => {
  try {
    const { receiver, content } = req.body;
    const message = new Message({ sender: req.user.id, receiver, content });
    await message.save();
    res.json(message);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get conversation with another user
router.get('/:userId', auth, async (req, res) => {
  const messages = await Message.find({
    $or: [
      { sender: req.user.id, receiver: req.params.userId },
      { sender: req.params.userId, receiver: req.user.id }
    ]
  }).sort('createdAt');
  res.json(messages);
});

// Get list of conversations (unique users)
router.get('/conversations', auth, async (req, res) => {
  const messages = await Message.find({
    $or: [{ sender: req.user.id }, { receiver: req.user.id }]
  }).sort('-createdAt');
  const userIds = new Set();
  messages.forEach(msg => {
    if (msg.sender.toString() !== req.user.id) userIds.add(msg.sender.toString());
    if (msg.receiver.toString() !== req.user.id) userIds.add(msg.receiver.toString());
  });
  const users = await User.find({ _id: { $in: Array.from(userIds) } }).select('name avatar');
  res.json(users);
});

module.exports = router;