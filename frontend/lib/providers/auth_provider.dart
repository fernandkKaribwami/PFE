import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _token = token;
        _user = userData;
        await _saveToken(token);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        await _saveToken(_token!);
        await _saveUserId(_user!['id']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String faculty,
    String? bio,
    String? avatarPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_URL/api/auth/register'),
      );

      request.fields['nom'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['faculty'] = faculty;
      if (bio != null) request.fields['bio'] = bio;

      if (avatarPath != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        await _saveToken(_token!);
        await _saveUserId(_user!['id']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verificationCode': code,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'resetCode': code,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
