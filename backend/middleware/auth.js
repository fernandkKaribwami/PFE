const jwt = require('jsonwebtoken');
const { createHttpError } = require('../utils/httpError');

module.exports = (req, res, next) => {
  const authorizationHeader = req.header('Authorization') || '';
  const bearerToken = authorizationHeader.startsWith('Bearer ')
    ? authorizationHeader.slice(7).trim()
    : null;
  const legacyToken = req.header('x-auth-token');
  const token = bearerToken || legacyToken;

  if (!token) {
    next(createHttpError(401, 'Authentification requise', 'AUTH_REQUIRED'));
    return;
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded.user;
    next();
  } catch (err) {
    next(createHttpError(401, 'Token invalide', 'INVALID_TOKEN'));
  }
};
