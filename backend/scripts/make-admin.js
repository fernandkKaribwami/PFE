const path = require('path');

const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');

const email = (process.argv[2] || '').trim().toLowerCase();

if (!email) {
  console.error('Usage: node scripts/make-admin.js <email>');
  process.exit(1);
}

if (!process.env.MONGODB_URI) {
  console.error('MONGODB_URI est introuvable dans backend/.env');
  process.exit(1);
}

const run = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const user = await User.findOneAndUpdate(
      { email },
      { $set: { role: 'admin', emailVerified: true } },
      { new: true }
    );

    if (!user) {
      console.error(`Utilisateur introuvable: ${email}`);
      process.exitCode = 1;
      return;
    }

    console.log(`Compte admin active pour ${user.email}`);
  } catch (error) {
    console.error('Activation admin impossible:', error.message);
    process.exitCode = 1;
  } finally {
    await mongoose.connection.close();
  }
};

run();
