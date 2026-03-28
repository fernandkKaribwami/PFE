const getRequestBody = (req) => {
  if (!req || typeof req.body !== 'object' || req.body === null) {
    return {};
  }

  return req.body;
};

module.exports = {
  getRequestBody,
};
