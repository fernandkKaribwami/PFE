import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EventService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getEvents({
    int page = 1,
    int limit = 10,
    String? category,
    String? faculty,
  }) async {
    try {
      final query =
          '?page=$page&limit=$limit${category != null ? '&category=$category' : ''}${faculty != null ? '&faculty=$faculty' : ''}';
      final response = await _api.get('/events$query');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['events'] is List ? data['events'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get events error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getEvent(String eventId) async {
    try {
      final response = await _api.get('/events/$eventId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get event error: $e');
      return null;
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required String startDate,
    required String location,
    required String category,
    String? endDate,
    int? maxAttendees,
    String? faculty,
    String? group,
    String? imagePath,
  }) async {
    try {
      final fields = {
        'title': title,
        'description': description,
        'startDate': startDate,
        'location': location,
        'category': category,
        if (endDate case != null) 'endDate': endDate,
        if (maxAttendees case != null) 'maxAttendees': maxAttendees.toString(),
        if (faculty case != null) 'faculty': faculty,
        if (group case != null) 'group': group,
      };

      final response = await _api.postMultipart(
        '/events',
        fields,
        'image',
        imagePath ?? '',
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create event error: $e');
      return false;
    }
  }

  Future<bool> rsvpEvent(String eventId) async {
    try {
      final response = await _api.post('/events/$eventId/rsvp', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('RSVP event error: $e');
      return false;
    }
  }
}
