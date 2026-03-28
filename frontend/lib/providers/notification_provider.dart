import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart' show apiUrl;

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
        Uri.parse('$apiUrl/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _notifications = data['notifications'] ?? [];
        _unreadCount = data['unreadCount'] ?? 0;
        _error = null;
      } else {
        _error = data['message'] ?? 'Chargement des notifications impossible';
      }
    } catch (e) {
      _error = 'Erreur reseau: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere(
          (notification) => notification['_id'] == notificationId,
        );
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
        Uri.parse('$apiUrl/api/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        for (final notification in _notifications) {
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
    final normalizedNotification = Map<String, dynamic>.from(
      notification as Map,
    );
    normalizedNotification.putIfAbsent('read', () => false);
    normalizedNotification.putIfAbsent(
      'content',
      () => 'Nouvelle notification',
    );
    final notificationId = normalizedNotification['_id']?.toString();
    final existingIndex = _notifications.indexWhere(
      (item) => item['_id']?.toString() == notificationId,
    );

    if (existingIndex != -1) {
      _notifications[existingIndex] = normalizedNotification;
    } else {
      _notifications.insert(0, normalizedNotification);
    }

    _unreadCount = _notifications.where((item) => item['read'] != true).length;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
