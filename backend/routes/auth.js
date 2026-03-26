const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const crypto = require('crypto');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, faculty, level } = req.body;
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ msg: 'User already exists' });

    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    user = new User({ name, email, password, role, faculty, level, verificationCode });
    await user.save();

    // In production, send email with code
    res.json({ msg: 'User created. Please verify email.', code: verificationCode });
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
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
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ msg: 'Invalid credentials' });
  if (!user.emailVerified) return res.status(400).json({ msg: 'Please verify your email first' });
  if (user.blocked) return res.status(403).json({ msg: 'Account blocked' });

  const isMatch = await user.comparePassword(password);
  if (!isMatch) return res.status(400).json({ msg: 'Invalid credentials' });

  const payload = { user: { id: user.id, role: user.role } };
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
    if (err) throw err;
    res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role, avatar: user.avatar } });
  });
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

module.exports = router;