const Notification = require('../models/Notification');
const { serializeNotification } = require('./serializers');

const resolveRoomId = (value) => {
  if (!value) {
    return null;
  }

  if (typeof value === 'string') {
    return value;
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const emitNotification = (app, notification) => {
  const io = app?.get?.('io');
  const roomId = resolveRoomId(notification?.user);

  if (!io || !roomId) {
    return null;
  }

  const payload = serializeNotification(notification);
  io.to(roomId).emit('notification', payload);
  return payload;
};

const createAndEmitNotification = async (app, data) => {
  const notification = await Notification.create(data);
  emitNotification(app, notification);
  return notification;
};

module.exports = {
  createAndEmitNotification,
  emitNotification,
};
