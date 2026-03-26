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
    res.json(faculties);
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

    const faculty = new Faculty({
      name,
      description,
      location,
      image
    });

    await faculty.save();
    res.json(faculty);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
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

    const faculty = await Faculty.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!faculty) {
      return res.status(404).json({ msg: 'Faculty not found' });
    }

    res.json(faculty);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
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