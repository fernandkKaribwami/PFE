import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utils/app_config.dart';

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  String? _connectedUserId;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _storyController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _profileController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get stories => _storyController.stream;
  Stream<Map<String, dynamic>> get profileUpdates => _profileController.stream;
  Stream<Map<String, dynamic>> get typingEvents => _typingController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userId}) {
    if (_socket != null && _connectedUserId == userId) {
      if (!(_socket?.connected ?? false)) {
        _socket?.connect();
      }
      return;
    }

    disconnect();
    _connectedUserId = userId;

    _socket = io.io(
      AppConfig.wsBaseUrl,
      io.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .disableAutoConnect()
          .setAuth({'userId': userId})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('Realtime connected for user $userId');
      _socket?.emit('join', userId);
    });

    _socket?.onDisconnect((_) {
      debugPrint('Realtime disconnected');
    });

    _socket?.on('userTyping', (data) {
      if (data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('newMessage', (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messageSent', (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    for (final eventName in [
      'notification',
      'followNotification',
      'postLiked',
      'postCommented',
    ]) {
      _socket?.on(eventName, (data) {
        if (data is Map) {
          final payload = Map<String, dynamic>.from(data);
          payload.putIfAbsent('type', () => eventName);
          _notificationController.add(payload);
        }
      });
    }

    for (final eventName in ['storyCreated', 'storyDeleted']) {
      _socket?.on(eventName, (data) {
        if (data is Map) {
          final payload = Map<String, dynamic>.from(data);
          payload['type'] = eventName;
          _storyController.add(payload);
        }
      });
    }

    _socket?.on('profileUpdated', (data) {
      if (data is Map) {
        _profileController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
    _connectedUserId = null;
  }

  void sendTyping({
    required String sender,
    required String receiver,
    required bool isTyping,
  }) {
    _socket?.emit('typing', {
      'sender': sender,
      'receiver': receiver,
      'isTyping': isTyping,
    });
  }
}
