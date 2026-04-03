const crypto = require('crypto');
const express = require('express');
const mongoose = require('mongoose');

const Faculty = require('../models/Faculty');
const User = require('../models/User');
const { verifyGoogleIdToken } = require('../utils/googleAuth');
const { createHttpError } = require('../utils/httpError');
const { signToken } = require('../utils/jwt');
const { getRequestBody } = require('../utils/request');
const { serializeUserSummary } = require('../utils/serializers');

const router = express.Router();
const isEmailVerificationRequired = () =>
  process.env.REQUIRE_EMAIL_VERIFICATION === 'true';

const resolveFacultyId = async (faculty) => {
  if (!faculty) {
    return null;
  }

  if (mongoose.isValidObjectId(faculty)) {
    return faculty;
  }

  const facultyDoc = await Faculty.findOne({
    name: { $regex: new RegExp(faculty, 'i') },
  });

  if (!facultyDoc) {
    throw createHttpError(
      400,
      `Faculte invalide: ${faculty}`,
      'INVALID_FACULTY'
    );
  }

  return facultyDoc._id;
};

const buildUserToken = async (user) => {
  return signToken(
    { user: { id: user._id.toString(), role: user.role } },
    { expiresIn: '7d' }
  );
};

router.post('/register', async (req, res) => {
  const body = getRequestBody(req);
  const { name, email, password, role, faculty, level, bio, avatar } = body;
  const normalizedEmail = email?.trim().toLowerCase();

  if (!name || !normalizedEmail || !password || !faculty) {
    throw createHttpError(
      400,
      'name, email, password et faculty sont requis',
      'MISSING_REQUIRED_FIELDS'
    );
  }

  const existingUser = await User.findOne({ email: normalizedEmail });
  if (existingUser) {
    throw createHttpError(400, 'Cet utilisateur existe deja', 'USER_EXISTS');
  }

  const facultyId = await resolveFacultyId(faculty);
  const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

  const user = await User.create({
    name,
    email: normalizedEmail,
    password,
    role,
    faculty: facultyId,
    level,
    bio: bio || '',
    avatar: avatar || '',
    verificationCode,
    emailVerified: !isEmailVerificationRequired(),
  });

  const populatedUser = await User.findById(user._id).populate(
    'faculty',
    'name slug image location'
  );
  const token = await buildUserToken(user);

  res.status(201).json({
    success: true,
    message: isEmailVerificationRequired()
      ? 'Utilisateur cree avec succes. Verification email requise'
      : 'Utilisateur cree avec succes',
    token,
    user: serializeUserSummary(populatedUser),
    verificationCode: !isEmailVerificationRequired()
      ? verificationCode
      : undefined,
  });
});

router.post('/verify-email', async (req, res) => {
  const body = getRequestBody(req);
  const { email, code, verificationCode } = body;
  const providedCode = code || verificationCode;
  const normalizedEmail = email?.trim().toLowerCase();

  if (!normalizedEmail || !providedCode) {
    throw createHttpError(
      400,
      'email et code sont requis',
      'MISSING_VERIFICATION_FIELDS'
    );
  }

  const user = await User.findOne({ email: normalizedEmail });
  if (!user || user.verificationCode !== providedCode) {
    throw createHttpError(400, 'Code de verification invalide', 'INVALID_CODE');
  }

  user.emailVerified = true;
  user.verificationCode = undefined;
  await user.save();

  res.json({
    success: true,
    message: 'Email verifie avec succes',
  });
});

router.post('/login', async (req, res) => {
  const body = getRequestBody(req);
  const { email, username, password } = body;
  const identifier = (email || username)?.trim();
  const normalizedIdentifier = identifier?.includes('@')
    ? identifier.toLowerCase()
    : identifier;

  if (!normalizedIdentifier || !password) {
    throw createHttpError(
      400,
      'email/username et password sont requis',
      'MISSING_LOGIN_FIELDS'
    );
  }

  const user = await User.findOne({
    $or: [{ email: normalizedIdentifier }, { name: normalizedIdentifier }],
  }).select('+password');

  if (!user) {
    throw createHttpError(
      400,
      'Identifiants invalides',
      'INVALID_CREDENTIALS'
    );
  }

  if (!user.emailVerified && !isEmailVerificationRequired()) {
    user.emailVerified = true;
    user.verificationCode = undefined;
    await user.save();
  }

  if (!user.emailVerified) {
    throw createHttpError(
      400,
      'Veuillez verifier votre email avant de vous connecter',
      'EMAIL_NOT_VERIFIED'
    );
  }

  if (user.blocked) {
    throw createHttpError(403, 'Compte bloque', 'ACCOUNT_BLOCKED');
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    throw createHttpError(
      400,
      'Identifiants invalides',
      'INVALID_CREDENTIALS'
    );
  }

  const token = await buildUserToken(user);
  const populatedUser = await User.findById(user._id).populate(
    'faculty',
    'name slug image location'
  );

  res.json({
    success: true,
    message: 'Connexion reussie',
    token,
    user: serializeUserSummary(populatedUser),
  });
});

router.post('/google', async (req, res) => {
  const body = getRequestBody(req);
  const { name, avatar, role, idToken } = body;

  if (!process.env.GOOGLE_CLIENT_ID) {
    throw createHttpError(
      500,
      'GOOGLE_CLIENT_ID manquant dans la configuration serveur',
      'GOOGLE_CONFIG_MISSING'
    );
  }

  const googleProfile = await verifyGoogleIdToken({
    idToken,
    expectedAudience: process.env.GOOGLE_CLIENT_ID,
  });
  const normalizedEmail = googleProfile.email;

  if (!normalizedEmail || !normalizedEmail.endsWith('@usmba.ac.ma')) {
    throw createHttpError(
      400,
      'Email universitaire @usmba.ac.ma requis',
      'INVALID_UNIVERSITY_EMAIL'
    );
  }

  let user = await User.findOne({ email: normalizedEmail });

  if (user?.blocked) {
    throw createHttpError(403, 'Compte bloque', 'ACCOUNT_BLOCKED');
  }

  if (!user) {
    user = await User.create({
      name:
        googleProfile.name ||
        name ||
        normalizedEmail.split('@')[0],
      email: normalizedEmail,
      password: crypto.randomBytes(20).toString('hex'),
      role: role || 'student',
      avatar: googleProfile.avatar || avatar || '',
      emailVerified: true,
    });
  }

  const token = await buildUserToken(user);
  const populatedUser = await User.findById(user._id).populate(
    'faculty',
    'name slug image location'
  );

  res.json({
    success: true,
    message: 'Connexion Google reussie',
    token,
    user: serializeUserSummary(populatedUser),
  });
});

router.post('/request-password-reset', async (req, res) => {
  const body = getRequestBody(req);
  const { email } = body;
  const normalizedEmail = email?.trim().toLowerCase();

  if (!normalizedEmail) {
    throw createHttpError(400, 'email requis', 'EMAIL_REQUIRED');
  }

  const user = await User.findOne({ email: normalizedEmail });
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const token = crypto.randomBytes(20).toString('hex');
  user.resetPasswordToken = token;
  user.resetPasswordExpires = Date.now() + 3600000;
  await user.save();

  res.json({
    success: true,
    message: 'Lien de reinitialisation genere',
    ...(process.env.NODE_ENV !== 'production' ? { token } : {}),
  });
});

router.post('/reset-password', async (req, res) => {
  const body = getRequestBody(req);
  const { token, resetCode, newPassword } = body;
  const providedToken = token || resetCode;

  if (!providedToken || !newPassword) {
    throw createHttpError(
      400,
      'token et newPassword sont requis',
      'MISSING_RESET_FIELDS'
    );
  }

  const user = await User.findOne({
    resetPasswordToken: providedToken,
    resetPasswordExpires: { $gt: Date.now() },
  });

  if (!user) {
    throw createHttpError(
      400,
      'Token invalide ou expire',
      'INVALID_RESET_TOKEN'
    );
  }

  user.password = newPassword;
  user.resetPasswordToken = undefined;
  user.resetPasswordExpires = undefined;
  await user.save();

  res.json({
    success: true,
    message: 'Mot de passe reinitialise avec succes',
  });
});

module.exports = router;
