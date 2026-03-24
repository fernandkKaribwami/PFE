const mongoose = require('mongoose');

const GroupSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  category: { type: String, enum: ['class', 'club', 'department', 'sports', 'cultural'], required: true },
  privacy: { type: String, enum: ['public', 'private'], default: 'public' },
  avatar: String,
  cover: String,
  admin: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  posts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }]
}, { timestamps: true });

module.exports = mongoose.model('Group', GroupSchema);
