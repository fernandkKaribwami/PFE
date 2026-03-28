const fs = require('fs');
const multer = require('multer');
const path = require('path');

const uploadsDirectory = path.join(__dirname, '..', 'uploads');

const ensureUploadsDirectory = () => {
  fs.mkdirSync(uploadsDirectory, { recursive: true });
};

const sanitizeFileName = (fileName = 'file') => {
  return fileName.replace(/[^\w.-]+/g, '_');
};

const inferMimeTypeFromFileName = (fileName = '') => {
  const extension = path.extname(fileName).toLowerCase();

  switch (extension) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.mp3':
      return 'audio/mpeg';
    case '.wav':
      return 'audio/wav';
    case '.aac':
      return 'audio/aac';
    case '.m4a':
      return 'audio/mp4';
    case '.mp4':
      return 'video/mp4';
    case '.mov':
      return 'video/quicktime';
    case '.pdf':
      return 'application/pdf';
    case '.doc':
      return 'application/msword';
    case '.docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case '.xls':
      return 'application/vnd.ms-excel';
    case '.xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.ppt':
      return 'application/vnd.ms-powerpoint';
    case '.pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case '.txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
};

const inferAttachmentKind = (mimeType = '') => {
  if (mimeType.startsWith('image/')) {
    return 'image';
  }

  if (mimeType.startsWith('audio/')) {
    return 'audio';
  }

  if (mimeType.startsWith('video/')) {
    return 'video';
  }

  return 'document';
};

const createUpload = ({ prefix = 'upload', fileSize = 25 * 1024 * 1024 } = {}) => {
  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      ensureUploadsDirectory();
      cb(null, uploadsDirectory);
    },
    filename: (req, file, cb) => {
      const safeName = sanitizeFileName(file.originalname || 'file');
      cb(null, `${prefix}-${Date.now()}-${safeName}`);
    },
  });

  return multer({
    storage,
    limits: {
      fileSize,
    },
  });
};

const resolveUploadMimeType = (file) => {
  if (!file) {
    return 'application/octet-stream';
  }

  if (file.mimetype && file.mimetype !== 'application/octet-stream') {
    return file.mimetype;
  }

  return inferMimeTypeFromFileName(file.originalname || file.filename || '');
};

const serializeUploadedFile = (file) => {
  if (!file) {
    return null;
  }

  const mimeType = resolveUploadMimeType(file);

  return {
    url: `/uploads/${file.filename}`,
    fileName: file.originalname || file.filename,
    mimeType,
    size: file.size || 0,
    kind: inferAttachmentKind(mimeType),
  };
};

module.exports = {
  createUpload,
  ensureUploadsDirectory,
  inferAttachmentKind,
  inferMimeTypeFromFileName,
  resolveUploadMimeType,
  serializeUploadedFile,
  uploadsDirectory,
};
