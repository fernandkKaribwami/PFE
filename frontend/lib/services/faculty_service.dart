import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FacultyService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getFaculties() async {
    try {
      debugPrint('🔄 getFaculties: Tentative de chargement...');
      final response = await _api.get('/faculties');

      debugPrint('✓ getFaculties response code: ${response.statusCode}');
      debugPrint('✓ getFaculties response headers: ${response.headers}');
      debugPrint(
        '✓ getFaculties response body length: ${response.body.length}',
      );
      debugPrint('✓ getFaculties response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          debugPrint('✓ Decoded faculties type: ${decoded.runtimeType}');
          debugPrint(
            '✓ Decoded faculties count: ${decoded is List ? decoded.length : 0}',
          );
          debugPrint('✓ Decoded faculties: $decoded');

          if (decoded is List && decoded.isNotEmpty) {
            debugPrint('✓ Successfully loaded ${decoded.length} faculties');
            return decoded;
          } else {
            debugPrint('⚠️ getFaculties: List is empty or not a list');
            return [];
          }
        } catch (parseError) {
          debugPrint('❌ JSON Parse error: $parseError');
          debugPrint('❌ Response body was: ${response.body}');
          rethrow;
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ getFaculties: endpoint not found (404)');
        throw Exception('Endpoint /faculties non trouvé');
      } else {
        debugPrint('❌ getFaculties error status: ${response.statusCode}');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getFaculties exception: $e');
      rethrow;
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
      //debugPrint('Get faculty posts error: $e');
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
