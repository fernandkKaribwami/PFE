const express = require('express');
const Faculty = require('../models/Faculty');
const User = require('../models/User');
const Post = require('../models/Post');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/faculties
// @desc    Get all faculties
// @access  Public
router.get('/', async (req, res) => {
  try {
    console.log('📚 GET /api/faculties - Fetching all faculties...');
    const faculties = await Faculty.find().sort({ name: 1 });
    console.log(`✓ Found ${faculties.length} faculties`);
    
    // Count members for each faculty
    const facultiesWithCounts = await Promise.all(
      faculties.map(async (faculty) => {
        const memberCount = await User.countDocuments({ faculty: faculty._id });
        return {
          ...faculty.toObject(),
          membersCount: memberCount
        };
      })
    );
    
    res.json(facultiesWithCounts);
  } catch (err) {
    console.error('❌ Error fetching faculties:', err.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du chargement des facultés',
      error: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
  }
});

// @route   GET /api/faculties/:id
// @desc    Get faculty by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) {
      return res.status(404).json({ message: 'Faculty not found' });
    }
    res.json(faculty);
  } catch (err) {
    console.error(err.message);
    if (err.kind === 'ObjectId') {
      return res.status(404).json({ message: 'Faculty not found' });
    }
    res.status(500).json({
      success: false,
      message: 'Erreur lors du chargement de la faculté',
      error: err.message
    });
  }
});

// @route   GET /api/faculties/:id/posts
// @desc    Get posts from faculty members
// @access  Private
router.get('/:id/posts', auth, async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) {
      return res.status(404).json({ message: 'Faculty not found' });
    }

    // Find users from this faculty
    const facultyUsers = await User.find({ faculty: req.params.id }).select('_id');

    // Get posts from these users
    const posts = await Post.find({
      author: { $in: facultyUsers.map(user => user._id) }
    })
    .populate('author', 'name avatar faculty')
    .sort({ createdAt: -1 })
    .limit(50);

    res.json(posts);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du chargement des posts de la faculté',
      error: err.message
    });
  }
});

// @route   GET /api/faculties/:id/members
// @desc    Get faculty members
// @access  Private
router.get('/:id/members', auth, async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) {
      return res.status(404).json({ message: 'Faculty not found' });
    }

    const members = await User.find({ faculty: req.params.id })
      .select('name avatar email role level')
      .sort({ name: 1 });

    res.json({
      faculty: faculty.name,
      members: members,
      count: members.length
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du chargement des membres de la faculté',
      error: err.message
    });
  }
});

// @route   POST /api/faculties
// @desc    Create a new faculty (Admin only)
// @access  Private/Admin
router.post('/', auth, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ msg: 'Access denied. Admin only.' });
    }

    const { name, description, location, image } = req.body;

    // Validate required fields
    if (!name || name.trim() === '') {
      return res.status(400).json({ message: 'Le nom de la faculté est requis' });
    }

    // Generate slug from name
    const slug = name
      .toLowerCase()
      .trim()
      .replace(/[àâ]/g, 'a')
      .replace(/[éèê]/g, 'e')
      .replace(/[ôo]/g, 'o')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    const faculty = new Faculty({
      name: name.trim(),
      slug,
      description: description || '',
      location: location || '',
      image: image || ''
    });

    await faculty.save();
    res.status(201).json(faculty);
  } catch (err) {
    console.error(err.message);
    if (err.code === 11000) {
      return res.status(400).json({ message: 'Cette faculté existe déjà' });
    }
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la faculté',
      error: err.message
    });
  }
});

// @route   PUT /api/faculties/:id
// @desc    Update faculty (Admin only)
// @access  Private/Admin
router.put('/:id', auth, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ msg: 'Access denied. Admin only.' });
    }

    const { name, description, location, image } = req.body;
    const updateData = {};

    // Update fields if provided
    if (name && name.trim() !== '') {
      updateData.name = name.trim();
      // Generate new slug if name is changed
      updateData.slug = name
        .toLowerCase()
        .trim()
        .replace(/[àâ]/g, 'a')
        .replace(/[éèê]/g, 'e')
        .replace(/[ôo]/g, 'o')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');
    }

    if (description !== undefined) updateData.description = description;
    if (location !== undefined) updateData.location = location;
    if (image !== undefined) updateData.image = image;

    const faculty = await Faculty.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!faculty) {
      return res.status(404).json({ msg: 'Faculté non trouvée' });
    }

    res.json(faculty);
  } catch (err) {
    console.error(err.message);
    if (err.code === 11000) {
      return res.status(400).json({ message: 'Cette faculté existe déjà' });
    }
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de la faculté',
      error: err.message
    });
  }
});

// @route   DELETE /api/faculties/:id
// @desc    Delete faculty (Admin only)
// @access  Private/Admin
router.delete('/:id', auth, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ msg: 'Access denied. Admin only.' });
    }

    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) {
      return res.status(404).json({ msg: 'Faculty not found' });
    }

    await Faculty.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Faculty removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;