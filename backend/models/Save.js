const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const SaveSchema = new Schema({
  post: { type: Schema.Types.ObjectId, ref: 'Post', required: true },
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true }
}, { timestamps: true });

SaveSchema.index({ post: 1, user: 1 }, { unique: true });

module.exports = mongoose.model('Save', SaveSchema);
