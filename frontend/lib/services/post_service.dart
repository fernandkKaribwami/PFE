import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class PostService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _api.get('/posts?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['posts'] is List ? data['posts'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get feed error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/posts/user/$userId?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['posts'] is List ? data['posts'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get user posts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createPost({
    required String text,
    required bool isPublic,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String? faculty,
    String? group,
  }) async {
    try {
      final fields = {
        'content': text,
        if (faculty case != null) 'faculty': faculty,
        if (group case != null) 'group': group,
      };

      final response = await _api.postMultipart(
        '/posts',
        fields,
        'image',
        filePath ?? '',
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (response.statusCode == 201) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);
        return data['post'];
      }

      return null;
    } catch (e) {
      debugPrint('Create post error: $e');
      return null;
    }
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _api.post('/posts/$postId/like', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Like post error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> toggleLikePost(String postId) async {
    try {
      final response = await _api.post('/posts/$postId/like', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['post'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Toggle like post error: $e');
      return null;
    }
  }

  Future<bool> commentPost(String postId, String text) async {
    try {
      final response = await _api.post('/posts/$postId/comment', {
        'content': text,
      });
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Comment post error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/posts/$postId/comments?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['comments'] is List ? data['comments'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get comments error: $e');
      return [];
    }
  }

  Future<bool> savePost(String postId) async {
    try {
      final response = await _api.post('/posts/$postId/save', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Save post error: $e');
      return false;
    }
  }

  Future<bool> reportPost(
    String postId,
    String reason,
    String description,
  ) async {
    try {
      final response = await _api.post('/posts/$postId/report', {
        'reason': reason,
        'description': description,
      });
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Report post error: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _api.delete('/posts/$postId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete post error: $e');
      return false;
    }
  }
}
