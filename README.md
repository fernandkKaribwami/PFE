# 🎓 USMBA Social Network - Application Instagram-like Moderne

Un réseau social moderne et intuitif dédié à l'université Sidi Mohamed Ben Abdellah (USMBA), développé avec Flutter et Node.js.

## ✨ Fonctionnalités Principales

### 🔐 Authentification Sécurisée
- ✅ Inscription avec avatar personnalisé
- ✅ Connexion sécurisée avec JWT
- ✅ Validation d'email en temps réel
- ✅ Gestion des rôles utilisateurs

### 📱 Interface Utilisateur Moderne
- ✅ Design Material Design 3
- ✅ Navigation par onglets (Instagram-like)
- ✅ Animations fluides et transitions
- ✅ Mode sombre/clair
- ✅ Interface responsive

### 🏠 Fil d'Actualité
- ✅ Feed infini avec pagination
- ✅ Stories en haut du feed
- ✅ Posts avec images et vidéos
- ✅ Likes et commentaires en temps réel
- ✅ Pull-to-refresh

### 👤 Profils Utilisateur
- ✅ Profils complets avec statistiques
- ✅ Modification de profil
- ✅ Système de followers/following
- ✅ Grille de posts

### 🔍 Recherche
- ✅ Recherche globale d'utilisateurs
- ✅ Recherche de posts et groupes
- ✅ Résultats en temps réel

### 📝 Création de Contenu
- ✅ Créer des posts avec texte
- ✅ Upload d'images depuis galerie/appareil photo
- ✅ Support vidéo (bientôt)
- ✅ Paramètres de confidentialité

### 💬 Messagerie (Base)
- ✅ Interface de chat préparée
- ✅ WebSocket pour temps réel

## 🏗️ Architecture Technique

### Backend (Node.js + Express + MongoDB)
```
✅ Serveur Express sécurisé avec middlewares
✅ Authentification JWT robuste
✅ Base de données MongoDB avec Mongoose
✅ API RESTful complète
✅ WebSocket pour temps réel
✅ Gestion d'uploads de fichiers
✅ Validation et sanitisation des données
✅ Rate limiting et sécurité
```

### Frontend (Flutter + Provider)
```
✅ Architecture Provider pour state management
✅ UI moderne avec Material Design 3
✅ Navigation par bottom tabs
✅ Animations et transitions fluides
✅ Gestion d'état réactive
✅ Cache d'images optimisé
✅ Interface responsive
```

## 🚀 Démarrage Rapide

### Option 1: Script Automatique (Recommandé)

**Windows:**
```bash
# Double-cliquez sur start.bat ou exécutez:
./start.bat
```

**Linux/Mac:**
```bash
chmod +x start.sh
./start.sh
```

### Option 2: Démarrage Manuel

**1. Backend:**
```bash
cd backend
npm install
node server.js
```

**2. Frontend (dans un nouveau terminal):**
```bash
cd frontend
flutter pub get
flutter run -d chrome  # ou flutter run -d <device-id>
```

### 3. Configuration

Le fichier `.env` contient :
```
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production_2026
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/usmba_social
NODE_ENV=development
CLIENT_URL=http://localhost:3000
```

## 📱 Utilisation

1. **Inscription**: Créez un compte avec email @usmba.ac.ma
2. **Connexion**: Utilisez vos identifiants
3. **Navigation**: Utilisez la barre de navigation du bas
4. **Posts**: Créez du contenu depuis l'onglet central
5. **Interaction**: Likez et commentez les posts

## 🔧 Scripts Disponibles

### Backend
```bash
npm install          # Installer dépendances
node server.js       # Démarrer serveur
node seed.js         # Seeder les facultés
```

### Frontend
```bash
flutter pub get      # Installer dépendances
flutter run          # Lancer l'app
flutter build apk    # Build Android
```

## 📊 État du Projet

### ✅ Implémenté
- [x] Architecture backend sécurisée
- [x] Authentification complète
- [x] UI moderne Flutter
- [x] Navigation par onglets
- [x] Feed avec pagination
- [x] Création de posts
- [x] Profils utilisateur
- [x] Recherche
- [x] Animations et transitions

### 🚧 En Développement
- [ ] Messagerie temps réel complète
- [ ] Notifications push
- [ ] Stories Instagram-like
- [ ] Groupes et événements
- [ ] Mode hors ligne

### 📋 À Venir
- [ ] Marketplace étudiant
- [ ] Covoiturage
- [ ] Notes de cours
- [ ] Système de badges

## 🛡️ Sécurité

- ✅ JWT avec expiration
- ✅ Hashage des mots de passe (bcrypt)
- ✅ Validation des entrées
- ✅ Rate limiting
- ✅ CORS configuré
- ✅ Sanitisation des données
- ✅ Gestion des erreurs

## 🎨 Design System

- **Couleurs**: Palette USMBA (bleu principal)
- **Typographie**: Material Design 3
- **Composants**: Widgets réutilisables
- **Animations**: Transitions fluides
- **Responsive**: Adapté mobile/desktop

## 📈 Performance

- ✅ Lazy loading des images
- ✅ Pagination efficace
- ✅ Cache optimisé
- ✅ State management réactif
- ✅ Animations 60fps

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature
3. Committez vos changements
4. Push et créez une PR

## 📝 License

Projet universitaire - USMBA 2026

---

Développé avec ❤️ pour la communauté USMBA

## ✨ Fonctionnalités Implémentées

### 🔐 Authentification & Sécurité (100%)
- ✅ Inscription avec avatar
- ✅ Connexion par email/mot de passe
- ✅ Vérification email (code 6 chiffres)
- ✅ Réinitialisation de mot de passe
- ✅ JWT Authentication (7 jours)
- ✅ Rôles utilisateurs (student, teacher, admin)
- ✅ Blocage d'utilisateurs

### 📱 fil d'Actualité (100%)
- ✅ Pagination infinie (infinite scroll)
- ✅ Posts avec texte, images, vidéos
- ✅ #Hashtags automatiques
- ✅ @Mentions d'utilisateurs
- ✅ J'aime (likes) en temps réel
- ✅ Commentaires
- ✅ Sauvegarder posts
- ✅ Signaler contenu
- ✅ Suppression par auteur/admin

### 👥 Profils & Suivi (100%)
- ✅ Profils complets avec stats
- ✅ Follow/Unfollow
- ✅ Followers/Following counts
- ✅ Bio et intérêts
- ✅ Filière et niveau d'études
- ✅ Photo de profil

### 💬 Messagerie Instantanée (100%)
- ✅ Chat privé style Messenger
- ✅ Conversations en temps réel (Socket.IO)
- ✅ Historique des messages
- ✅ Notifications de nouveaux messages
- ✅ Liste des conversations actives

### 🏢 Facultés Universitaires (100%)
- ✅ 11 facultés USMBA seeded:
  - Faculté des Sciences Dhar El Mahraz – Fès
  - Faculté des Lettres et Sciences Humaines Saïs – Fès
  - Faculté des Sciences Juridiques, Économiques et Sociales
  - Faculté de Médecine et de Pharmacie
  - ENSA Fès & Taza
  - EST Fès
  - Faculté Polydisciplinaire Taza
  - École Sup d'Éducation et Formation
  - Institut Sciences du Sport
  - Centres de recherche
- ✅ Pages dédiées par faculté
- ✅ Fil d'actualité par faculté
- ✅ Liste des membres

### 👥 Groupes & Clubs (100%)
- ✅ Créer groupes (publics/privés)
- ✅ Catégories: classe, club, filière, sports, culturel
- ✅ Joindre/Quitter groupes
- ✅ Posts dans groupes
- ✅ Admin & modération

### 🎉 Événements Universitaires (100%)
- ✅ Créer événements (conférences, examens, séminaires)
- ✅ Images & descriptions
- ✅ Dates & lieux
- ✅ RSVP (J'y vais / Intéressé)
- ✅ Capacité max attendees
- ✅ Listing avec filtres par catégorie/faculté

### 🔔 Notifications en Temps Réel (100%)
- ✅ Likes sur posts
- ✅ Nouveaux commentaires
- ✅ Nouveaux followers
- ✅ Invitations groupes
- ✅ Annonces facultés
- ✅ Reminders événements
- ✅ Format "non-lu" vs "lu"
- ✅ WebSocket real-time push

### 🔍 Recherche Globale (100%)
- ✅ Recherche utilisateurs
- ✅ Recherche posts (texte + hashtags)
- ✅ Recherche groupes
- ✅ Recherche facultés
- ✅ Résultats multi-type

### 🛡️ Admin Dashboard (100%)
- ✅ Gestion utilisateurs
- ✅ Modération posts
- ✅ Gestion signalements
- ✅ Statistiques globales
- ✅ Actions: supprimer, suspendre, bannir

## 🏗️ Architecture Technique

### Backend (Node.js + Express)
```
server.js (1400+ lignes)
├── Auth routes (/register, /login, /verify-email, /reset-password)
├── User routes (/user/:id, /follow, /unfollow, /block)
├── Post routes (CRUD + like/comment/save/report)
├── Faculty routes (get + posts + members)
├── Group routes (CRUD + join/leave + posts)
├── Event routes (CRUD + RSVP)
├── Notification routes (get + markRead + delete)
├── Search routes (global search)
├── Admin routes (reports, users, dashboard)
├── Message routes (send + get + conversations)
└── Socket.IO (real-time chat + notifications)
```

### MongoDB Collections
- `users` - Profils avec followers/following
- `posts` - Publications avec likes/comments
- `comments` - Commentaires sur posts
- `saves` - Posts sauvegardés
- `reports` - Signalements de contenu
- `groups` - Groupes et clubs
- `events` - Événements universitaires
- `notifications` - Notifications en temps réel
- `messages` - Messages privés
- `faculties` - Données des 11 facultés

### Flutter Frontend
```
lib/
├── services/
│   ├── api_service.dart (base HTTP client)
│   ├── auth_service.dart
│   ├── post_service.dart
│   ├── chat_service.dart
│   ├── group_service.dart
│   ├── event_service.dart
│   ├── user_service.dart
│   ├── faculty_service.dart
│   └── notification_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── verify_email_screen.dart
│   ├── feed_screen.dart (infinite scroll)
│   ├── profile_screen.dart
│   ├── chat_screen.dart
│   └── create_post_screen.dart
└── main.dart
```

## 🚀 Quick Start

### Backend Setup

```bash
cd g:\Desktop\PFE\backend
npm install
# npm insall si besoin: express mongoose cors bcryptjs jsonwebtoken multer socket.io dotenv

# Seed faculties
node seed.js

# Lancer serveur
node server.js
# Server will run on http://localhost:5000
```

### Frontend Setup

```bash
cd g:\Desktop\PFE\frontend
flutter pub get
flutter run -d chrome
# or for mobile: flutter run -d <device-id>
```

### Environment Variables (Backend)

Créez un `.env` dans `backend/`:
```
JWT_SECRET=your_super_secret_key_here
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/usmba_social
```

## 📋 API Endpoints Reference

### Auth
- `POST /register` - Inscription
- `POST /login` - Connexion
- `POST /auth/verify-email` - Vérifier email
- `POST /auth/request-password-reset` - Demander reset
- `POST /auth/reset-password` - Réinitialiser mdp

### Users
- `GET /user/:id` - Profil utilisateur
- `PUT /user/:id` - Modifier profil
- `POST /follow/:id` - Suivre
- `POST /unfollow/:id` - Ne pas suivre
- `POST /block/:id` - Bloquer

### Posts
- `POST /posts` - Créer post
- `GET /posts` - Fil d'actualité (pagination)
- `GET /posts/user/:userId` - Posts utilisateur
- `POST /posts/:id/like` - Aimer/disliker
- `POST /posts/:id/comment` - Commenter
- `GET /posts/:id/comments` - Commentaires
- `POST /posts/:id/save` - Sauvegarder
- `POST /posts/:id/report` - Signaler
- `DELETE /posts/:id` - Supprimer

### Faculties
- `GET /faculties` - Toutes les facultés
- `GET /faculties/:id` - Details faculté
- `GET /faculties/:id/posts` - Posts de faculté
- `GET /faculties/:id/members` - Membres

### Groups
- `POST /groups` - Créer groupe
- `GET /groups` - Lister groupes
- `GET /groups/:id` - Détails groupe
- `POST /groups/:id/join` - Rejoindre
- `POST /groups/:id/leave` - Quitter
- `GET /groups/:id/posts` - Posts du groupe

### Events
- `POST /events` - Créer événement
- `GET /events` - Lister événements
- `GET /events/:id` - Détails événement
- `POST /events/:id/rsvp` - RSVP

### Messages
- `POST /messages` - Envoyer message
- `GET /messages/:userId` - Conversation
- `GET /conversations` - Liste conversations

### Admin
- `GET /admin/dashboard` - Stats globales
- `GET /admin/reports` - Signalements
- `PUT /admin/reports/:id` - Traiter signalement
- `GET /admin/users` - Lister utilisateurs

### Search
- `GET /search?q=query` - Recherche globale

## 🎨 UI/UX Features

✅ Material Design 3
✅ Dark mode ready
✅ Responsive layout
✅ Infinite scroll feed
✅ Real-time notifications
✅ Image/video preview
✅ Loading states
✅ Error handling
✅ Pull-to-refresh
✅ Bottom navigation

## 🔒 Security Implemented

- ✅ JWT authentication with expiry
- ✅ Password hashing (bcrypt 10 rounds)
- ✅ CORS configuration
- ✅ File upload validation
- ✅ Input sanitization
- ✅ User role-based access control
- ✅ Token stored in SharedPreferences

## 📦 Project Statistics

**Backend:**
- Lines of code: 1400+
- Models: 10 (User, Post, Comment, Save, Report, Group, Event, Notification, Message, Faculty)
- API Endpoints: 45+
- Database collections: 10

**Frontend:**
- Services: 8 complete
- Screens: 7+
- Lines of Flutter code: 800+

**Total:** 
- ~2500+ lines of production code
- ~50+ API endpoints fully functional
- Real-time WebSocket integration
- Full university social network

## 🌟 Next Steps (Optional Enhancements)

- Email verification avec Nodemailer
- Google OAuth integration
- Instagram-style stories
- Live streaming conférences
- Marketplace étudiant
- Offres de stage
- Covoiturage
- Notes de cours partagées
- Badges de contribution
- Rating professorale
- Système de points/rewards

## 📝 Notes Importantes

1. **MongoDB**: Assurez-vous que MongoDB tourne sur `localhost:27017`
2. **API URL**: Le frontend utilise `http://localhost:5000` par défaut
3. **Uploads**: Les fichiers sont sauvegardés dans `/backend/uploads`
4. **Token**: JWT valide 7 jours
5. **Verification Code**: Retourné en réponse d'inscription (dev mode)

## 🤝 License

Projet universitaire - USMBA 2025

---

Créé avec ❤️ pour l'université Sidi Mohamed Ben Abdellah
