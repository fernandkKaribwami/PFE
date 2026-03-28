const { AppError } = require('../utils/httpError');

const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let code = err.code || 'INTERNAL_SERVER_ERROR';
  let message = err.message || 'Erreur interne du serveur';
  let details = err.details;

  console.error(err);

  if (err.name === 'CastError') {
    statusCode = 404;
    code = 'RESOURCE_NOT_FOUND';
    message = 'Ressource introuvable';
  }

  if (err.code === 11000) {
    statusCode = 400;
    code = 'DUPLICATE_FIELD';
    message = 'Une valeur unique existe deja';
    details = err.keyValue;
  }

  if (err.name === 'ValidationError') {
    statusCode = 400;
    code = 'VALIDATION_ERROR';
    message = Object.values(err.errors).map((val) => val.message).join(', ');
    details = Object.values(err.errors).map((val) => ({
      field: val.path,
      message: val.message,
    }));
  }

  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    code = 'INVALID_TOKEN';
    message = 'Token invalide';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    code = 'TOKEN_EXPIRED';
    message = 'Token expire';
  }

  if (err instanceof AppError) {
    statusCode = err.statusCode;
    code = err.code;
    message = err.message;
    details = err.details;
  }

  res.status(statusCode).json({
    success: false,
    message,
    code,
    ...(details ? { details } : {}),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = { errorHandler };
