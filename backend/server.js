const http = require('http');
const mongoose = require('mongoose');
require('dotenv').config();

const { createApp } = require('./app');
const { initializeSocket } = require('./socket');
const { backfillEmailVerificationIfDisabled } = require('./utils/userMaintenance');

const app = createApp();
const server = http.createServer(app);
const io = initializeSocket(server);
app.set('io', io);

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);

    const backfillResult = await backfillEmailVerificationIfDisabled();
    if (!backfillResult.skipped && backfillResult.modifiedCount > 0) {
      console.log(
        `Email verification disabled: ${backfillResult.modifiedCount} existing user(s) synchronized`
      );
    }

    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected');
    });

    mongoose.connection.on('reconnected', () => {
      console.log('MongoDB reconnected');
    });
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    setTimeout(connectDB, 5000);
  }
};

connectDB();

const gracefulShutdown = async (signal) => {
  console.log(`${signal} received, shutting down gracefully`);
  server.close(async () => {
    try {
      await mongoose.connection.close();
      console.log('MongoDB connection closed');
      process.exit(0);
    } catch (err) {
      console.error('Error closing MongoDB connection:', err);
      process.exit(1);
    }
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

const PORT = process.env.PORT || 5000;
server
  .listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  })
  .on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use.`);
      console.error(
        'Stop the other backend process or change PORT in backend/.env before restarting.'
      );
      process.exit(1);
    } else {
      throw err;
    }
  });

module.exports = {
  app,
  io,
  server,
};
