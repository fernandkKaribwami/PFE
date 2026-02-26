import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());
final chatServiceProvider = Provider((ref) => ChatService());

// État pour les notifications
class NotificationState {
  final List<dynamic> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<dynamic>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider pour les notifications
final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.watch(notificationServiceProvider)),
);

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
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
