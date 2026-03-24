const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const http = require('http');
const socketio = require('socket.io');
const path = require('path');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const postRoutes = require('./routes/posts');
const groupRoutes = require('./routes/groups');
const eventRoutes = require('./routes/events');
const messageRoutes = require('./routes/messages');
const adminRoutes = require('./routes/admin');
const searchRoutes = require('./routes/search');
const facultyRoutes = require('./routes/faculties');

// Import middleware
const { errorHandler } = require('./middleware/errorHandler');
const { notFound } = require('./middleware/notFound');

const app = express();
const server = http.createServer(app);

// Socket.IO configuration with CORS
const io = socketio(server, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:3000",
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling']
});

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// API rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 auth requests per windowMs
  message: 'Too many authentication attempts, please try again later.',
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// Compression
app.use(compression());

// CORS configuration
app.use(cors({
  origin: process.env.CLIENT_URL || "http://localhost:3000",
  credentials: true,
  optionsSuccessStatus: 200
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  maxAge: '1d',
  etag: false
}));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/faculties', facultyRoutes);

// Socket.IO for real-time features
io.on('connection', (socket) => {
  console.log(`New client connected: ${socket.id}`);

  // Join user room for private messages
  socket.on('join', (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined room`);
  });

  // Handle private messages
  socket.on('sendMessage', async (data) => {
    try {
      const Message = require('./models/Message');
      const message = new Message({
        ...data,
        timestamp: new Date()
      });
      await message.save();

      // Emit to receiver
      io.to(data.receiver).emit('newMessage', {
        ...message.toObject(),
        isFromMe: false
      });

      // Emit to sender (confirmation)
      socket.emit('messageSent', {
        ...message.toObject(),
        isFromMe: true
      });
    } catch (error) {
      socket.emit('messageError', { error: 'Failed to send message' });
    }
  });

  // Handle typing indicators
  socket.on('typing', (data) => {
    socket.to(data.receiver).emit('userTyping', {
      userId: data.sender,
      isTyping: data.isTyping
    });
  });

  // Handle post likes (real-time updates)
  socket.on('likePost', (data) => {
    socket.to(data.postAuthor).emit('postLiked', {
      postId: data.postId,
      likerId: data.likerId,
      likerName: data.likerName
    });
  });

  // Handle comments
  socket.on('newComment', (data) => {
    socket.to(data.postAuthor).emit('postCommented', {
      postId: data.postId,
      commenterId: data.commenterId,
      commenterName: data.commenterName,
      comment: data.comment
    });
  });

  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Error handling middleware (must be last)
app.use(notFound);
app.use(errorHandler);

// MongoDB Connection with retry logic
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Modern MongoDB driver doesn't need these options
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);

    // Handle connection events
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
    // Retry connection after 5 seconds
    setTimeout(connectDB, 5000);
  }
};

connectDB();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Client URL: ${process.env.CLIENT_URL || 'http://localhost:3000'}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
});
