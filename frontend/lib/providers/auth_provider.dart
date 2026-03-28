import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/realtime_service.dart';
import '../utils/app_config.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String get role => _user?['role']?.toString() ?? 'student';
  bool get isAuthenticated => _token != null && _user != null;

  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _token = token;
        _user = userData['user'];
        await _saveToken(token);
        if (_user?['_id'] != null) {
          await _saveUserId(_user!['_id']);
        }
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
      final normalizedEmail = email.trim().toLowerCase();

      if (!normalizedEmail.endsWith('@usmba.ac.ma')) {
        _error = 'Email doit etre un email universitaire @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data['user'];
        await _saveToken(_token!);
        await _saveUserId(_user!['_id']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Connexion impossible';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final baseError =
          'Echec de connexion au serveur. Verifiez que le backend est demarre a ${AppConfig.apiOrigin} et que votre reseau autorise la connexion.';
      _error = e.toString().contains('SocketException')
          ? '$baseError (Erreur reseau)'
          : baseError;
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
    required String role,
    String? bio,
    String? avatarPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();

      if (!normalizedEmail.endsWith('@usmba.ac.ma')) {
        _error = 'Email doit etre un email universitaire @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': normalizedEmail,
          'password': password,
          'faculty': faculty,
          'role': role,
          'level': 'L1',
          'bio': bio ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _token = data['token'];
        _user = data['user'];

        if (_token != null && _user != null) {
          await _saveToken(_token!);
          await _saveUserId(_user!['_id']);
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _error = 'Inscription reussie mais session incomplete';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _error = data['message'] ?? 'Inscription impossible';
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb && AppConfig.googleClientId.isEmpty) {
        _error =
            'Google Sign-In Web demande GOOGLE_CLIENT_ID. Lance Flutter avec --dart-define=GOOGLE_CLIENT_ID=votre_client_id_google.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleSignIn = GoogleSignIn(
        clientId: AppConfig.googleClientId.isEmpty
            ? null
            : AppConfig.googleClientId,
        scopes: const ['email', 'profile'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final email = googleUser.email;
      if (!email.endsWith('@usmba.ac.ma')) {
        _error = 'L email doit etre @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': googleUser.displayName ?? googleUser.email.split('@')[0],
          'email': email,
          'avatar': googleUser.photoUrl ?? '',
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'role': 'student',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data['user'];
        await _saveToken(_token!);
        await _saveUserId(_user!['_id']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? 'Connexion Google impossible';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur Google Login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'code': code}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'token': code,
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
    RealtimeService.instance.disconnect();
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

  void mergeUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
