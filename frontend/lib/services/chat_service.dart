import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getMessages(String userId) async {
    try {
      final response = await _api.get('/messages/$userId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) is List
            ? jsonDecode(response.body)
            : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get messages error: $e');
      return [];
    }
  }

  Future<bool> sendMessage(String to, String text) async {
    try {
      final response = await _api.post('/messages', {'to': to, 'text': text});
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _api.get('/conversations');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) is List
            ? jsonDecode(response.body)
            : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get conversations error: $e');
      return [];
    }
  }
}
