import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider((ref) => UserService());

// Provider pour les données d'un utilisateur spécifique
final userProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getUser(userId);
});

// État pour le profil de l'utilisateur courant
class ProfileState {
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final String? error;
  final List<String> followers;
  final List<String> following;

  ProfileState({
    this.userData,
    this.isLoading = false,
    this.error,
    this.followers = const [],
    this.following = const [],
  });

  ProfileState copyWith({
    Map<String, dynamic>? userData,
    bool? isLoading,
    String? error,
    List<String>? followers,
    List<String>? following,
  }) {
    return ProfileState(
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}

// Provider pour la gestion du profil utilisateur
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, ProfileState>(
  (ref) => CurrentUserNotifier(ref.watch(userServiceProvider)),
);

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
