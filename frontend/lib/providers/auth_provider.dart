import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Provider pour l'état d'authentification
final authServiceProvider = Provider((ref) => AuthService());

// Provider pour l'utilisateur courant
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserId();
});

// Provider pour l'état de connexion
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.isLoggedIn();
});

// Provider pour le token
final tokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserId();
});

// Provider pour la gestion d'erreur
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Provider pour le state de chargement global
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Provider pour la connectivité
final isOnlineProvider = StateProvider<bool>((ref) => true);
