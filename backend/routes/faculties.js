const express = require('express');

const auth = require('../middleware/auth');
const Faculty = require('../models/Faculty');
const Post = require('../models/Post');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const { serializeFaculty, serializePost, serializeUserSummary } = require('../utils/serializers');

const router = express.Router();

router.get('/', async (req, res) => {
  const faculties = await Faculty.find().sort({ name: 1 }).lean();

  const facultyIds = faculties.map((faculty) => faculty._id);
  const usersPerFaculty = await User.aggregate([
    { $match: { faculty: { $in: facultyIds } } },
    { $group: { _id: '$faculty', count: { $sum: 1 } } },
  ]);

  const counts = usersPerFaculty.reduce((acc, entry) => {
    acc[entry._id.toString()] = entry.count;
    return acc;
  }, {});

  res.json(
    faculties.map((faculty) => ({
      ...serializeFaculty(faculty),
      membersCount: counts[faculty._id.toString()] || 0,
    }))
  );
});

router.get('/:id', async (req, res) => {
  const faculty = await Faculty.findById(req.params.id).lean();
  if (!faculty) {
    throw createHttpError(404, 'Faculte introuvable', 'FACULTY_NOT_FOUND');
  }

  res.json({
    success: true,
    faculty: serializeFaculty(faculty),
  });
});

router.get('/:id/posts', auth, async (req, res) => {
  const faculty = await Faculty.findById(req.params.id).lean();
  if (!faculty) {
    throw createHttpError(404, 'Faculte introuvable', 'FACULTY_NOT_FOUND');
  }

  const posts = await Post.find({ faculty: req.params.id })
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .populate({
      path: 'comments',
      populate: {
        path: 'user',
        select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
        populate: { path: 'faculty', select: 'name slug image location' },
      },
    })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();

  res.json({
    success: true,
    posts: posts.map((post) => serializePost(post, req.user.id)),
  });
});

router.get('/:id/members', auth, async (req, res) => {
  const faculty = await Faculty.findById(req.params.id).lean();
  if (!faculty) {
    throw createHttpError(404, 'Faculte introuvable', 'FACULTY_NOT_FOUND');
  }

  const members = await User.find({ faculty: req.params.id })
    .populate('faculty', 'name slug image location')
    .sort({ name: 1 })
    .lean();

  res.json({
    success: true,
    faculty: faculty.name,
    members: members.map((member) => serializeUserSummary(member)),
    count: members.length,
  });
});

router.post('/', auth, async (req, res) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }

  const { name, description, location, image } = req.body;
  if (!name || !name.trim()) {
    throw createHttpError(400, 'Le nom de la faculte est requis', 'NAME_REQUIRED');
  }

  const slug = name
    .toLowerCase()
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

  const faculty = await Faculty.create({
    name: name.trim(),
    slug,
    description: description || '',
    location: location || '',
    image: image || '',
  });

  res.status(201).json({
    success: true,
    message: 'Faculte creee',
    faculty: serializeFaculty(faculty),
  });
});

router.put('/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }

  const updateData = {};
  const { name, description, location, image } = req.body;

  if (name && name.trim()) {
    updateData.name = name.trim();
    updateData.slug = name
      .toLowerCase()
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  }
  if (description !== undefined) updateData.description = description;
  if (location !== undefined) updateData.location = location;
  if (image !== undefined) updateData.image = image;

  const faculty = await Faculty.findByIdAndUpdate(req.params.id, updateData, {
    new: true,
    runValidators: true,
  }).lean();

  if (!faculty) {
    throw createHttpError(404, 'Faculte introuvable', 'FACULTY_NOT_FOUND');
  }

  res.json({
    success: true,
    message: 'Faculte mise a jour',
    faculty: serializeFaculty(faculty),
  });
});

router.delete('/:id', auth, async (req, res) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }

  const faculty = await Faculty.findByIdAndDelete(req.params.id).lean();
  if (!faculty) {
    throw createHttpError(404, 'Faculte introuvable', 'FACULTY_NOT_FOUND');
  }

  res.json({
    success: true,
    message: 'Faculte supprimee',
  });
});

module.exports = router;
