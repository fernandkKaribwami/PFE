import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class ChatSendResult {
  final Map<String, dynamic>? data;
  final String? error;

  const ChatSendResult({this.data, this.error});

  bool get isSuccess => data != null;
}

class ChatService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getMessages(String userId) async {
    try {
      final response = await _api.get('/messages/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['messages'] is List ? data['messages'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get messages error: $e');
      return [];
    }
  }

  Future<ChatSendResult> sendMessage(
    String to, {
    String text = '',
    List<MultipartAttachment> attachments = const [],
  }) async {
    try {
      final trimmedText = text.trim();

      if (trimmedText.isEmpty && attachments.isEmpty) {
        return const ChatSendResult(
          error: 'Ajoute un message ou un fichier avant l envoi',
        );
      }

      if (attachments.isNotEmpty) {
        final response = await _api.postMultipartFiles(
          '/messages',
          {'receiver': to, if (trimmedText.isNotEmpty) 'content': trimmedText},
          'attachments',
          attachments,
        );
        final body = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          final data = jsonDecode(body);
          return ChatSendResult(data: data['data'] as Map<String, dynamic>?);
        }

        debugPrint('Send message failed: $body');
        return ChatSendResult(error: _extractErrorMessage(body));
      }

      final response = await _api.post('/messages', {
        'receiver': to,
        'content': trimmedText,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatSendResult(data: data['data'] as Map<String, dynamic>?);
      }

      debugPrint('Send message failed: ${response.body}');
      return ChatSendResult(error: _extractErrorMessage(response.body));
    } catch (e) {
      debugPrint('Send message error: $e');
      return const ChatSendResult(
        error: 'Erreur reseau pendant l envoi du message',
      );
    }
  }

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _api.get('/messages/conversations');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['conversations'] is List ? data['conversations'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get conversations error: $e');
      return [];
    }
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Ignore JSON parsing and fall back below.
    }

    return 'Envoi impossible pour le moment';
  }
}
