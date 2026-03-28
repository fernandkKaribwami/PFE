const express = require('express');

const auth = require('../middleware/auth');
const Message = require('../models/Message');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const { createAndEmitNotification } = require('../utils/notifications');
const { getRequestBody } = require('../utils/request');
const { createUpload, serializeUploadedFile } = require('../utils/uploads');
const { serializeMessage, serializeUserSummary } = require('../utils/serializers');

const router = express.Router();
const upload = createUpload({ prefix: 'message', fileSize: 25 * 1024 * 1024 });

const populateMessageQuery = (query) => {
  return query
    .populate({
      path: 'sender',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .populate({
      path: 'receiver',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    });
};

router.get('/conversations', auth, async (req, res) => {
  const messages = await populateMessageQuery(
    Message.find({
      $or: [{ sender: req.user.id }, { receiver: req.user.id }],
    }).sort({ createdAt: -1 })
  ).lean();

  const conversationMap = new Map();

  messages.forEach((message) => {
    const partner =
      message.sender?._id?.toString() === req.user.id.toString()
        ? message.receiver
        : message.sender;

    if (!partner?._id) {
      return;
    }

    const key = partner._id.toString();
    if (!conversationMap.has(key)) {
      conversationMap.set(key, {
        user: serializeUserSummary(partner),
        lastMessage: serializeMessage(message),
      });
    }
  });

  res.json({
    success: true,
    conversations: Array.from(conversationMap.values()),
  });
});

router.post('/', auth, upload.array('attachments', 6), async (req, res) => {
  const body = getRequestBody(req);
  const receiverId = body.receiver || body.to;
  const content = (body.content || body.text || '').toString().trim();
  const attachments = Array.isArray(req.files)
    ? req.files.map((file) => serializeUploadedFile(file)).filter(Boolean)
    : [];

  if (!receiverId || (!content && attachments.length === 0)) {
    throw createHttpError(
      400,
      'receiver/to et un texte ou une piece jointe sont requis',
      'MISSING_MESSAGE_FIELDS'
    );
  }

  const receiver = await User.findById(receiverId);
  if (!receiver) {
    throw createHttpError(404, 'Destinataire introuvable', 'USER_NOT_FOUND');
  }

  const message = await Message.create({
    sender: req.user.id,
    receiver: receiverId,
    content,
    attachments,
  });

  const populatedMessage = await populateMessageQuery(
    Message.findById(message._id)
  );
  const serializedMessage = serializeMessage(populatedMessage);

  const io = req.app.get('io');
  if (io) {
    io.to(receiverId.toString()).emit('newMessage', serializedMessage);
  }

  let notification = null;
  if (receiverId.toString() !== req.user.id.toString()) {
    const senderName =
      serializedMessage.sender?.name ||
      (await User.findById(req.user.id).select('name'))?.name ||
      'Quelqu un';
    const hasText = content.length > 0;
    const hasAttachments = attachments.length > 0;
    const notificationContent = hasText && hasAttachments
      ? `${senderName} vous a envoye un message avec piece jointe`
      : hasAttachments
        ? `${senderName} vous a envoye une piece jointe`
        : `${senderName} vous a envoye un message`;

    notification = await createAndEmitNotification(req.app, {
      user: receiverId,
      type: 'message',
      referenceId: req.user.id,
      content: notificationContent,
    });
  }

  res.status(201).json({
    success: true,
    message: 'Message envoye',
    data: serializedMessage,
    ...(notification ? { notification } : {}),
  });
});

router.get('/:userId', auth, async (req, res) => {
  const targetUser = await User.findById(req.params.userId);
  if (!targetUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  const messages = await populateMessageQuery(
    Message.find({
      $or: [
        { sender: req.user.id, receiver: req.params.userId },
        { sender: req.params.userId, receiver: req.user.id },
      ],
    }).sort({ createdAt: 1 })
  ).lean();

  await Message.updateMany(
    {
      sender: req.params.userId,
      receiver: req.user.id,
      read: false,
    },
    {
      $set: { read: true },
    }
  );

  res.json({
    success: true,
    messages: messages.map((message) => serializeMessage(message)),
  });
});

module.exports = router;
