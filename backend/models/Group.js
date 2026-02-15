const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const GroupSchema = new Schema({
  name: { type: String, required: true },
  description: String,
  avatar: String,
  faculty: { type: Schema.Types.ObjectId, ref: 'Faculty' },
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  admins: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  members: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  isPrivate: { type: Boolean, default: false },
  category: { type: String, enum: ['class', 'club', 'filiere', 'sports', 'cultural', 'academic', 'other'], default: 'other' }
}, { timestamps: true });

module.exports = mongoose.model('Group', GroupSchema);
