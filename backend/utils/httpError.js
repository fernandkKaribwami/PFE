class AppError extends Error {
  constructor(statusCode, message, code = 'APP_ERROR', details) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

const createHttpError = (statusCode, message, code, details) => {
  return new AppError(statusCode, message, code, details);
};

const assertOrThrow = (condition, statusCode, message, code, details) => {
  if (!condition) {
    throw createHttpError(statusCode, message, code, details);
  }
};

module.exports = {
  AppError,
  assertOrThrow,
  createHttpError,
};
