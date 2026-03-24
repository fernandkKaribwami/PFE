const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const Post = require('../models/Post');
const Report = require('../models/Report');

// Middleware: check admin role
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') return res.status(403).json({ msg: 'Admin only' });
  next();
};

// Dashboard stats
router.get('/dashboard', auth, adminOnly, async (req, res) => {
  const totalUsers = await User.countDocuments();
  const totalPosts = await Post.countDocuments();
  const totalReports = await Report.countDocuments({ status: 'pending' });
  res.json({ totalUsers, totalPosts, totalReports });
});

// Get all users (with filters)
router.get('/users', auth, adminOnly, async (req, res) => {
  const users = await User.find().select('-password');
  res.json(users);
});

// Get all reports
router.get('/reports', auth, adminOnly, async (req, res) => {
  const reports = await Report.find().populate('user post').populate('post', 'content user');
  res.json(reports);
});

// Resolve report
router.put('/reports/:id', auth, adminOnly, async (req, res) => {
  const report = await Report.findById(req.params.id);
  if (!report) return res.status(404).json({ msg: 'Report not found' });
  report.status = 'resolved';
  await report.save();
  res.json({ msg: 'Report resolved' });
});

// Delete user (admin)
router.delete('/users/:id', auth, adminOnly, async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ msg: 'User deleted' });
});

module.exports = router;