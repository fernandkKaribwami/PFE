const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const MessageSchema = new Schema({
  from: { type: Schema.Types.ObjectId, ref: 'User' },
  to: { type: Schema.Types.ObjectId, ref: 'User' },
  text: String
},{ timestamps: true });
MessageSchema.index({ participants: 1 });
module.exports = mongoose.model('Message', MessageSchema);