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
      final fields = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'faculty': faculty,
        'filiere': filiere,
        'niveau': niveau,
        'bio': bio,
      };

      final response = await _api.postMultipart(
        '/register',
        fields,
        'avatar',
        avatarPath ?? '',
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(await response.stream.bytesToString());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['id']);
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
      final response = await _api.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['id']);
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
      print('Verify email error: $e');
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
