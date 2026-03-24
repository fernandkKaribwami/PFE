const mongoose = require('mongoose');

const EventSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: String,
  image: String,
  location: String,
  startDate: Date,
  endDate: Date,
  capacity: Number,
  category: { type: String, enum: ['conference', 'exam', 'seminar', 'cultural', 'sports'] },
  faculty: { type: mongoose.Schema.Types.ObjectId, ref: 'Faculty' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  attendees: [{ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, status: { type: String, enum: ['going', 'interested'] } }]
}, { timestamps: true });

module.exports = mongoose.model('Event', EventSchema);
