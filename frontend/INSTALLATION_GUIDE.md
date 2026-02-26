# 🚀 GUIDE D'INSTALLATION & SETUP

## 1️⃣ Installation des dépendances

```bash
# Naviguer au répertoire frontend
cd frontend

# Mettre à jour pubspec.yaml (déjà fait ✅)
# puis installer les dépendances
flutter pub get

# Générer les fichiers Riverpod
flutter pub run build_runner build --delete-conflicting-outputs

# Nettoyer et rebuild
flutter clean
flutter pub get
```

## 2️⃣ Configuration initiale

### Si vous utilisez Android:
```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

### Si vous utilisez iOS:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

## 3️⃣ Vérifier l'installation

```bash
# Tester que tout fonctionne
flutter doctor

# Lancer sur émulateur/device
flutter run

# Lancer en mode release (optimisé)
flutter run --release
```

---

## ✅ Checklist Post-Installation

### Configuration du projet
- [ ] pubspec.yaml mis à jour avec les nouvelles dépendances
- [ ] `flutter pub get` exécuté avec succès
- [ ] Pas d'erreurs de compilation
- [ ] Riverpod code generation build_runner fonctionnel

### Design System
- [ ] All theme files créés dans `lib/theme/`
- [ ] Colors accessible via `AppColors.*`
- [ ] Typography accessible via `AppTypography.*`
- [ ] Spacing accessible via `AppSpacing.*`

### Providers
- [ ] `providers/` dossier créé
- [ ] Tous les providers Riverpod disponibles
- [ ] `themeModeProvider` fonctionne
- [ ] `feedProvider` avec infinite scroll fonctionne

### Widgets
- [ ] `widgets/` dossier créé avec tous les composants
- [ ] `SkeletonLoader` disponible
- [ ] `PostCard` avec image caching disponible
- [ ] `StoryCircle` avec animations disponible
- [ ] `PhotoViewScreen` pour galerie disponible

### Utils
- [ ] Extensions (`paddingAll()`, `withColor()`, etc.)
- [ ] `ImageUtils` pour caching
- [ ] `ValidationUtils` pour validations
- [ ] `NotificationUtils` pour SnackBar/Dialog

### Documentation
- [ ] `ARCHITECTURE.md` consultable
- [ ] `INTEGRATION_GUIDE.dart` checké
- [ ] `modern_feed_screen.dart` étudié
- [ ] `modern_profile_screen.dart` étudié

---

## 🎨 Test du Design System

Pour vérifier que le design system fonctionne:

```dart
// Tester les couleurs
import 'theme/app_colors.dart';

Container(
  color: AppColors.primaryBlue,  // ✅ Devrait être bleu USMBA
)

// Tester la typographie
import 'theme/app_typography.dart';

Text(
  'Titre',
  style: AppTypography.headlineSmall,  // ✅ Grande et bold
)

// Tester les espacements
import 'theme/app_spacing.dart';

Padding(
  padding: EdgeInsets.all(AppSpacing.lg),  // ✅ Padding 16px
)
```

---

## 🔄 Test du Feed Infini

Pour tester que le feed infini fonctionne:

```dart
// Dans modern_feed_screen.dart
// 1. Scroll vers le bas de la liste
// 2. Vérifier que plus de posts se chargent automatiquement
// 3. Vérifier que le loading indicator apparaît
// 4. Vérifier que les images se chargent avec shimmer
```

---

## 🎭 Test du Theme Switcher

Pour vérifier que le light/dark mode fonctionne:

```dart
// 1. Appuyer sur l'icône de thème en haut à droite
// 2. Vérifier que l'application passe en dark mode
// 3. Fermer et rouvrir l'app
// 4. Vérifier que le thème est sauvegardé (persistence)
```

---

## 🏗️ Architecture de Dossiers Finale

Après installation complète, vous devriez avoir:

```
frontend/
├── lib/
│   ├── main.dart                      # Entry point avec ProviderScope
│   ├── INTEGRATION_GUIDE.dart         # Guide d'intégration
│   │
│   ├── theme/                         # 🎨 Design System
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   │
│   ├── providers/                     # 🔄 État avec Riverpod
│   │   ├── theme_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── feed_provider.dart         # ⭐ Feed infini
│   │   ├── user_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── services/                      # 📡 API Calls
│   │   ├── api_service.dart           # (existant)
│   │   ├── auth_service.dart          # (existant)
│   │   ├── post_service.dart          # (existant)
│   │   └── ...
│   │
│   ├── widgets/                       # 🧩 Composants réutilisables
│   │   ├── base_widgets.dart          # SkeletonLoader, CachedAvatar, etc.
│   │   ├── post_card.dart             # ⭐ PostCard optimisée
│   │   ├── story_circle.dart          # Stories avec animations
│   │   └── photo_view_screen.dart     # Galerie images
│   │
│   ├── screens/                       # 📱 Écrans
│   │   ├── feed_screen.dart           # (existant)
│   │   ├── modern_feed_screen.dart    # ✨ NEW - Feed moderne
│   │   ├── modern_profile_screen.dart # ✨ NEW - Profil moderne
│   │   └── ...
│   │
│   └── utils/                         # 🛠️ Helpers
│       ├── extensions.dart            # Padding, TextStyle, Responsive
│       ├── image_utils.dart           # ImageUtils, CacheManager
│       ├── validation_utils.dart      # Email, Password, Text validation
│       ├── notification_utils.dart    # SnackBar, Dialog, Toast
│       └── app_config.dart            # Config globale & Exceptions
│
├── ARCHITECTURE.md                    # 📚 Documentation détaillée
├── IMPLEMENTATION_CHECKLIST.md        # ✅ Checklist d'implémentation
├── pubspec.yaml                       # (mis à jour ✅)
└── ...
```

---

## 🐛 Erreurs Communes & Solutions

### Erreur: `ProviderScope not found`
```
Solution:
✅ Envelopper runApp() avec ProviderScope
✅ import 'package:flutter_riverpod/flutter_riverpod.dart';
```

### Erreur: `CachedNetworkImage` not found
```
Solution:
✅ S'assurer que cached_network_image est dans pubspec.yaml
✅ flutter pub get
```

### Images ne se chargent pas
```
Solution:
✅ Vérifier la validité des URLs (http:// ou https://)
✅ Vérifier la connectivité réseau
✅ Augmenter le timeout dans ApiService
```

### Feed infinite scroll ne fonctionne pas
```
Solution:
✅ S'assurer que le ScrollController est attaché au ListView
✅ Vérifier que _onScroll() est appelé
✅ Vérifier les indices dans itemCount
```

### Theme ne persiste pas après redémarrage
```
Solution:
✅ S'assurer que SharedPreferences est initialisé
✅ Vérifier que ThemeModeNotifier sauvegarde le mode
```

---

## 📊 Performance Checklist

- [ ] Images cachées dans la mémoire
- [ ] Pas de memory leaks (teste avec DevTools)
- [ ] Feed infinite scroll fluide (60 fps)
- [ ] Animations lisses (300ms duration)
- [ ] Aucune requête API dupliquée

---

## 🔗 Intégration avec API existante

Les services existants sont déjà configurés:

```dart
// PostService récupère maintenant les posts avec Riverpod:
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(postServiceProvider));
});

// L'API_URL peut être mise à jour dans utils/app_config.dart:
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:5000';
}
```

---

## 🚀 Production Deployment

Avant de déployer en production:

```bash
# 1. Tester le build release
flutter build apk --release
flutter build ios --release

# 2. Vérifier les permissions Android (AndroidManifest.xml)
# 3. Vérifier les permissions iOS (Info.plist)
# 4. Tester sur device physique
# 5. Vérifier la connectivité API
# 6. Analyser la performance avec DevTools
# 7. Exécuter flutter analyze
flutter analyze
```

---

## 📞 Support & Questions

Si vous avez des questions ou rencontrez des problèmes:

1. Consultez la [documentation Riverpod](https://riverpod.dev)
2. Lisez le fichier [ARCHITECTURE.md](./ARCHITECTURE.md)
3. Étudiez les exemples dans [modern_feed_screen.dart](./lib/screens/modern_feed_screen.dart)
4. Vérifiez le [INTEGRATION_GUIDE.dart](./lib/INTEGRATION_GUIDE.dart)

---

**✨ Vous êtes prêt à utiliser l'architecture Flutter moderne pour USMBA Social!**

*Bonne chance avec votre plateforme universitaire! 🎓*
