const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ReportSchema = new Schema({
  post: { type: Schema.Types.ObjectId, ref: 'Post' },
  user: { type: Schema.Types.ObjectId, ref: 'User' },
  comment: { type: Schema.Types.ObjectId, ref: 'Comment' },
  reportedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  reason: { type: String, enum: ['spam', 'abuse', 'harassment', 'inappropriate', 'other'], required: true },
  description: String,
  status: { type: String, enum: ['pending', 'reviewed', 'resolved', 'dismissed'], default: 'pending' },
  action: { type: String, enum: ['none', 'removed', 'suspended', 'banned'] }
}, { timestamps: true });

module.exports = mongoose.model('Report', ReportSchema);
