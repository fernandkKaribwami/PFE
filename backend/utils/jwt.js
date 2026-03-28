const jwt = require('jsonwebtoken');
const { promisify } = require('util');

const signAsync = promisify(jwt.sign);

const signToken = async (payload, options = {}) => {
  return signAsync(payload, process.env.JWT_SECRET, options);
};

module.exports = {
  signToken,
};
