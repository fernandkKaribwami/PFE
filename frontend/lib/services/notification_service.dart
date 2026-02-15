import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get('/notifications?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['notifications'] is List ? data['notifications'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get notifications error: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _api.put(
        '/notifications/$notificationId/read',
        {},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark as read error: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _api.delete('/notifications/$notificationId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete notification error: $e');
      return false;
    }
  }
}

class SearchService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> search(String query, {String? type}) async {
    try {
      final typeQuery = type != null ? '&type=$type' : '';
      final response = await _api.get('/search?q=$query$typeQuery');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Search error: $e');
      return {};
    }
  }
}
