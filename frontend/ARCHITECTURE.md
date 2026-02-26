# 🎨 ARCHITECTURE FLUTTER MODERNE - GUIDE COMPLET

## 📋 Table des matières
1. [Design System](#design-system)
2. [Gestion d'État avec Riverpod](#gestion-détat-avec-riverpod)
3. [Composants Réutilisables](#composants-réutilisables)
4. [Animations Fluides](#animations-fluides)
5. [Optimisation des Images](#optimisation-des-images)
6. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🎨 Design System

### Couleurs (`theme/app_colors.dart`)
```dart
// Couleurs primaires
Color primaryBlue = Color(0xFF003366);
Color primaryBlueDark = Color(0xFF001F47);
Color primaryBlueLight = Color(0xFF0052A3);

// Couleurs d'accent
Color accentPink = Color(0xFFE91E63);
Color accentGreen = Color(0xFF4CAF50);
Color accentOrange = Color(0xFFFF9800);
Color accentPurple = Color(0xFF9C27B0);

// Couleurs sémantiques
Color success = Color(0xFF4CAF50);
Color warning = Color(0xFFFFC107);
Color error = Color(0xFFF44336);
Color info = Color(0xFF2196F3);
```

### Typographie (`theme/app_typography.dart`)
Hiérarchie complète de TextStyles:
- **Display**: displayLarge, displayMedium, displaySmall (57px, 45px, 36px)
- **Headlines**: headlineLarge, headlineMedium, headlineSmall (32px, 28px, 24px)
- **Titles**: titleLarge, titleMedium, titleSmall (22px, 16px, 14px)
- **Body**: bodyLarge, bodyMedium, bodySmall (16px, 14px, 12px)
- **Labels**: labelLarge, labelMedium, labelSmall (14px, 12px, 11px)

### Espacements (`theme/app_spacing.dart`)
Grille de 4px:
```dart
// Base units
xs = 4    // 4px
sm = 8    // 8px
md = 12   // 12px
lg = 16   // 16px
xl = 20   // 20px
xl2 = 24  // 24px
...
```

### Thème (`theme/app_theme.dart`)
- ✅ Light Mode complètement stylisé
- ✅ Dark Mode avec contraste élevé
- ✅ Material 3 (Material You)
- ✅ Cohérence visuelle garantie

---

## 🔄 Gestion d'État avec Riverpod

### Architecture Provider

#### 1. **Auth Provider** (`providers/auth_provider.dart`)
```dart
// Vérifier si l'utilisateur est connecté
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return authService.isLoggedIn();
});

// Obtenir l'ID de l'utilisateur courant
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  return authService.getUserId();
});
```

#### 2. **Feed Provider** (`providers/feed_provider.dart`) - ⭐ Feed Infini
```dart
class FeedState {
  final List<dynamic> posts;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(postServiceProvider));
});

// Utilisation:
final feedNotifier = ref.read(feedProvider.notifier);
await feedNotifier.initializeFeed();  // Charger la 1ère page
await feedNotifier.loadMore();        // Charger plus
await feedNotifier.toggleLike(postId); // Like/Unlike
```

#### 3. **User Provider** (`providers/user_provider.dart`)
```dart
final userProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, userId) async {
    return ref.watch(userServiceProvider).getUser(userId);
  }
);

// Vérifier si on suit un utilisateur
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(currentUserProvider).following.contains(userId);
});
```

#### 4. **Notification Provider** (`providers/notification_provider.dart`)
```dart
final notificationsProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.watch(notificationServiceProvider)),
);

// Accéder aux notifications non-lues
ref.watch(notificationsProvider).unreadCount
```

#### 5. **Chat Provider** - Temps Réel WebSocket
```dart
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatServiceProvider));
});

// Envoyer un message
ref.read(chatProvider.notifier).sendMessage(userId, text);
```

#### 6. **Theme Provider** (`providers/theme_provider.dart`)
```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// Basculer le thème
ref.read(themeModeProvider.notifier).toggleTheme();
```

---

## 🎯 Composants Réutilisables

### 1. **SkeletonLoader** (`widgets/base_widgets.dart`)
Barre de chargement avec effet de shimmer
```dart
SkeletonLoader(
  width: 300,
  height: 100,
  borderRadius: BorderRadius.circular(12),
  isCircle: false,
)
```

### 2. **CachedAvatarImage**
Avatar avec image en cache et fallback
```dart
CachedAvatarImage(
  imageUrl: user['avatar'],
  size: 40,
)
```

### 3. **HeartLikeButton** - ❤️ Animation du cœur
Like button avec animation élastique
```dart
HeartLikeButton(
  isLiked: post['isLiked'],
  count: post['likesCount'],
  onPressed: () => ref.read(feedProvider.notifier).toggleLike(postId),
)
```

### 4. **AnimatedActionButton**
Bouton d'action avec animation de scale
```dart
AnimatedActionButton(
  icon: Icons.favorite,
  label: 'J\'aime',
  onPressed: onLikePressed,
  isSelected: isLiked,
)
```

### 5. **StoryCircle** (`widgets/story_circle.dart`)
Story avec gradient et indicateur de vue
```dart
StoryCircle(
  userId: user.id,
  userName: user.nom,
  avatarUrl: user.avatar,
  isViewed: true,
  gradientColors: [Colors.pink, Colors.orange],
  onTap: () => showStory(userId),
)

// Utilisation horizontale
StoriesHorizontalList(
  stories: storyList,
  onStoryTap: (userId) {},
  showAddYourStory: true,
)
```

### 6. **PostCard** (`widgets/post_card.dart`) - ⭐ Carte de post optimisée
```dart
PostCard(
  postId: post['_id'],
  authorName: post['author']['nom'],
  authorAvatarUrl: post['author']['avatar'],
  faculty: post['faculty']['name'],
  content: post['text'],
  mediaUrl: post['mediaUrl'],  // Lazy loading automatique
  createdAt: DateTime.parse(post['createdAt']),
  likesCount: post['likesCount'],
  commentsCount: post['commentsCount'],
  isLiked: post['isLiked'],
  isSaved: post['isSaved'],
  onLike: () => ref.read(feedProvider.notifier).toggleLike(post['_id']),
  onComment: () {},
  onSave: () => ref.read(feedProvider.notifier).toggleSave(post['_id']),
)
```

**Fonctionnalités:**
- ✅ Affichage optimisé des images avec caching
- ✅ Commentaires expandables
- ✅ Temps formaté intelligent (5m, 2h, 1j, etc.)
- ✅ Boutons d'action animés
- ✅ Création de commentaire intégré

### 7. **PhotoViewScreen** & **ImageGalleryViewer** (`widgets/photo_view_screen.dart`)
Visionneuse d'images full-screen avec zoom et swipe
```dart
// Simple
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => PhotoViewScreen(
      imageUrl: imageUrl,
      onDismiss: () => print('Closed'),
    ),
  ),
);

// Galerie
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ImageGalleryViewer(
      imageUrls: ['img1', 'img2', 'img3'],
      initialIndex: 0,
    ),
  ),
);
```

---

## 🎬 Animations Fluides

### 1. **HeartLikeButton Animation**
```dart
// Automatique: scale + opacity avec elasticOut curve
// Durée: 400ms
```

### 2. **StoryCircle Scale Animation**
```dart
// Press: scale 1.0 → 0.85
// Courbe: easeInOut
// Durée: 300ms
```

### 3. **Skeleton Loading Shimmer**
```dart
// Gradient qui se déplace horizontalement
// Durée: 1500ms
// Couleurs: greyLight200 → greyLight300 → greyLight200
```

### 4. **AnimatedActionButton**
```dart
// Scale animation on tap
// Scale: 1.0 → 1.2
// Courbe: easeInOut
// Durée: 300ms
```

### Custom Animations
```dart
class MyAnimatedWidget extends StatefulWidget {
  @override
  State<MyAnimatedWidget> createState() => _MyAnimatedWidgetState();
}

class _MyAnimatedWidgetState extends State<MyAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.md,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(),
    );
  }
}
```

---

## 📸 Optimisation des Images

### CachedNetworkImage
```dart
CachedNetworkImage(
  imageUrl: url,
  fit: BoxFit.cover,
  memCacheHeight: 200,    // Limiter la mémoire
  memCacheWidth: 200,
  cacheKey: url,          // Cache unique
  placeholder: (_) => SkeletonLoader(...),
  errorWidget: (_) => Icon(Icons.error),
)
```

### ImageUtils
```dart
// Charger avec caching
ImageUtils.cachedNetworkImage(
  imageUrl: url,
  fit: BoxFit.cover,
  width: 400,
  height: 300,
  borderRadius: BorderRadius.circular(12),
)

// Thumbnail pour liste
ImageUtils.cachedThumbnail(
  imageUrl: url,
  size: 100,
)

// Optimiser URLs groupées
final optimized = ImageUtils.optimizeImageUrls([url1, url2, url3]);
```

### Lazy Loading pour PostCard
```dart
// Automatique dans PostCard:
// - Images chargées uniquement si mediaUrl n'est pas null
// - SkeletonLoader pendant le chargement
// - Gestion d'erreurs intégré
```

### Vider le cache
```dart
await ImageMemoryManager.clearImageCache();
```

---

## 🔧 Extensions Utiles (`utils/extensions.dart`)

### Padding
```dart
widget.paddingAll(16)
widget.paddingSymmetric(horizontal: 16, vertical: 8)
widget.paddingOnly(left: 16, top: 12)
```

### Spacing
```dart
AppSpacing.lg.verticalSpace    // SizedBox(height: 16)
AppSpacing.md.horizontalSpace  // SizedBox(width: 12)
```

### Responsive
```dart
if (context.isSmallScreen) { ... }
if (context.isMediumScreen) { ... }
if (context.isLargeScreen) { ... }

final width = context.screenWidth;
final height = context.screenHeight;
```

### TextStyle
```dart
style.withColor(Colors.red)
style.withSize(20)
style.bold()
style.semiBold()
```

---

## ✅ Bonnes Pratiques

### 1. **Utiliser le Design System**
```dart
// ✅ BON
Text(
  'Titre',
  style: Theme.of(context).textTheme.headlineSmall,
)

// ❌ MAUVAIS
Text(
  'Titre',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)
```

### 2. **Gestion d'État avec Riverpod**
```dart
// ❌ MAUVAIS: setState
class MyWidget extends StatefulWidget {
  State createState() => MyState();
}

// ✅ BON: Riverpod
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
  }
}
```

### 3. **Caching des Images**
```dart
// ✅ BON
CachedNetworkImage(imageUrl: url, memCacheHeight: 200)

// ❌ MAUVAIS
Image.network(imageUrl)  // Pas de caching
```

### 4. **Pagination Infinie**
```dart
// ✅ BON: Feed Provider avec loadMore()
ListView.builder(
  onBottomReached: () => ref.read(feedProvider.notifier).loadMore(),
)

// ❌ MAUVAIS: Charger tout en même temps
FutureBuilder(future: getAllPosts())
```

### 5. **Validations**
```dart
// ✅ BON
if (ValidationUtils.isValidEmail(email)) { ... }

// ❌ MAUVAIS
if (email.contains('@')) { ... }
```

### 6. **Notifications**
```dart
// ✅ BON
NotificationUtils.showSuccessSnackBar(context, 'Succès!');

// ❌ MAUVAIS
ScaffoldMessenger.of(context).showSnackBar(...)
```

---

## 📱 Structure de Dossiers

```
lib/
├── main.dart                    # Point d'entrée avec ProviderScope
├── theme/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   └── app_theme.dart           # Thèmes light & dark
├── providers/                   # Gestion d'état Riverpod
│   ├── theme_provider.dart
│   ├── auth_provider.dart
│   ├── feed_provider.dart       # Feed infini ⭐
│   ├── user_provider.dart
│   └── notification_provider.dart
├── services/                    # Appels API
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── post_service.dart
│   └── ...
├── widgets/                     # Composants réutilisables
│   ├── base_widgets.dart        # SkeletonLoader, etc.
│   ├── post_card.dart           # ⭐ Optimisée
│   ├── story_circle.dart        # Avec animations
│   └── photo_view_screen.dart   # Visionneuse
├── screens/                     # Écrans
│   ├── home_screen.dart
│   ├── feed_screen.dart
│   └── ...
└── utils/                       # Helpers
    ├── extensions.dart
    ├── image_utils.dart
    ├── validation_utils.dart
    ├── notification_utils.dart
    └── app_config.dart
```

---

## 🚀 Démarrage Rapide

```dart
// 1. Importer Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 2. Envelopper l'app avec ProviderScope
runApp(const ProviderScope(child: MyApp()));

// 3. Utiliser dans les écrans
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    
    return feed.when(
      data: (posts) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(),
    );
  }
}
```

---

## 📊 Performances

- **Image Caching**: 7 jours par défaut
- **Feed Pagination**: 10 posts par page
- **Memory Management**: Max 200x200px en mémoire
- **Animation Duration**: 300ms (smooth)
- **Skeleton Loading**: 1500ms (fluide)

---

## 📚 Ressources

- [Riverpod Documentation](https://riverpod.dev)
- [Material Design 3](https://m3.material.io)
- [Flutter Performance](https://flutter.dev/performance)
- [CachedNetworkImage](https://pub.dev/packages/cached_network_image)

---

**Créé pour USMBA Social - Plateforme Universitaire Moderne 🎓**
