const compression = require('compression');
const cors = require('cors');
const express = require('express');
const helmet = require('helmet');
const path = require('path');
const rateLimit = require('express-rate-limit');

const { corsOptions } = require('./config/cors');
const { errorHandler } = require('./middleware/errorHandler');
const { notFound } = require('./middleware/notFound');

const adminRoutes = require('./routes/admin');
const authRoutes = require('./routes/auth');
const eventRoutes = require('./routes/events');
const facultyRoutes = require('./routes/faculties');
const groupRoutes = require('./routes/groups');
const messageRoutes = require('./routes/messages');
const notificationRoutes = require('./routes/notifications');
const postRoutes = require('./routes/posts');
const searchRoutes = require('./routes/search');
const storyRoutes = require('./routes/stories');
const userRoutes = require('./routes/users');

const createLimiterMessage = (message, code) => ({
  success: false,
  message,
  code,
});

const createApp = () => {
  const app = express();

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    })
  );
  app.use(compression());
  app.use(cors(corsOptions));

  const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: createLimiterMessage(
      'Trop de requetes. Veuillez reessayer plus tard.',
      'RATE_LIMITED'
    ),
    standardHeaders: true,
    legacyHeaders: false,
  });

  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    message: createLimiterMessage(
      'Trop de tentatives d authentification. Veuillez reessayer plus tard.',
      'AUTH_RATE_LIMITED'
    ),
    standardHeaders: true,
    legacyHeaders: false,
  });

  app.use('/api', apiLimiter);
  app.use('/api/auth/login', authLimiter);
  app.use('/api/auth/register', authLimiter);

  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  app.use(
    '/uploads',
    express.static(path.join(__dirname, 'uploads'), {
      maxAge: '1d',
      etag: false,
    })
  );

  app.get('/api/health', (req, res) => {
    res.status(200).json({
      success: true,
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/posts', postRoutes);
  app.use('/api/groups', groupRoutes);
  app.use('/api/events', eventRoutes);
  app.use('/api/messages', messageRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/search', searchRoutes);
  app.use('/api/faculties', facultyRoutes);
  app.use('/api/notifications', notificationRoutes);
  app.use('/api/stories', storyRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
};

module.exports = {
  createApp,
};
