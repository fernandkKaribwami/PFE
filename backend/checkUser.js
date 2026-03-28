require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const user = await User.findOne({ email: 'testuser@example.com' });
    if (user) {
      console.log('User found:', user);
    } else {
      console.log('User not found');
    }

    await mongoose.connection.close();
    console.log('Connection closed');
  } catch (err) {
    console.error('Error:', err);
  }
})();