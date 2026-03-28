const { createHttpError } = require('../utils/httpError');

const localhostPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/i;

const parseEnvOrigins = () => {
  return [
    process.env.CLIENT_URL,
    process.env.CLIENT_ORIGIN,
    process.env.CLIENT_ORIGINS,
    process.env.CLIENT_URLS,
  ]
    .filter(Boolean)
    .flatMap((value) => value.split(','))
    .map((origin) => origin.trim())
    .filter(Boolean);
};

const configuredOrigins = () => Array.from(new Set(parseEnvOrigins()));

const isAllowedOrigin = (origin) => {
  if (!origin) {
    return true;
  }

  if (localhostPattern.test(origin)) {
    return true;
  }

  return configuredOrigins().includes(origin);
};

const originDelegate = (origin, callback) => {
  if (isAllowedOrigin(origin)) {
    callback(null, true);
    return;
  }

  callback(
    createHttpError(
      403,
      `Origin non autorisee par CORS: ${origin}`,
      'CORS_ORIGIN_DENIED',
      { origin }
    )
  );
};

const corsOptions = {
  origin: originDelegate,
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-token'],
};

module.exports = {
  configuredOrigins,
  corsOptions,
  isAllowedOrigin,
  originDelegate,
};
