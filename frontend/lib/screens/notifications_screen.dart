import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'modern_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoaded) {
      return;
    }

    _hasLoaded = true;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && token.isNotEmpty) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications(token);
    }
  }

  Future<void> _refreshNotifications() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || token.isEmpty) {
      return;
    }

    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications(token);
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;
    final notificationId = notification['_id']?.toString();
    final referenceId = notification['referenceId']?.toString();
    final type = notification['type']?.toString() ?? '';

    if (token != null &&
        token.isNotEmpty &&
        notificationId != null &&
        notificationId.isNotEmpty &&
        notification['read'] != true) {
      await notificationProvider.markAsRead(notificationId, token);
    }

    if (!mounted || referenceId == null || referenceId.isEmpty) {
      return;
    }

    if (type == 'follow') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModernProfileScreen(userId: referenceId),
        ),
      );
      return;
    }

    if (type == 'message') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(userId: referenceId),
        ),
      );
      return;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.mode_comment_outlined;
      case 'message':
        return Icons.mark_chat_unread_outlined;
      case 'post':
        return Icons.newspaper_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'follow':
        return const Color(0xFF2563EB);
      case 'like':
        return const Color(0xFFE11D48);
      case 'comment':
        return const Color(0xFFEA580C);
      case 'message':
        return const Color(0xFF0F766E);
      case 'post':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'A l instant';
    }

    try {
      final date = DateTime.parse(rawDate).toLocal();
      final delta = DateTime.now().difference(date);

      if (delta.inMinutes < 1) {
        return 'A l instant';
      }
      if (delta.inHours < 1) {
        return 'Il y a ${delta.inMinutes} min';
      }
      if (delta.inDays < 1) {
        return 'Il y a ${delta.inHours} h';
      }
      if (delta.inDays < 7) {
        return 'Il y a ${delta.inDays} j';
      }

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Recente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer2<AuthProvider, NotificationProvider>(
            builder: (context, authProvider, notificationProvider, _) {
              final token = authProvider.token;
              final unreadCount = notificationProvider.unreadCount;

              return TextButton(
                onPressed:
                    token == null ||
                        token.isEmpty ||
                        unreadCount == 0 ||
                        notificationProvider.isLoading
                    ? null
                    : () => notificationProvider.markAllAsRead(token),
                child: Text(
                  'Tout lire',
                  style: TextStyle(
                    color: unreadCount == 0 ? Colors.grey : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          final notifications = notificationProvider.notifications;

          if (notificationProvider.isLoading && notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 72,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune notification pour le moment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = Map<String, dynamic>.from(
                  notifications[index] as Map,
                );
                final type = notification['type']?.toString() ?? '';
                final unread = notification['read'] != true;
                final accentColor = _colorForType(type);

                return Material(
                  color: unread
                      ? accentColor.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _openNotification(notification),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: unread
                              ? accentColor.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_iconForType(type), color: accentColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['content']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? notification['content'].toString()
                                      : 'Nouvelle notification',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(
                                    notification['createdAt']?.toString(),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
