const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Faculty = require('../models/Faculty');
const crypto = require('crypto');
const Notification = require('../models/Notification');
const bcrypt = require('bcrypt');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, faculty, level } = req.body;

    if (!name || !email || !password || !faculty) {
      return res.status(400).json({ message: 'name, email, password, and faculty are required' });
    }

    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ message: 'User already exists' });

    let facultyId = null;
    if (faculty) {
      if (mongoose.isValidObjectId(faculty)) {
        facultyId = faculty;
      } else {
        const facultyDoc = await Faculty.findOne({ name: { $regex: new RegExp(faculty, 'i') } });
        if (facultyDoc) {
          facultyId = facultyDoc._id;
        } else {
          return res.status(400).json({ message: `Invalid faculty: ${faculty}. Please provide a valid faculty name or ID.` });
        }
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    user = new User({
      name,
      email,
      password: hashedPassword,
      role,
      faculty: facultyId,
      level,
      verificationCode,
      emailVerified: false,
    });

    await user.save();

    const payload = { user: { id: user.id, role: user.role } };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        faculty: user.faculty,
        level: user.level,
      },
    });
  } catch (err) {
    console.error('❌ Error during registration:', err.message);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
  }
});

// Verify email
router.post('/verify-email', async (req, res) => {
  const { email, code } = req.body;
  const user = await User.findOne({ email });
  if (!user || user.verificationCode !== code) return res.status(400).json({ msg: 'Invalid code' });
  user.emailVerified = true;
  user.verificationCode = undefined;
  await user.save();
  res.json({ msg: 'Email verified' });
});

// Login
router.post('/login', async (req, res) => {
  const { email, username, password } = req.body;
  const identifier = email || username; // Accept both email and username

  try {
    const user = await User.findOne({ $or: [{ email: identifier }, { name: identifier }] });
    if (!user) return res.status(400).json({ msg: 'Invalid email/username or password' });
    if (!user.emailVerified) return res.status(400).json({ msg: 'Please verify your email first' });
    if (user.blocked) return res.status(403).json({ msg: 'Account blocked' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(400).json({ msg: 'Invalid email/username or password' });

    const payload = { user: { id: user.id, role: user.role } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
      if (err) {
        console.error('JWT signing failed:', err);
        return res.status(500).json({ message: 'Token generation failed', error: err.message });
      }

      res.json({
        token,
        user: { id: user.id, name: user.name, email: user.email, role: user.role, avatar: user.avatar },
      });
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ msg: 'Server error', error: err.message });
  }
});

// Google OAuth simulation endpoint
router.post('/google', async (req, res) => {
  try {
    const { name, email, avatar, role } = req.body;
    if (!email || !email.endsWith('@usmba.ac.ma')) {
      return res.status(400).json({ msg: 'Email universitaire @usmba.ac.ma requis' });
    }

    let user = await User.findOne({ email });
    if (!user) {
      user = new User({
        name: name || email.split('@')[0],
        email,
        password: crypto.randomBytes(20).toString('hex'),
        role: role || 'student',
        avatar: avatar || '',
        emailVerified: true,
      });
      await user.save();
    }

    const payload = { user: { id: user.id, role: user.role } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
      if (err) throw err;
      res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role, avatar: user.avatar } });
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
});

// Request password reset
router.post('/request-password-reset', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ msg: 'User not found' });
  const token = crypto.randomBytes(20).toString('hex');
  user.resetPasswordToken = token;
  user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
  await user.save();
  // Send email with token link
  res.json({ msg: 'Reset link sent to email', token });
});

// Reset password
router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  const user = await User.findOne({ resetPasswordToken: token, resetPasswordExpires: { $gt: Date.now() } });
  if (!user) return res.status(400).json({ msg: 'Invalid or expired token' });
  user.password = newPassword;
  user.resetPasswordToken = undefined;
  user.resetPasswordExpires = undefined;
  await user.save();
  res.json({ msg: 'Password reset successful' });
});

// Follow a user
router.post('/follow/:id', async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const currentUser = req.user;

    if (currentUser.id === targetUserId) {
      return res.status(400).json({ error: 'You cannot follow yourself' });
    }

    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (targetUser.followers.includes(currentUser.id)) {
      return res.status(400).json({ error: 'You are already following this user' });
    }

    targetUser.followers.push(currentUser.id);
    currentUser.following.push(targetUserId);

    await targetUser.save();
    await currentUser.save();

    const notification = new Notification({
      user: targetUserId,
      type: 'follow',
      message: `${currentUser.name} started following you`,
    });
    await notification.save();

    res.status(200).json({ message: 'Followed successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to follow user' });
  }
});

module.exports = router;