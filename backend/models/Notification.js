const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const NotificationSchema = new Schema({
  recipient: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  sender: { type: Schema.Types.ObjectId, ref: 'User' },
  type: { type: String, enum: ['like', 'comment', 'follow', 'message', 'group_invite', 'event_invite', 'announcement', 'admin'], required: true },
  relatedPost: { type: Schema.Types.ObjectId, ref: 'Post' },
  relatedComment: { type: Schema.Types.ObjectId, ref: 'Comment' },
  relatedGroup: { type: Schema.Types.ObjectId, ref: 'Group' },
  relatedEvent: { type: Schema.Types.ObjectId, ref: 'Event' },
  message: String,
  isRead: { type: Boolean, default: false },
  link: String
}, { timestamps: true });

module.exports = mongoose.model('Notification', NotificationSchema);
