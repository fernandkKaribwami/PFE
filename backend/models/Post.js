const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const PostSchema = new Schema({
  author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  text: String,
  mediaUrl: String,
  mediaType: String,
  hashtags: [String],
  mentions: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  likes: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  commentsCount: { type: Number, default: 0 },
  likesCount: { type: Number, default: 0 },
  savesCount: { type: Number, default: 0 },
  sharesCount: { type: Number, default: 0 },
  isPublic: { type: Boolean, default: true },
  isPinned: { type: Boolean, default: false },
  scheduledFor: Date,
  faculty: { type: Schema.Types.ObjectId, ref: 'Faculty' },
  group: { type: Schema.Types.ObjectId, ref: 'Group' }
},{ timestamps: true });
module.exports = mongoose.model('Post', PostSchema);