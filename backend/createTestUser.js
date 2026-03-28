require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const user = new User({
      name: 'Test User',
      email: 'testuser@example.com',
      password: 'password123', // Will be hashed by the pre-save hook
      role: 'student',
      emailVerified: true,
    });

    await user.save();
    console.log('Test user created:', user);

    await mongoose.connection.close();
    console.log('Connection closed');
  } catch (err) {
    console.error('Error:', err);
  }
})();