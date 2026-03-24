const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Event = require('../models/Event');
const Notification = require('../models/Notification');

// Create event
router.post('/', auth, async (req, res) => {
  try {
    const event = new Event({ ...req.body, createdBy: req.user.id });
    await event.save();
    res.json(event);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// Get events (with filters)
router.get('/', auth, async (req, res) => {
  const { category, faculty } = req.query;
  const filter = {};
  if (category) filter.category = category;
  if (faculty) filter.faculty = faculty;
  const events = await Event.find(filter).populate('createdBy', 'name').populate('faculty');
  res.json(events);
});

// Get event by ID
router.get('/:id', auth, async (req, res) => {
  const event = await Event.findById(req.params.id).populate('createdBy attendees.user', 'name avatar');
  res.json(event);
});

// RSVP to event
router.post('/:id/rsvp', auth, async (req, res) => {
  const { status } = req.body; // 'going' or 'interested'
  const event = await Event.findById(req.params.id);
  if (!event) return res.status(404).json({ msg: 'Event not found' });
  const existing = event.attendees.find(a => a.user.toString() === req.user.id);
  if (existing) {
    existing.status = status;
  } else {
    event.attendees.push({ user: req.user.id, status });
  }
  await event.save();
  res.json({ msg: 'RSVP updated' });
});

module.exports = router;