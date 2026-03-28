import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final response = await _api.get('/users/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Get current profile error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMessageContacts() async {
    try {
      final response = await _api.get('/users/contacts');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['contacts'] as List? ?? [])
            .whereType<Map>()
            .map<Map<String, dynamic>>((item) {
              final contact = Map<String, dynamic>.from(item);
              return {
                '_id': contact['_id']?.toString() ?? '',
                'name': contact['name']?.toString() ?? 'Utilisateur',
                'avatar': contact['avatar']?.toString() ?? '',
                'subtitle':
                    contact['faculty']?['name']?.toString() ??
                    contact['email']?.toString() ??
                    '',
              };
            })
            .where((contact) => contact['_id']!.isNotEmpty)
            .toList();
      }

      final profile = await getCurrentProfile();
      if (profile == null) {
        return [];
      }

      final contacts = <String, Map<String, dynamic>>{};
      final currentUserId = profile['_id']?.toString();
      for (final relation in [
        ...(profile['following'] as List? ?? const []),
        ...(profile['followers'] as List? ?? const []),
      ]) {
        if (relation is! Map) {
          continue;
        }

        final relationMap = Map<String, dynamic>.from(relation);
        final relationId = relationMap['_id']?.toString();
        if (relationId == null ||
            relationId.isEmpty ||
            relationId == currentUserId) {
          continue;
        }

        contacts[relationId] = {
          '_id': relationId,
          'name': relationMap['name']?.toString() ?? 'Utilisateur',
          'avatar': relationMap['avatar']?.toString() ?? '',
          'subtitle':
              relationMap['faculty']?['name']?.toString() ??
              relationMap['email']?.toString() ??
              '',
        };
      }

      return contacts.values.toList();
    } catch (e) {
      debugPrint('Get message contacts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String name,
    String? bio,
    String? facultyId,
    String? level,
    String? interests,
    String? avatarPath,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarUrl,
  }) async {
    try {
      final fields = <String, String>{
        'name': name,
        if (bio case != null) 'bio': bio,
        if (facultyId case != null) 'faculty': facultyId,
        if (level case != null) 'level': level,
        if (interests case != null) 'interests': interests,
        if (avatarUrl case != null) 'avatar': avatarUrl,
      };

      final hasAvatarFile =
          (avatarBytes != null &&
              avatarFileName != null &&
              avatarFileName.isNotEmpty) ||
          (avatarPath != null && avatarPath.isNotEmpty);

      if (hasAvatarFile) {
        final response = await _api.putMultipart(
          '/users/profile',
          fields,
          'avatar',
          avatarPath ?? '',
          fileBytes: avatarBytes,
          fileName: avatarFileName,
        );
        final body = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final data = jsonDecode(body);
          return data['user'] as Map<String, dynamic>?;
        }
        debugPrint('Update profile failed: $body');
        return null;
      }

      final response = await _api.put('/users/profile', fields);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>?;
      }

      debugPrint('Update profile failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return null;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _api.put('/users/profile/password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return null;
      }

      return data['message']?.toString() ??
          'Modification du mot de passe impossible';
    } catch (e) {
      debugPrint('Change password error: $e');
      return 'Erreur reseau pendant la mise a jour du mot de passe';
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      final response = await _api.post('/users/follow/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Follow user error: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      final response = await _api.post('/users/unfollow/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Unfollow user error: $e');
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      final response = await _api.patch('/admin/users/$userId/block', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Block user error: $e');
      return false;
    }
  }
}
