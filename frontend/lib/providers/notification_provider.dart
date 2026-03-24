import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String token) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _notifications = data['notifications'] ?? [];
        _unreadCount = _notifications.where((n) => !(n['read'] ?? false)).length;
        _error = null;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Failed to load notifications';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$API_URL/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$API_URL/api/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void addNotification(dynamic notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
      final notifications = await _notificationService.getNotifications();

      // Compter les non-lues
      final unreadCount = notifications
          .where((n) => n['isRead'] == false)
          .length;

      state = NotificationState(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final updated = state.notifications.map((n) {
        if (n['_id'] == notificationId) {
          return {...n, 'isRead': true};
        }
        return n;
      }).toList();

      final unreadCount = updated.where((n) => n['isRead'] == false).length;

      state = state.copyWith(
        notifications: updated,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      final updated = state.notifications
          .where((n) => n['_id'] != notificationId)
          .toList();

      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = state.notifications
        .where((n) => n['isRead'] == false)
        .map((n) => n['_id'] as String)
        .toList();

    for (final id in unreadIds) {
      await markAsRead(id);
    }
  }
}

// État pour les messages
class ChatState {
  final List<dynamic> conversations;
  final List<dynamic> currentMessages;
  final String? selectedUserId;
  final bool isLoading;
  final String? error;

  ChatState({
    this.conversations = const [],
    this.currentMessages = const [],
    this.selectedUserId,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<dynamic>? conversations,
    List<dynamic>? currentMessages,
    String? selectedUserId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider pour le chat
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.watch(chatServiceProvider)),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatNotifier(this._chatService) : super(ChatState());

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final conversations = await _chatService.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> selectConversation(String userId) async {
    state = state.copyWith(
      selectedUserId: userId,
      isLoading: true,
    );
    try {
      final messages = await _chatService.getMessages(userId);
      state = state.copyWith(
        currentMessages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> sendMessage(String userId, String text) async {
    try {
      await _chatService.sendMessage(userId, text);

      // Ajouter le message à la liste locale
      final newMessage = {
        'to': userId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'isOwn': true,
      };

      state = state.copyWith(
        currentMessages: [...state.currentMessages, newMessage],
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }
}
