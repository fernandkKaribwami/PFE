import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

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
        Uri.parse('$API_URL/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data;
        _error = null;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Network error: $e';
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
        Uri.parse('$API_URL/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data;
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Failed to update profile';
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

  Future<bool> followUser(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/users/follow/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local user data if needed
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
        Uri.parse('$API_URL/api/users/unfollow/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local user data if needed
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
}

class CurrentUserNotifier extends StateNotifier<ProfileState> {
  final UserService _userService;

  CurrentUserNotifier(this._userService) : super(ProfileState());

  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _userService.getUser(userId);
      state = ProfileState(
        userData: user,
        isLoading: false,
        followers: List<String>.from(user?['followers'] ?? []),
        following: List<String>.from(user?['following'] ?? []),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await _userService.followUser(userId);
      state = state.copyWith(
        following: [...state.following, userId],
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _userService.unfollowUser(userId);
      final updated = List<String>.from(state.following);
      updated.remove(userId);
      state = state.copyWith(following: updated);
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _userService.blockUser(userId);
      state = state.copyWith(
        error: 'Utilisateur bloqué',
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }
}

// Provider pour vérifier si on suit un utilisateur
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser.following.contains(userId);
});
