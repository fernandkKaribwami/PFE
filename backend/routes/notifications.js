const express = require('express');

const auth = require('../middleware/auth');
const Notification = require('../models/Notification');
const { createHttpError } = require('../utils/httpError');
const { serializeNotification } = require('../utils/serializers');

const router = express.Router();

router.get('/', auth, async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));

  const [total, unreadCount] = await Promise.all([
    Notification.countDocuments({ user: req.user.id }),
    Notification.countDocuments({ user: req.user.id, read: false }),
  ]);
  const notifications = await Notification.find({ user: req.user.id })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  res.json({
    success: true,
    notifications: notifications.map((notification) =>
      serializeNotification(notification)
    ),
    unreadCount,
    pagination: {
      page,
      limit,
      total,
      hasMore: page * limit < total,
    },
  });
});

router.put('/:id/read', auth, async (req, res) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, user: req.user.id },
    { read: true },
    { new: true }
  ).lean();

  if (!notification) {
    throw createHttpError(
      404,
      'Notification introuvable',
      'NOTIFICATION_NOT_FOUND'
    );
  }

  res.json({
    success: true,
    message: 'Notification marquee comme lue',
    notification: serializeNotification(notification),
  });
});

router.put('/mark-all-read', auth, async (req, res) => {
  await Notification.updateMany({ user: req.user.id, read: false }, { read: true });

  res.json({
    success: true,
    message: 'Toutes les notifications sont lues',
  });
});

router.delete('/:id', auth, async (req, res) => {
  const notification = await Notification.findOneAndDelete({
    _id: req.params.id,
    user: req.user.id,
  }).lean();

  if (!notification) {
    throw createHttpError(
      404,
      'Notification introuvable',
      'NOTIFICATION_NOT_FOUND'
    );
  }

  res.json({
    success: true,
    message: 'Notification supprimee',
  });
});

module.exports = router;
