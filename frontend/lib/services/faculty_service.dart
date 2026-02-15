import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FacultyService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getFaculties() async {
    try {
      final response = await _api.get('/faculties');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) is List
            ? jsonDecode(response.body)
            : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get faculties error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFaculty(String facultyId) async {
    try {
      final response = await _api.get('/faculties/$facultyId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get faculty error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getFacultyPosts(
    String facultyId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/faculties/$facultyId/posts?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['posts'] is List ? data['posts'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get faculty posts error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getFacultyMembers(
    String facultyId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        '/faculties/$facultyId/members?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['members'] is List ? data['members'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get faculty members error: $e');
      return [];
    }
  }
}
