const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: { type: String, enum: ['like', 'comment', 'follow', 'group_invite', 'event_reminder', 'faculty_announcement'] },
  referenceId: mongoose.Schema.Types.ObjectId,
  content: String,
  read: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', NotificationSchema);

module.exports = mongoose.model('Notification', NotificationSchema);
