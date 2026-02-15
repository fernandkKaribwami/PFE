import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getGroups({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    try {
      final query =
          '?page=$page&limit=$limit${category != null ? '&category=$category' : ''}';
      final response = await _api.get('/groups$query');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['groups'] is List ? data['groups'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get groups error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGroup(String groupId) async {
    try {
      final response = await _api.get('/groups/$groupId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get group error: $e');
      return null;
    }
  }

  Future<bool> createGroup({
    required String name,
    required String description,
    required String category,
    required bool isPrivate,
    String? faculty,
    String? avatarPath,
  }) async {
    try {
      final fields = {
        'name': name,
        'description': description,
        'category': category,
        'isPrivate': isPrivate.toString(),
        if (faculty case != null) 'faculty': faculty,
      };

      final response = await _api.postMultipart(
        '/groups',
        fields,
        'avatar',
        avatarPath ?? '',
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create group error: $e');
      return false;
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      final response = await _api.post('/groups/$groupId/join', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Join group error: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await _api.post('/groups/$groupId/leave', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Leave group error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getGroupPosts(
    String groupId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/groups/$groupId/posts?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['posts'] is List ? data['posts'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get group posts error: $e');
      return [];
    }
  }
}
