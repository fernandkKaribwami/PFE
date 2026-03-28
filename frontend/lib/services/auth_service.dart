import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String faculty,
    required String filiere,
    required String niveau,
    required String bio,
    String? avatarPath,
  }) async {
    try {
      final response = await _api.post('/auth/register', {
        'name': '$nom $prenom',
        'email': email,
        'password': password,
        'faculty': faculty,
        'role': 'student',
        'level': niveau,
        'bio': bio,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['_id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['_id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await _api.post('/auth/verify-email', {
        'email': email,
        'code': code,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Verify email error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    return true;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
