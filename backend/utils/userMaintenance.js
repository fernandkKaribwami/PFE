const User = require('../models/User');

const backfillEmailVerificationIfDisabled = async () => {
  if (process.env.REQUIRE_EMAIL_VERIFICATION === 'true') {
    return {
      skipped: true,
      matchedCount: 0,
      modifiedCount: 0,
    };
  }

  const result = await User.updateMany(
    { emailVerified: { $ne: true } },
    {
      $set: { emailVerified: true },
      $unset: { verificationCode: '' },
    }
  );

  return {
    skipped: false,
    matchedCount: result.matchedCount ?? 0,
    modifiedCount: result.modifiedCount ?? 0,
  };
};

module.exports = {
  backfillEmailVerificationIfDisabled,
};
