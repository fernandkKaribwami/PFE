const express = require('express');

const auth = require('../middleware/auth');
const Event = require('../models/Event');
const { createHttpError } = require('../utils/httpError');

const router = express.Router();

router.post('/', auth, async (req, res) => {
  const event = await Event.create({ ...req.body, createdBy: req.user.id });

  res.status(201).json({
    success: true,
    message: 'Evenement cree',
    event,
  });
});

router.get('/', auth, async (req, res) => {
  const filter = {};
  if (req.query.category) filter.category = req.query.category;
  if (req.query.faculty) filter.faculty = req.query.faculty;

  const events = await Event.find(filter)
    .populate('createdBy', 'name avatar')
    .populate('faculty', 'name slug image location')
    .lean();

  res.json({
    success: true,
    events,
  });
});

router.get('/:id', auth, async (req, res) => {
  const event = await Event.findById(req.params.id)
    .populate('createdBy', 'name avatar')
    .populate('attendees.user', 'name avatar')
    .populate('faculty', 'name slug image location')
    .lean();

  if (!event) {
    throw createHttpError(404, 'Evenement introuvable', 'EVENT_NOT_FOUND');
  }

  res.json({
    success: true,
    event,
  });
});

router.post('/:id/rsvp', auth, async (req, res) => {
  const { status } = req.body;
  const event = await Event.findById(req.params.id);

  if (!event) {
    throw createHttpError(404, 'Evenement introuvable', 'EVENT_NOT_FOUND');
  }

  const existing = event.attendees.find(
    (attendee) => attendee.user.toString() === req.user.id
  );

  if (existing) {
    existing.status = status;
  } else {
    event.attendees.push({ user: req.user.id, status });
  }

  await event.save();

  res.json({
    success: true,
    message: 'RSVP mis a jour',
  });
});

module.exports = router;
