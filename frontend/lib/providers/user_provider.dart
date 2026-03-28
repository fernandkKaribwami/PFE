import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart' show apiUrl;

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserProfile(String token) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = data['user'];
        _error = null;
      } else {
        _error = data['message'] ?? 'Chargement du profil impossible';
      }
    } catch (e) {
      _error = 'Erreur reseau: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String token, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = data['user'];
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Mise a jour du profil impossible';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur reseau: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> followUser(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/users/follow/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/users/unfollow/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void mergeCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
    _error = null;
    notifyListeners();
  }
}
