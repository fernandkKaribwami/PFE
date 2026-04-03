const https = require('https');

const { createHttpError } = require('./httpError');

const GOOGLE_TOKEN_INFO_URL = 'https://oauth2.googleapis.com/tokeninfo';

const fetchJson = (url) =>
  new Promise((resolve, reject) => {
    https
      .get(url, (response) => {
        let rawBody = '';

        response.setEncoding('utf8');
        response.on('data', (chunk) => {
          rawBody += chunk;
        });

        response.on('end', () => {
          let payload = {};

          try {
            payload = rawBody ? JSON.parse(rawBody) : {};
          } catch (error) {
            reject(
              createHttpError(
                502,
                'Reponse Google invalide',
                'GOOGLE_INVALID_RESPONSE'
              )
            );
            return;
          }

          if (response.statusCode && response.statusCode >= 400) {
            reject(
              createHttpError(
                401,
                payload.error_description ||
                  payload.error ||
                  'Jeton Google invalide',
                'INVALID_GOOGLE_TOKEN'
              )
            );
            return;
          }

          resolve(payload);
        });
      })
      .on('error', () => {
        reject(
          createHttpError(
            502,
            'Verification Google impossible pour le moment',
            'GOOGLE_VERIFY_UNAVAILABLE'
          )
        );
      });
  });

const verifyGoogleIdToken = async ({ idToken, expectedAudience }) => {
  if (!idToken) {
    throw createHttpError(
      400,
      'Jeton Google manquant',
      'MISSING_GOOGLE_ID_TOKEN'
    );
  }

  const url = new URL(GOOGLE_TOKEN_INFO_URL);
  url.searchParams.set('id_token', idToken);

  const payload = await fetchJson(url);

  if (expectedAudience && payload.aud !== expectedAudience) {
    throw createHttpError(
      401,
      'Client Google non autorise',
      'GOOGLE_AUDIENCE_MISMATCH'
    );
  }

  if (payload.email_verified !== 'true') {
    throw createHttpError(
      403,
      'Le compte Google doit etre verifie',
      'GOOGLE_EMAIL_NOT_VERIFIED'
    );
  }

  if (!payload.email) {
    throw createHttpError(
      400,
      'Adresse email Google introuvable',
      'GOOGLE_EMAIL_MISSING'
    );
  }

  return {
    email: payload.email.toString().trim().toLowerCase(),
    name: payload.name?.toString().trim() || '',
    avatar: payload.picture?.toString().trim() || '',
    subject: payload.sub?.toString() || '',
  };
};

module.exports = {
  verifyGoogleIdToken,
};
