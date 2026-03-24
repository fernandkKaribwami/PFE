const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true },
  media: [{ type: String }], // URLs
  hashtags: [String],
  mentions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  comments: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Comment' }],
  group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group' }, // if in group
  faculty: { type: mongoose.Schema.Types.ObjectId, ref: 'Faculty' }, // if in faculty feed
  isReported: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Post', PostSchema);