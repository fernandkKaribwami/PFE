import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class StoryService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getFeedStories() async {
    try {
      final response = await _api.get('/stories/feed');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stories = data['stories'] as List? ?? const [];
        return stories
            .whereType<Map>()
            .map((story) => Map<String, dynamic>.from(story))
            .toList();
      }
    } catch (e) {
      debugPrint('Get stories error: $e');
    }

    return [];
  }

  Future<Map<String, dynamic>?> createStory({
    required String fileName,
    String? mediaPath,
    Uint8List? mediaBytes,
    String? caption,
  }) async {
    try {
      final response = await _api.postMultipart(
        '/stories',
        {
          if (caption != null && caption.trim().isNotEmpty)
            'caption': caption.trim(),
        },
        'media',
        mediaPath ?? '',
        fileBytes: mediaBytes,
        fileName: fileName,
      );

      final body = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final data = jsonDecode(body);
        return data['story'] as Map<String, dynamic>?;
      }

      debugPrint('Create story failed: $body');
      return null;
    } catch (e) {
      debugPrint('Create story error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> markViewed(String storyId) async {
    try {
      final response = await _api.post('/stories/$storyId/view', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['story'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Mark story viewed error: $e');
    }

    return null;
  }
}
