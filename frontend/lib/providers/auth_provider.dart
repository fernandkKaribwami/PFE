import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String get role => _user?['role']?.toString() ?? 'student';
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
      if (!email.endsWith('@usmba.ac.ma')) {
        _error = 'Email doit être un email universitaire @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$API_URL/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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
      final baseError =
          'Échec de connexion au serveur. Vérifiez que le backend est démarré à $API_URL et que votre réseau autorise la connexion.';
      _error = e.toString().contains('SocketException')
          ? '$baseError (Erreur réseau)'
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
      if (!email.endsWith('@usmba.ac.ma')) {
        _error = 'Email doit être un email universitaire @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$API_URL/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'faculty': faculty,
          'role': role,
          'level': 'L1',
          'bio': bio ?? '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        if (_token != null && _user != null) {
          await _saveToken(_token!);
          await _saveUserId(_user!['id']);
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _error = 'Registration succeeded but server did not return token/user';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _error =
              errorData['message'] ??
              errorData['error'] ??
              errorData['msg'] ??
              'Registration failed';
        } catch (_) {
          _error =
              'Registration failed: ${response.statusCode} ${response.reasonPhrase ?? ''}';
        }
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final email = googleUser.email;
      if (!email.endsWith('@usmba.ac.ma')) {
        _error = 'L’email doit être @usmba.ac.ma';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$API_URL/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': googleUser.displayName ?? googleUser.email.split('@')[0],
          'email': email,
          'avatar': googleUser.photoUrl ?? '',
          'role': 'student',
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
        _error = errorData['msg'] ?? 'Google login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Google Login error: $e';
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
        body: jsonEncode({'email': email, 'verificationCode': code}),
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

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
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
