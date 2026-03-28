const { createHttpError } = require('../utils/httpError');

const notFound = (req, res, next) => {
  next(
    createHttpError(
      404,
      `Route introuvable: ${req.originalUrl}`,
      'ROUTE_NOT_FOUND'
    )
  );
};

module.exports = { notFound };
