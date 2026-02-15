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

  Future<bool> createPost({
    required String text,
    required bool isPublic,
    String? filePath,
    String? faculty,
    String? group,
  }) async {
    try {
      final fields = {
        'text': text,
        'isPublic': isPublic.toString(),
        if (faculty case != null) 'faculty': faculty,
        if (group case != null) 'group': group,
      };

      final response = await _api.postMultipart(
        '/posts',
        fields,
        'media',
        filePath ?? '',
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create post error: $e');
      return false;
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

  Future<bool> commentPost(String postId, String text) async {
    try {
      final response = await _api.post('/posts/$postId/comment', {
        'text': text,
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
      return response.statusCode == 200;
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
