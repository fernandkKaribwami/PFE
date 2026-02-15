const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const EventSchema = new Schema({
  title: { type: String, required: true },
  description: String,
  image: String,
  faculty: { type: Schema.Types.ObjectId, ref: 'Faculty' },
  group: { type: Schema.Types.ObjectId, ref: 'Group' },
  organizer: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  startDate: { type: Date, required: true },
  endDate: Date,
  location: String,
  category: { type: String, enum: ['conference', 'exam', 'seminar', 'workshop', 'sport', 'cultural', 'other'], default: 'other' },
  attendees: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  interested: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  maxAttendees: Number
}, { timestamps: true });

module.exports = mongoose.model('Event', EventSchema);
