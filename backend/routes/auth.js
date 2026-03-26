const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Faculty = require('../models/Faculty');
const crypto = require('crypto');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, faculty, level } = req.body;

    if (!name || !email || !password || !faculty) {
      return res.status(400).json({ message: 'name, email, password and faculty are required' });
    }

    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ message: 'User already exists' });

    let facultyId = null;
    if (faculty) {
      if (mongoose.isValidObjectId(faculty)) {
        facultyId = faculty;
      } else {
        // try exact, case-insensitive, fuzzy match
        let facultyDoc = await Faculty.findOne({ name: faculty });
        if (!facultyDoc) {
          facultyDoc = await Faculty.findOne({ name: { $regex: new RegExp(`^${faculty.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } });
        }
        if (!facultyDoc) {
          facultyDoc = await Faculty.findOne({ name: { $regex: faculty, $options: 'i' } });
        }

        if (facultyDoc) {
          facultyId = facultyDoc._id;
        } else {
          return res.status(400).json({ message: `Faculté invalide : ${faculty}. Envoyez l'ID de la faculté ou un nom exact.` });
        }
      }
    }

    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    user = new User({
      name,
      email,
      password,
      role,
      faculty: facultyId,
      level,
      verificationCode,
      emailVerified: false,
    });

    await user.save();

    const payload = { user: { id: user.id, role: user.role } };
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
      if (err) {
        console.error('JWT signing failed:', err);
        return res.status(500).json({ message: 'Token generation failed', error: err.message });
      }

      return res.status(201).json({
        message: 'User created. Please verify email.',
        code: verificationCode,
        token,
        user: { id: user.id, name: user.name, email: user.email, role: user.role, avatar: user.avatar },
      });
    });
  } catch (err) {
    console.error('Registration error:', err);

    if (err.name === 'ValidationError') {
      const message = Object.values(err.errors).map(val => val.message).join(', ');
      return res.status(400).json({ message });
    }

    return res.status(500).json({ message: 'Server error', error: err.message });
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
    if (err) {
      console.error('JWT sign error on login:', err);
      return res.status(500).json({ message: 'Token generation failed', error: err.message });
    }
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