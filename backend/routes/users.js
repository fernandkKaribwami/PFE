const express = require('express');
const mongoose = require('mongoose');

const auth = require('../middleware/auth');
const Faculty = require('../models/Faculty');
const Post = require('../models/Post');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const { createAndEmitNotification } = require('../utils/notifications');
const { getRequestBody } = require('../utils/request');
const { createUpload } = require('../utils/uploads');
const {
  serializeUserProfile,
} = require('../utils/serializers');

const router = express.Router();
const upload = createUpload({ prefix: 'avatar', fileSize: 10 * 1024 * 1024 });

const userPopulateConfig = [
  { path: 'faculty', select: 'name slug image location' },
  {
    path: 'followers',
    select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
    populate: { path: 'faculty', select: 'name slug image location' },
  },
  {
    path: 'following',
    select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
    populate: { path: 'faculty', select: 'name slug image location' },
  },
];

const resolveFacultyId = async (faculty) => {
  if (faculty === undefined) {
    return undefined;
  }

  if (faculty === null || faculty === '') {
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

const normalizeInterests = (interests) => {
  if (interests === undefined) {
    return undefined;
  }

  if (Array.isArray(interests)) {
    return interests.map((item) => item.toString().trim()).filter(Boolean);
  }

  if (typeof interests === 'string') {
    return interests
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
  }

  return [];
};

const loadMessageContacts = async (userId) => {
  const user = await User.findById(userId).populate(userPopulateConfig);
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const contacts = new Map();

  for (const relation of [...(user.following || []), ...(user.followers || [])]) {
    const relationId = relation?._id?.toString();
    if (!relationId || relationId === userId.toString()) {
      continue;
    }

    if (!contacts.has(relationId)) {
      contacts.set(relationId, serializeUserProfile(relation, {
        isFollowing: Array.isArray(user.following)
          ? user.following.some(
              (followingUser) => followingUser?._id?.toString() === relationId
            )
          : false,
        followersCount: Array.isArray(relation.followers)
          ? relation.followers.length
          : 0,
        followingCount: Array.isArray(relation.following)
          ? relation.following.length
          : 0,
      }));
    }
  }

  return Array.from(contacts.values()).sort((left, right) => {
    const leftName = left.name?.toString().toLowerCase() ?? '';
    const rightName = right.name?.toString().toLowerCase() ?? '';
    return leftName.localeCompare(rightName);
  });
};

const loadUserProfile = async (targetUserId, currentUserId) => {
  const user = await User.findById(targetUserId).populate(userPopulateConfig);
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const postsCount = await Post.countDocuments({ user: targetUserId });
  const followingIds = Array.isArray(user.followers)
    ? user.followers.map((follower) => follower._id.toString())
    : [];

  return serializeUserProfile(user, {
    postsCount,
    isFollowing: currentUserId
      ? followingIds.includes(currentUserId.toString())
      : false,
  });
};

const emitProfileUpdate = async (
  app,
  targetUserId,
  roomUserId = targetUserId,
  viewerUserId = roomUserId
) => {
  const io = app.get('io');
  if (!io) {
    return null;
  }

  const profile = await loadUserProfile(targetUserId, viewerUserId);
  io.to(roomUserId.toString()).emit('profileUpdated', profile);
  return profile;
};

router.get('/profile', auth, async (req, res) => {
  const profile = await loadUserProfile(req.user.id, req.user.id);
  res.json({
    success: true,
    user: profile,
  });
});

router.get('/contacts', auth, async (req, res) => {
  const contacts = await loadMessageContacts(req.user.id);

  res.json({
    success: true,
    contacts,
  });
});

router.put('/profile', auth, upload.single('avatar'), async (req, res) => {
  const body = getRequestBody(req);
  const { name, bio, faculty, level, interests, avatar } = body;
  const user = await User.findById(req.user.id);

  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  if (name !== undefined) {
    user.name = name.toString().trim();
  }

  if (bio !== undefined) {
    user.bio = bio;
  }

  if (faculty !== undefined) {
    user.faculty = await resolveFacultyId(faculty);
  }

  if (level !== undefined) {
    user.level = level;
  }

  const normalizedInterests = normalizeInterests(interests);
  if (normalizedInterests !== undefined) {
    user.interests = normalizedInterests;
  }

  if (req.file) {
    user.avatar = `/uploads/${req.file.filename}`;
  } else if (avatar !== undefined) {
    user.avatar = avatar;
  }

  await user.save();

  const populatedUser = await User.findById(req.user.id).populate(
    userPopulateConfig
  );

  const postsCount = await Post.countDocuments({ user: req.user.id });

  res.json({
    success: true,
    message: 'Profil mis a jour',
    user: serializeUserProfile(populatedUser, { postsCount }),
  });

  emitProfileUpdate(req.app, req.user.id).catch(() => {});
});

router.put('/profile/password', auth, async (req, res) => {
  const body = getRequestBody(req);
  const { currentPassword, newPassword, confirmPassword } = body;

  if (!currentPassword || !newPassword) {
    throw createHttpError(
      400,
      'currentPassword et newPassword sont requis',
      'MISSING_PASSWORD_FIELDS'
    );
  }

  if (newPassword.length < 6) {
    throw createHttpError(
      400,
      'Le nouveau mot de passe doit contenir au moins 6 caracteres',
      'WEAK_PASSWORD'
    );
  }

  if (confirmPassword !== undefined && newPassword !== confirmPassword) {
    throw createHttpError(
      400,
      'La confirmation du mot de passe ne correspond pas',
      'PASSWORD_CONFIRMATION_MISMATCH'
    );
  }

  const user = await User.findById(req.user.id).select('+password');
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const isCurrentPasswordValid = await user.comparePassword(currentPassword);
  if (!isCurrentPasswordValid) {
    throw createHttpError(
      400,
      'Mot de passe actuel incorrect',
      'INVALID_CURRENT_PASSWORD'
    );
  }

  user.password = newPassword;
  await user.save();

  res.json({
    success: true,
    message: 'Mot de passe mis a jour',
  });
});

router.get('/:id', auth, async (req, res) => {
  const profile = await loadUserProfile(req.params.id, req.user.id);
  res.json({
    success: true,
    user: profile,
  });
});

router.put('/:id', auth, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== 'admin') {
    throw createHttpError(403, 'Action non autorisee', 'FORBIDDEN');
  }

  const body = getRequestBody(req);
  const { name, bio, faculty, level, interests, avatar } = body;
  const updateData = {
    ...(name !== undefined ? { name } : {}),
    ...(bio !== undefined ? { bio } : {}),
    ...(faculty !== undefined ? { faculty } : {}),
    ...(level !== undefined ? { level } : {}),
    ...(interests !== undefined ? { interests } : {}),
    ...(avatar !== undefined ? { avatar } : {}),
  };

  const user = await User.findByIdAndUpdate(req.params.id, updateData, {
    new: true,
    runValidators: true,
  }).populate(userPopulateConfig);

  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const postsCount = await Post.countDocuments({ user: req.params.id });

  res.json({
    success: true,
    message: 'Profil mis a jour',
    user: serializeUserProfile(user, { postsCount }),
  });

  emitProfileUpdate(req.app, req.params.id).catch(() => {});
});

router.post('/follow/:id', auth, async (req, res) => {
  if (req.user.id === req.params.id) {
    throw createHttpError(400, 'Impossible de se suivre soi-meme', 'SELF_FOLLOW');
  }

  const [userToFollow, currentUser] = await Promise.all([
    User.findById(req.params.id),
    User.findById(req.user.id),
  ]);

  if (!userToFollow || !currentUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  if (currentUser.following.some((id) => id.toString() === req.params.id)) {
    throw createHttpError(400, 'Utilisateur deja suivi', 'ALREADY_FOLLOWING');
  }

  currentUser.following.push(userToFollow._id);
  userToFollow.followers.push(currentUser._id);
  await Promise.all([currentUser.save(), userToFollow.save()]);

  await createAndEmitNotification(req.app, {
    user: userToFollow._id,
    type: 'follow',
    referenceId: currentUser._id,
    content: `${currentUser.name} a commence a vous suivre`,
  });

  const updatedProfile = await loadUserProfile(req.params.id, req.user.id);

  await Promise.all([
    emitProfileUpdate(req.app, req.params.id, req.params.id, req.params.id),
    emitProfileUpdate(req.app, req.user.id, req.user.id, req.user.id),
  ]);

  res.json({
    success: true,
    message: 'Utilisateur suivi avec succes',
    user: updatedProfile,
  });
});

router.post('/unfollow/:id', auth, async (req, res) => {
  const [userToUnfollow, currentUser] = await Promise.all([
    User.findById(req.params.id),
    User.findById(req.user.id),
  ]);

  if (!userToUnfollow || !currentUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  currentUser.following = currentUser.following.filter(
    (id) => id.toString() !== req.params.id
  );
  userToUnfollow.followers = userToUnfollow.followers.filter(
    (id) => id.toString() !== req.user.id
  );
  await Promise.all([currentUser.save(), userToUnfollow.save()]);

  const updatedProfile = await loadUserProfile(req.params.id, req.user.id);

  await Promise.all([
    emitProfileUpdate(req.app, req.params.id, req.params.id, req.params.id),
    emitProfileUpdate(req.app, req.user.id, req.user.id, req.user.id),
  ]);

  res.json({
    success: true,
    message: 'Utilisateur retire des abonnements',
    user: updatedProfile,
  });
});

router.patch('/block/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }

  const user = await User.findById(req.params.id);
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  user.blocked = !user.blocked;
  await user.save();

  res.json({
    success: true,
    message: `Utilisateur ${user.blocked ? 'bloque' : 'debloque'}`,
    user: {
      _id: user._id.toString(),
      blocked: user.blocked,
    },
  });
});

router.post('/block/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }

  const user = await User.findById(req.params.id);
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  user.blocked = !user.blocked;
  await user.save();

  res.json({
    success: true,
    message: `Utilisateur ${user.blocked ? 'bloque' : 'debloque'}`,
    user: {
      _id: user._id.toString(),
      blocked: user.blocked,
    },
  });
});

module.exports = router;
