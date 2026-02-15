import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await _api.get('/user/$userId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String nom,
    String? prenom,
    String? bio,
    String? filiere,
    String? niveau,
    String? interests,
    String? avatarPath,
  }) async {
    try {
      final fields = {
        'nom': nom,
        if (prenom case != null) 'prenom': prenom,
        if (bio case != null) 'bio': bio,
        if (filiere case != null) 'filiere': filiere,
        if (niveau case != null) 'niveau': niveau,
        if (interests case != null) 'interests': interests,
      };

      final response = await _api.postMultipart(
        '/user/$userId',
        fields,
        'avatar',
        avatarPath ?? '',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      final response = await _api.post('/follow/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Follow user error: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      final response = await _api.post('/unfollow/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Unfollow user error: $e');
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      final response = await _api.post('/block/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Block user error: $e');
      return false;
    }
  }
}
