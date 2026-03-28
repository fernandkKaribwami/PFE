const socketio = require('socket.io');

const Message = require('./models/Message');
const { corsOptions } = require('./config/cors');
const { serializeMessage, serializeNotification } = require('./utils/serializers');

const initializeSocket = (server) => {
  const io = socketio(server, {
    cors: corsOptions,
    transports: ['websocket', 'polling'],
  });

  io.on('connection', (socket) => {
    const initialUserId = socket.handshake.auth?.userId;

    if (initialUserId) {
      socket.join(initialUserId);
    }

    socket.on('join', (userId) => {
      if (userId) {
        socket.join(userId);
      }
    });

    socket.on('typing', (data = {}) => {
      if (data.receiver) {
        socket.to(data.receiver).emit('userTyping', {
          userId: data.sender,
          isTyping: Boolean(data.isTyping),
        });
      }
    });

    socket.on('sendMessage', async (data = {}) => {
      try {
        const content = (data.content || data.text || '').toString().trim();
        const attachments = Array.isArray(data.attachments)
          ? data.attachments
          : [];

        if (!data.sender || !(data.receiver || data.to) || (!content && attachments.length === 0)) {
          throw new Error('Invalid payload');
        }

        const message = await Message.create({
          sender: data.sender,
          receiver: data.receiver || data.to,
          content,
          attachments,
        });

        const populatedMessage = await Message.findById(message._id)
          .populate('sender', 'name email role avatar bio faculty level interests blocked createdAt updatedAt')
          .populate('receiver', 'name email role avatar bio faculty level interests blocked createdAt updatedAt');

        const payload = serializeMessage(populatedMessage);
        if (payload.receiver?._id) {
          io.to(payload.receiver._id).emit('newMessage', payload);
        }
        socket.emit('messageSent', payload);
      } catch (error) {
        socket.emit('messageError', {
          success: false,
          message: 'Impossible d envoyer le message',
          code: 'MESSAGE_SEND_FAILED',
        });
      }
    });

    socket.on('notification', (notification) => {
      if (notification?.user) {
        io.to(notification.user).emit(
          'notification',
          serializeNotification(notification)
        );
      }
    });
  });

  return io;
};

module.exports = {
  initializeSocket,
};
