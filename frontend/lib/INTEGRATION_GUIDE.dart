/// GUIDE D'INTÉGRATION COMPLÈTE - FLUTTER MODERN ARCHITECTURE
/// 
/// Ce fichier montre comment intégrer tous les composants créés :
/// - Design System (Couleurs, Typography, Spacing)
/// - Gestion d'état avec Riverpod
/// - Composants réutilisables
/// - Animations fluides
/// - Caching et images optimisées
///

// ============================================================================
// 1. MISE À JOUR DE main.dart
// ============================================================================

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser SharedPreferences, etc.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'USMBA Social',
      debugShowCheckedModeBanner: false,
      themeMode: _toThemeMode(themeMode),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }

  ThemeMode _toThemeMode(dynamic mode) {
    if (mode is ThemeMode) return mode;
    return ThemeMode.system;
  }
}
*/

// ============================================================================
// 2. EXEMPLE D'ÉCRAN UTILISANT LE FEED INFINI & RIVERPOD
// ============================================================================

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/base_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Charger le feed au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).initializeFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fil d\'actualité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: feedState.posts.isEmpty && !feedState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.greyLight400,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucun post disponible',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: feedState.posts.length +
                  (feedState.isLoading && feedState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == feedState.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  );
                }

                final post = feedState.posts[index];

                return PostCard(
                  postId: post['_id'],
                  authorId: post['author']['_id'],
                  authorName: post['author']['nom'],
                  authorAvatarUrl: post['author']['avatar'],
                  faculty: post['faculty']?['name'] ?? 'USMBA',
                  content: post['text'],
                  mediaUrl: post['mediaUrl'],
                  createdAt: DateTime.parse(post['createdAt']),
                  likesCount: post['likesCount'] ?? 0,
                  commentsCount: post['commentsCount'] ?? 0,
                  isLiked: post['isLiked'] ?? false,
                  isSaved: post['isSaved'] ?? false,
                  onLike: () => ref
                      .read(feedProvider.notifier)
                      .toggleLike(post['_id']),
                  onComment: () {
                    // Afficher les commentaires
                  },
                  onSave: () => ref
                      .read(feedProvider.notifier)
                      .toggleSave(post['_id']),
                  onMore: () {
                    // Menu d'options
                  },
                );
              },
            ),
    );
  }
}
*/

// ============================================================================
// 3. EXEMPLE D'UTILISATION DES ANIMATIONS
// ============================================================================

/*
class AnimatedExampleScreen extends StatelessWidget {
  const AnimatedExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Like button animé
            const Text('Like Button Animé'),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: HeartLikeButton(
                isLiked: false,
                count: 42,
                onPressed: () {},
              ),
            ),

            const SizedBox(height: AppSpacing.xl2),

            // Story circles
            const Text('Story Circles'),
            const SizedBox(height: AppSpacing.md),
            StoriesHorizontalList(
              stories: [
                {
                  'userId': '1',
                  'userName': 'Ahmed Ali',
                  'avatarUrl': null,
                  'isViewed': false,
                },
                {
                  'userId': '2',
                  'userName': 'Fatima Ben',
                  'avatarUrl': null,
                  'isViewed': true,
                },
              ],
              onStoryTap: (userId) {
                if (userId == 'add_story') {
                  // Ajouter une story
                }
              },
            ),

            const SizedBox(height: AppSpacing.xl2),

            // Skeleton loader
            const Text('Skeleton Loader'),
            const SizedBox(height: AppSpacing.md),
            SkeletonLoader(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}
*/

// ============================================================================
// 4. ORGANISATION DES DOSSIERS RECOMMANDÉE
// ============================================================================

/*
lib/
├── main.dart
├── theme/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   └── app_theme.dart
├── providers/
│   ├── theme_provider.dart
│   ├── auth_provider.dart
│   ├── feed_provider.dart
│   ├── user_provider.dart
│   └── notification_provider.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── post_service.dart
│   ├── user_service.dart
│   ├── chat_service.dart
│   ├── notification_service.dart
│   └── ... (autres services)
├── widgets/
│   ├── base_widgets.dart
│   ├── post_card.dart
│   ├── story_circle.dart
│   ├── photo_view_screen.dart
│   └── ... (autres widgets)
├── screens/
│   ├── home_screen.dart
│   ├── feed_screen.dart
│   ├── profile_screen.dart
│   ├── chat_screen.dart
│   └── ... (autres écrans)
└── utils/
    ├── extensions.dart
    ├── image_utils.dart
    ├── validation_utils.dart
    ├── notification_utils.dart
    └── app_config.dart
*/

// ============================================================================
// 5. BEST PRACTICES
// ============================================================================

/*
✅ BONNES PRATIQUES:
1. Toujours utiliser les constantes du Design System (AppColors, AppSpacing, etc.)
2. Préférer Riverpod pour l'état qu'à Provider
3. Utiliser des FutureProviders pour les requêtes asynchrones
4. Implémenter le caching pour les images (CachedNetworkImage)
5. Utiliser des extensions pour réduire le boilerplate
6. Tester les validations avec ValidationUtils
7. Afficher les notifications avec NotificationUtils
8. Appliquer les animations pour les interactions utilisateur
9. Optimiser les images avec ImageUtils
10. Respecter la hiérarchie typographique

❌ À ÉVITER:
- Hardcoder les couleurs, espacements, tailles
- Faire trop de requêtes API sans caching
- Utiliser setState au lieu de Riverpod
- Charger toutes les images à pleine résolution
- Ignorer les validations utilisateur
- Créer du code non réutilisable
- Ignorer les erreurs réseau
- Surcharger les widgets avec trop de logique
- Ne pas tester la responsive design
- Ne pas implémenter le theme switcher

⚙️ CONFIGURATION RIVERPOD:
// Pour les données simples et synchrones:
final simpleProvider = Provider<String>((ref) => 'value');

// Pour les données asynchrones (requêtes API):
final asyncProvider = FutureProvider<List<Post>>((ref) async {
  return await ref.watch(postServiceProvider).getPosts();
});

// Pour l'état mutable (user actions):
final mutableStateProvider = StateProvider<int>((ref) => 0);

// Pour les StateNotifiers (logique complexe):
final complexProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(ref.watch(someService)),
);

// Avec paramétrisation:
final parameterizedProvider = FutureProvider.family<Post, String>(
  (ref, postId) async {
    return await ref.watch(postServiceProvider).getPost(postId);
  },
);
*/

// ============================================================================
// 6. EXEMPLE DE GESTION D'ÉTAT POUR UN FORMULAIRE
// ============================================================================

/*
class FormState {
  final String email;
  final String password;
  final bool isLoading;
  final String? error;

  FormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
  });

  FormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? error,
  }) {
    return FormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FormNotifier extends StateNotifier<FormState> {
  FormNotifier() : super(FormState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Faire la requête
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final formProvider = StateNotifierProvider<FormNotifier, FormState>(
  (ref) => FormNotifier(),
);
*/
