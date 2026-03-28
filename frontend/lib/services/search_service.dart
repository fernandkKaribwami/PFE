import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class SearchService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await _api.get('/search?q=$encodedQuery');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Search error: $e');
      return {};
    }
  }
}
