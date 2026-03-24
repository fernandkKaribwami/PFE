const mongoose = require('mongoose');

const FacultySchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  location: String,
  image: String
});

module.exports = mongoose.model('Faculty', FacultySchema);
