# Rapport PFE

## Conception et developpement d'une application mobile et web de reseau social universitaire pour l'USMBA

### Intitule du projet

USMBA Social est une application de reseau social universitaire concue pour connecter les etudiants, enseignants et administrateurs de l'Universite Sidi Mohamed Ben Abdellah. Le projet met en relation une application Flutter multi-plateforme, une API REST Node.js / Express, une base MongoDB et une couche temps reel basee sur Socket.IO.

### Informations generales

- Nature du projet : Projet de Fin d'Etudes
- Domaine : Developpement mobile, web et systemes distribues
- Type d'application : Reseau social universitaire
- Frontend : Flutter / Dart
- Backend : Node.js / Express
- Base de donnees : MongoDB / Mongoose
- Communication temps reel : Socket.IO
- Plateformes cibles : Web, Android, iOS

---

## Sommaire

1. Remerciements
2. Resume du projet
3. Liste des abreviations
4. Introduction generale
5. Chapitre 1 : Cadre et contexte du projet
6. Chapitre 2 : Analyse des besoins et cahier des charges
7. Chapitre 3 : Technologies et outils utilises
8. Chapitre 4 : Architecture et conception de l'application
9. Chapitre 5 : Presentation fonctionnelle de l'application
10. Chapitre 6 : Explication technique des modules et du code
11. Chapitre 7 : Tests, securite, performance, limites et perspectives
12. Conclusion generale
13. Annexes

---

## Remerciements

Je remercie toutes les personnes ayant contribue a la realisation de ce projet de fin d'etudes. Mes remerciements s'adressent en premier lieu aux encadrants pedagogiques et professionnels qui ont apporte leur accompagnement, leurs conseils techniques et leurs remarques constructives tout au long de la conception et du developpement de l'application.

Je remercie egalement les enseignants, les camarades et les utilisateurs ayant participe aux retours fonctionnels sur l'ergonomie, les besoins du milieu universitaire et la pertinence des fonctionnalites proposees. Leurs observations ont permis d'ameliorer la qualite globale du systeme.

Enfin, j'exprime ma gratitude envers ma famille et toutes les personnes qui m'ont soutenu moralement durant la realisation de ce travail.

---

## Resume

Ce projet presente la conception et la mise en oeuvre d'une application complete de reseau social universitaire nommee USMBA Social. L'objectif principal est de fournir une plateforme moderne permettant aux membres de la communaute universitaire de publier des contenus, suivre d'autres utilisateurs, echanger des messages, consulter des stories, recevoir des notifications et administrer la plateforme depuis un tableau de bord dedie.

L'architecture repose sur une separation claire entre le frontend Flutter, responsable de l'interface utilisateur et de l'experience mobile/web, et le backend Node.js / Express, charge de l'authentification, des regles metier, de la persistence des donnees et de la diffusion des evenements temps reel. MongoDB est utilise pour stocker les utilisateurs, publications, messages, stories, notifications, signalements, groupes, facultes et evenements.

Le systeme implemente plusieurs mecanismes importants : authentification par email et Google, verification d'email optionnelle, gestion des anciens comptes deja presents en base, publication de posts avec media, commentaires, likes, sauvegarde, signalement, messagerie avec pieces jointes, stories ephemeres, notifications en temps reel et dashboard administrateur pour la moderation.

La solution obtenue est modulaire, evolutive et adaptee a un contexte universitaire. Elle met en avant la reactivite de l'interface, la structuration du code, la gestion des erreurs et la securisation des acces.

### Mots cles

Flutter, Dart, Node.js, Express, MongoDB, Mongoose, Socket.IO, reseau social, universite, temps reel, dashboard admin, stories, messagerie.

---

## Liste des abreviations

- API : Application Programming Interface
- JWT : JSON Web Token
- UI : User Interface
- UX : User Experience
- MVC : Modele Vue Controleur
- REST : Representational State Transfer
- CRUD : Create Read Update Delete
- ODM : Object Document Mapper
- HTTP : HyperText Transfer Protocol
- CORS : Cross-Origin Resource Sharing
- TTL : Time To Live
- RSVP : Reponse a une invitation d'evenement
- PFE : Projet de Fin d'Etudes
- USMBA : Universite Sidi Mohamed Ben Abdellah

---

## Introduction generale

Les etablissements universitaires ont besoin d'espaces numeriques favorisant la communication, la collaboration et la circulation d'informations entre etudiants, enseignants et administration. Les reseaux sociaux generalistes existent deja, mais ils ne repondent pas toujours aux contraintes d'un contexte universitaire comme l'identite institutionnelle, l'organisation par faculte, la moderation interne et les interactions pedagogiques.

Dans cette logique, le projet USMBA Social a ete concu comme une plateforme sociale specialisee pour l'universite. L'application permet de centraliser les echanges autour d'un ecosysteme unique : publications, profils, recherche, stories, messages, notifications et administration.

Le projet ne se limite pas a la production d'une interface visuelle. Il couvre l'ensemble de la chaine logicielle : architecture client-serveur, gestion d'etat, API REST, persistance des donnees, securite, flux temps reel, gestion des fichiers et supervision administrative.

Ce rapport decrit l'ensemble du fonctionnement de l'application en s'appuyant sur le code reel du projet. Il presente le contexte, les besoins, les choix technologiques, l'architecture globale, les fonctionnalites metier et l'explication technique des principaux modules logiciels.

---

## Chapitre 1 : Cadre et contexte du projet

### 1.1 Contexte du projet

Dans un environnement universitaire, les utilisateurs ont besoin :

- de partager rapidement des informations et publications
- de suivre des personnes appartenant au meme environnement academique
- d'echanger des documents et messages prives
- d'etre informes en temps reel des interactions importantes
- de disposer d'un espace specifique a l'universite et a ses facultes

Les solutions existantes sont generalement ouvertes a tous les publics et ne proposent pas une structuration centree sur l'identite universitaire. D'ou l'idee de creer une application dediee a l'USMBA.

### 1.2 Problematique

Comment concevoir une application moderne et reactive capable de :

- authentifier les utilisateurs de maniere securisee
- gerer des profils universitaires avec relations followers/following
- publier des posts avec media
- permettre les commentaires, likes et signalements
- assurer une messagerie avec pieces jointes
- diffuser des stories ephemeres
- notifier les utilisateurs en temps reel
- offrir un espace d'administration et de moderation

### 1.3 Objectifs generaux

Les objectifs du projet sont les suivants :

- creer une application de reseau social universitaire complete
- fournir une experience multiplateforme avec Flutter
- mettre en place une API securisee et modulaire avec Express
- modeliser les donnees sociales dans MongoDB
- integrer une communication temps reel avec Socket.IO
- proposer une architecture maintenable et evolutive

### 1.4 Public cible

L'application vise trois grandes categories d'utilisateurs :

- les etudiants, qui peuvent publier, suivre, commenter, aimer, chercher et discuter
- les enseignants, qui peuvent publier des informations et interagir avec les etudiants
- les administrateurs, qui peuvent moderer les utilisateurs, consulter les reports et surveiller les publications

### 1.5 Perimetre du projet

Le projet couvre :

- l'inscription et la connexion
- la gestion de profil
- la navigation principale de l'application
- le fil d'actualites
- la creation de posts
- les interactions sociales
- la messagerie
- les stories
- les notifications
- l'administration

Le projet couvre egalement plusieurs modules complementaires deja presents dans le backend :

- les facultes
- les groupes
- les evenements
- la recherche globale

### 1.6 Contraintes de realisation

Parmi les contraintes prises en compte :

- disponibilite sur plusieurs plateformes
- gestion correcte des appels reseau et des erreurs
- besoin d'une interface moderne et reactive
- besoin d'un systeme temps reel pour les notifications et messages
- prise en charge des fichiers envoyes par les utilisateurs
- structuration claire du code pour faciliter la maintenance

### 1.7 Resultat attendu

Le resultat attendu est une application coherente, utilisable et extensible, permettant de connecter la communaute universitaire dans un espace numerique unique et securise.

---

## Chapitre 2 : Analyse des besoins et cahier des charges

### 2.1 Analyse fonctionnelle

Le systeme doit proposer des fonctionnalites correspondant au cycle de vie complet de l'utilisateur.

#### 2.1.1 Besoins lies a l'authentification

- inscription avec nom, email universitaire, mot de passe, faculte et role
- connexion classique par email ou nom d'utilisateur
- connexion avec Google
- verification d'email configurable
- reinitialisation du mot de passe
- gestion des anciens comptes deja presents en base

#### 2.1.2 Besoins lies au profil utilisateur

- consultation du profil courant
- consultation des profils d'autres utilisateurs
- modification du nom, bio, avatar, faculte, niveau et centres d'interet
- suivi et desabonnement
- affichage des followers et des abonnements
- synchronisation temps reel des changements de profil

#### 2.1.3 Besoins lies aux publications

- creation de posts textuels ou avec media
- chargement du feed des utilisateurs suivis
- filtrage par faculte
- affichage des likes, commentaires et medias
- suppression de posts
- sauvegarde d'un post
- signalement d'un contenu problematique

#### 2.1.4 Besoins lies aux interactions sociales

- aimer un post
- commenter un post
- notifier le proprietaire du contenu
- partager un post dans une conversation

#### 2.1.5 Besoins lies a la messagerie

- voir la liste des conversations
- ouvrir une conversation detaillee
- envoyer un message texte
- envoyer des pieces jointes
- afficher les pieces jointes dans la discussion
- indiquer quand un utilisateur est en train d'ecrire
- creer une nouvelle conversation a partir d'une liste de contacts

#### 2.1.6 Besoins lies aux stories

- publier une story
- consulter les stories du graphe social
- marquer une story comme vue
- supprimer une story
- expiration automatique apres 24 heures

#### 2.1.7 Besoins lies aux notifications

- recevoir les notifications de suivi
- recevoir les notifications de like
- recevoir les notifications de commentaire
- recevoir les notifications de message
- recevoir les notifications de nouveau post d'un utilisateur suivi
- afficher le nombre de notifications non lues
- marquer les notifications comme lues

#### 2.1.8 Besoins lies a l'administration

- acceder a un dashboard reserve aux administrateurs
- consulter les statistiques globales
- voir les utilisateurs
- bloquer ou debloquer un utilisateur
- consulter les reports
- voir les posts recents
- supprimer un post depuis l'espace admin

### 2.2 Besoins non fonctionnels

- ergonomie et simplicite d'utilisation
- rapidite des chargements
- fiabilite du backend
- securite des acces
- code maintenable
- compatibilite web et mobile
- evolutivite de l'architecture

### 2.3 Acteurs du systeme

Les acteurs principaux sont :

- visiteur non authentifie
- utilisateur authentifie
- administrateur

### 2.4 Cas d'utilisation principaux

Les scenarios majeurs du systeme sont :

1. Un utilisateur s'inscrit avec son email universitaire.
2. Il se connecte et accede au feed.
3. Il consulte des profils et suit des utilisateurs.
4. Il publie un post ou une story.
5. Il aime, commente ou signale un post.
6. Il ouvre une conversation et envoie un message avec ou sans piece jointe.
7. Il recoit des notifications en temps reel.
8. L'administrateur accede au dashboard pour moderer la plateforme.

### 2.5 Cahier des charges fonctionnel synthese

| Module | Fonction attendue | Etat dans le projet |
| --- | --- | --- |
| Authentification | Inscription, connexion, Google, reset password | Implante |
| Profil | Consultation, modification, follow/unfollow | Implante |
| Feed | Posts suivis + filtre faculte | Implante |
| Interactions | Like, commentaire, sauvegarde, report | Implante |
| Messagerie | Conversations, detail, pieces jointes | Implante |
| Stories | Publication, visualisation, expiration | Implante |
| Notifications | Lecture et temps reel | Implante |
| Admin | Statistiques, moderation utilisateurs/posts/reports | Implante |
| Groupes | CRUD simple + rejoindre/quitter | Implante cote backend |
| Evenements | Creation, listing, RSVP | Implante cote backend |
| Recherche | Utilisateurs, posts, groupes, facultes | Implante |

### 2.6 Conclusion du chapitre

L'analyse des besoins montre que le projet ne se limite pas a un simple fil de publications. Il s'agit d'une plateforme sociale complete avec authentification, contenu social, temps reel, gestion des fichiers et moderation. Cette analyse guide directement les choix technologiques et architecturaux presentes dans les chapitres suivants.

---

## Chapitre 3 : Technologies et outils utilises

### 3.1 Introduction

La reussite de ce projet repose sur un choix de technologies coherentes avec les objectifs de performance, d'evolutivite et de compatibilite multi-plateforme. Chaque composant technologique a ete selectionne en fonction de son role dans l'application.

### 3.2 Technologies implementees cote frontend

#### 3.2.1 Flutter

Flutter constitue la base du frontend. Ce framework permet de produire une seule base de code pour le web, Android et iOS. Dans le projet, Flutter sert a :

- construire toutes les interfaces
- gerer la navigation entre les ecrans
- animer l'experience utilisateur
- afficher les contenus reseau et les pieces jointes

Le point fort de Flutter dans ce projet est la mutualisation du code UI entre plusieurs plateformes.

#### 3.2.2 Dart

Dart est le langage de programmation du frontend. Il est utilise pour :

- developper les widgets
- implementer la logique de presentation
- gerer les appels API
- manipuler les flux temps reel
- organiser l'etat de l'application

#### 3.2.3 Provider

Provider est la solution de gestion d'etat principale du projet. Elle est utilisee dans `frontend/lib/main.dart` pour injecter les providers globaux :

- `AuthProvider`
- `FeedProvider`
- `ThemeProvider`
- `UserProvider`
- `NotificationProvider`
- `FacultyProvider`

Ce choix permet d'eviter une logique dispersee et facilite la synchronisation entre l'interface et les donnees chargees depuis l'API.

#### 3.2.4 Services Flutter

Le frontend contient plusieurs services specialises :

- `api_service.dart` pour les requetes HTTP et multipart
- `auth_service.dart` pour l'authentification
- `post_service.dart` pour les posts
- `chat_service.dart` pour la messagerie
- `story_service.dart` pour les stories
- `notification_service.dart` pour les notifications
- `user_service.dart` pour les utilisateurs
- `realtime_service.dart` pour Socket.IO

Cette separation ameliore la lisibilite du code et isole les responsabilites.

#### 3.2.5 Bibliotheques Flutter importantes

Le projet utilise plusieurs dependances utiles :

- `http` pour les appels REST
- `socket_io_client` pour la communication temps reel
- `shared_preferences` pour conserver le token et l'identifiant utilisateur
- `image_picker` pour selectionner des images
- `file_picker` pour joindre des documents, audios, images et videos
- `cached_network_image` pour l'affichage optimise d'images
- `video_player` pour les medias video
- `google_sign_in` pour l'authentification Google
- `photo_view`, `lottie`, `shimmer` et `flutter_staggered_animations` pour l'UX

### 3.3 Technologies implementees cote backend

#### 3.3.1 Node.js

Node.js constitue le moteur d'execution du backend. Il permet de construire une API performante et adaptee a une application orientee evenements, en particulier avec Socket.IO.

#### 3.3.2 Express

Express fournit la structure de l'API REST. Dans `backend/app.js`, il est utilise pour :

- declarer les middlewares
- monter les routes
- appliquer la securite HTTP
- exposer les fichiers uploades
- centraliser la gestion des erreurs

#### 3.3.3 MongoDB

MongoDB est la base de donnees documentaire du projet. Elle stocke :

- les utilisateurs
- les facultes
- les posts
- les commentaires
- les messages
- les stories
- les notifications
- les reports
- les groupes
- les evenements

Ce choix est pertinent pour une application sociale car les structures de donnees sont riches, evolutives et orientees documents.

#### 3.3.4 Mongoose

Mongoose est utilise comme ODM. Il fournit :

- les schemas
- les validations
- les relations via `ref`
- les hooks de sauvegarde
- les requetes structurees

Dans `backend/models/User.js`, par exemple, Mongoose permet de hasher le mot de passe avant sauvegarde et de cacher certains champs sensibles lors de la serialisation JSON.

#### 3.3.5 Socket.IO

Socket.IO est le coeur du temps reel. Il est initialise dans `backend/socket.js` et connecte au frontend via `frontend/lib/services/realtime_service.dart`.

Il sert a diffuser :

- les nouveaux messages
- les notifications
- les events de typing
- les creations et suppressions de stories
- les mises a jour de profil

#### 3.3.6 Multer

Multer gere les uploads de fichiers. Le helper `backend/utils/uploads.js` standardise :

- le repertoire d'uploads
- le renommage securise des fichiers
- les limites de taille
- la serialisation des pieces jointes
- la detection du type MIME quand le navigateur fournit un type generique

#### 3.3.7 JWT

Les JSON Web Tokens sont utilises pour securiser l'acces aux routes privees. Le token est genere dans `backend/utils/jwt.js`, verifie dans `backend/middleware/auth.js` et stocke cote frontend avec `SharedPreferences`.

#### 3.3.8 Middlewares de securite

Le backend utilise aussi :

- `helmet` pour proteger les en-tetes HTTP
- `cors` pour controler les origines autorisees
- `compression` pour reduire la taille des reponses
- `express-rate-limit` pour limiter les abus

### 3.4 Outils de developpement

Les outils principaux du projet sont :

- Visual Studio Code pour le developpement
- Flutter SDK pour la compilation frontend
- Node.js et npm pour le backend
- MongoDB Atlas ou MongoDB local pour la base de donnees
- Chrome pour les tests web
- PowerShell / terminal integre pour l'execution
- Supertest et `node:test` pour les tests backend

### 3.5 Conclusion du chapitre

Les technologies retenues couvrent l'ensemble des besoins du projet : interface moderne, API modulaire, base de donnees flexible, uploads de fichiers, temps reel et securite. Le chapitre suivant detaille comment ces briques sont assemblees dans l'architecture globale de l'application.

---

## Chapitre 4 : Architecture et conception de l'application

### 4.1 Vision globale de l'architecture

L'application suit une architecture client-serveur en couches.

```text
Utilisateur
   |
   v
Frontend Flutter (UI, navigation, providers, services)
   |
   v
API REST + Socket.IO (Node.js / Express)
   |
   v
Couche metier et serialisation
   |
   v
MongoDB / Mongoose
   |
   v
Stockage des fichiers dans /uploads
```

Le frontend dialogue avec le backend de deux manieres :

- via HTTP pour les operations CRUD classiques
- via Socket.IO pour la synchronisation temps reel

### 4.2 Architecture du frontend

Le frontend est organise autour de quatre blocs principaux :

1. Le point d'entree et l'initialisation
2. Les providers de gestion d'etat
3. Les services d'acces aux donnees
4. Les ecrans et widgets de presentation

#### 4.2.1 Initialisation

`frontend/lib/main.dart` :

- force l'orientation verticale
- prepare le theme
- injecte les providers
- definit les routes principales
- execute `AppInitializer`

`AppInitializer` relit le token conserve localement, appelle `validateToken()` et choisit automatiquement entre l'ecran d'authentification et l'ecran principal.

#### 4.2.2 Navigation

La navigation principale est geree par `MainNavigationScreen` avec un `PageView` et une barre de navigation personnalisee. Les onglets centraux sont :

- feed
- recherche
- creation de post
- messagerie
- profil

#### 4.2.3 Gestion d'etat

Les providers ont chacun une responsabilite claire :

- `AuthProvider` : session, login, register, Google Sign-In, token, utilisateur courant
- `FeedProvider` : chargement pagine du fil
- `UserProvider` : profil utilisateur courant
- `NotificationProvider` : liste et compteur des notifications
- `FacultyProvider` : chargement des facultes
- `ThemeProvider` : theming de l'application

#### 4.2.4 Services

Les services font le lien entre l'UI et l'API :

- construction des URL
- ajout du token JWT
- envoi des formulaires JSON ou multipart
- decodage des reponses
- encapsulation des appels par domaine fonctionnel

### 4.3 Architecture du backend

Le backend suit une architecture modulaire :

- `server.js` pour le demarrage HTTP, Socket.IO et MongoDB
- `app.js` pour la composition Express
- `routes/` pour les points d'entree HTTP
- `models/` pour les schemas Mongoose
- `middleware/` pour l'authentification et les erreurs
- `utils/` pour les helpers techniques

#### 4.3.1 Flux de demarrage

Au lancement :

1. `server.js` charge les variables d'environnement.
2. `createApp()` construit l'application Express.
3. Le serveur HTTP est cree.
4. Socket.IO est initialise.
5. L'instance `io` est attachee a l'application via `app.set('io', io)`.
6. MongoDB est connecte via Mongoose.
7. Une regularisation des anciens comptes peut etre appliquee si la verification email est desactivee.

#### 4.3.2 Composition Express

Dans `backend/app.js`, l'application active :

- `helmet`
- `compression`
- `cors`
- les rate limiters
- `express.json`
- `express.urlencoded`
- le serveur statique `/uploads`
- la route de sante `/api/health`
- l'ensemble des routes metier

#### 4.3.3 Routes principales

Les routes montees sont :

- `/api/auth`
- `/api/users`
- `/api/posts`
- `/api/groups`
- `/api/events`
- `/api/messages`
- `/api/admin`
- `/api/search`
- `/api/faculties`
- `/api/notifications`
- `/api/stories`

### 4.4 Conception des donnees

Le modele de donnees est centre sur l'utilisateur et les interactions sociales.

#### 4.4.1 Entites majeures

- `User`
- `Post`
- `Comment`
- `Message`
- `Story`
- `Notification`
- `Report`
- `Faculty`
- `Group`
- `Event`
- `Save`

#### 4.4.2 Relations principales

```text
User 1 --- * Post
User * --- * User (followers / following)
Post 1 --- * Comment
User 1 --- * Message (sender)
User 1 --- * Message (receiver)
User 1 --- * Story
User 1 --- * Notification
Post 1 --- * Report
Faculty 1 --- * User
Faculty 1 --- * Post
Group 1 --- * Post
```

#### 4.4.3 Exemple de structure du modele User

Le modele `User` contient notamment :

- l'identite : nom, email
- la securite : password, emailVerified, verificationCode
- le role : student, teacher, admin
- le profil : avatar, bio, faculty, level, interests
- le graphe social : followers, following
- la moderation : blocked

#### 4.4.4 Exemple de structure du modele Message

Le modele `Message` contient :

- `sender`
- `receiver`
- `content`
- `attachments`
- `read`
- `createdAt`
- `updatedAt`

Chaque piece jointe contient :

- `url`
- `fileName`
- `mimeType`
- `size`
- `kind`

#### 4.4.5 Exemple de structure du modele Story

Le modele `Story` contient :

- l'utilisateur proprietaire
- l'URL du media
- le type du media
- la legende
- la liste des viewers
- la date d'expiration

L'index TTL sur `expiresAt` permet une suppression automatique des stories expirees.

### 4.5 Architecture temps reel

L'architecture Socket.IO repose sur des rooms associees a l'identifiant utilisateur.

#### 4.5.1 Cote backend

Dans `backend/socket.js` :

- a la connexion, le socket rejoint la room du `userId`
- l'event `typing` diffuse `userTyping`
- l'event `sendMessage` cree et renvoie un message
- l'event `notification` diffuse une notification a l'utilisateur cible

#### 4.5.2 Cote frontend

Dans `frontend/lib/services/realtime_service.dart` :

- la connexion est ouverte avec `auth.userId`
- des `StreamController.broadcast()` sont exposes
- l'application ecoute `newMessage`, `messageSent`, `notification`, `storyCreated`, `storyDeleted`, `profileUpdated`, `userTyping`

### 4.6 Conception des reponses API

Le projet utilise des serialiseurs centralises dans `backend/utils/serializers.js`. Cette couche transforme les documents MongoDB en objets JSON propres pour le frontend.

Avantages :

- structure de reponse stable
- masquage des champs sensibles
- conversion des ObjectId
- calcul d'attributs derives comme `likesCount`, `commentsCount`, `hasAttachments`, `hasViewed`, `followersCount`

### 4.7 Gestion des erreurs

Le middleware `backend/middleware/errorHandler.js` uniformise les erreurs :

- code HTTP
- code applicatif
- message humain
- details optionnels

Cette approche facilite le debogage et permet au frontend d'afficher des retours plus clairs.

### 4.8 Conclusion du chapitre

L'architecture de l'application est modulaire et bien separee. Le frontend, le backend, le temps reel, la base documentaire et le stockage des fichiers collaborent via des interfaces claires. Cette structure rend l'application plus facile a maintenir, a tester et a faire evoluer.

---

## Chapitre 5 : Presentation fonctionnelle de l'application

### 5.1 Introduction

Ce chapitre presente le comportement observable de l'application du point de vue utilisateur. Il correspond a la traduction concrete des besoins en ecrans, flux et interactions.

### 5.2 Ecran de demarrage et initialisation

L'application demarre par un splash screen anime. Ensuite, `AppInitializer` verifie si un token JWT est deja stocke localement.

Deux scenarios existent :

- si le token est valide, l'utilisateur est redirige vers l'application principale
- sinon, il est redirige vers l'ecran d'authentification

Ce mecanisme evite de demander a l'utilisateur de se reconnecter a chaque lancement.

### 5.3 Authentification

#### 5.3.1 Inscription

L'utilisateur remplit :

- son nom
- son email universitaire
- son mot de passe
- sa faculte
- son role principal

Le frontend impose deja un controle sur le domaine `@usmba.ac.ma`. Le backend verifie ensuite les champs obligatoires, detecte les doublons et cree le compte.

Si la verification email est active, un code de verification est associe au compte. Si elle est desactivee, le compte est marque automatiquement comme verifie.

#### 5.3.2 Connexion classique

La connexion peut se faire par email ou nom d'utilisateur. En cas de succes :

- le backend retourne un token JWT
- le frontend enregistre le token
- l'utilisateur est redirige vers l'application principale

#### 5.3.3 Connexion Google

Le projet integre aussi Google Sign-In. Seuls les emails universitaires sont acceptes. Cette fonctionnalite simplifie l'acces tout en conservant une logique reservee a la communaute USMBA.

#### 5.3.4 Verification d'email et anciens comptes

Un point important du projet est la gestion des comptes deja existants. Lorsque `REQUIRE_EMAIL_VERIFICATION=false`, les anciens utilisateurs non verifies sont regularises automatiquement au demarrage du backend via `backfillEmailVerificationIfDisabled()`.

Cette logique evite de bloquer les comptes historiques.

#### 5.3.5 Reinitialisation du mot de passe

Le backend supporte :

- la generation d'un token de reinitialisation
- la verification de sa validite
- l'enregistrement du nouveau mot de passe

### 5.4 Navigation principale

L'utilisateur authentifie accede a cinq zones centrales :

- le feed
- la recherche
- la creation de post
- les messages
- le profil

Cette structure rend la navigation directe et stable sur mobile comme sur web.

### 5.5 Fil d'actualites

Le feed est l'espace principal de consommation de contenu.

#### 5.5.1 Chargement du feed

Le `FeedProvider` appelle l'endpoint `/api/posts` avec pagination. Le backend retourne uniquement :

- les posts de l'utilisateur courant
- les posts des comptes suivis

Le systeme gere :

- la pagination
- le rafraichissement
- le chargement progressif
- le filtre par faculte

#### 5.5.2 Affichage des posts

Chaque post peut contenir :

- du texte
- un media principal
- plusieurs medias dans le schema
- des hashtags
- des mentions
- des compteurs de likes et commentaires

Le widget `PostCard` affiche le contenu et expose les actions principales.

#### 5.5.3 Interactions sur un post

Depuis le feed, l'utilisateur peut :

- aimer un post
- ouvrir les commentaires
- partager un post par message

Le like et le commentaire declenchent des notifications cote destinataire.

### 5.6 Creation de publication

L'ecran de creation de post permet d'envoyer :

- un texte
- une image selectionnee
- eventuellement un rattachement a une faculte ou un groupe

Le frontend utilise une requete multipart. Le backend stocke le fichier dans `/uploads`, cree le document `Post` et diffuse une notification de type `post` aux followers de l'auteur.

### 5.7 Profils utilisateurs

#### 5.7.1 Profil personnel

Le profil personnel affiche :

- avatar
- nom
- faculte
- bio
- nombre de posts
- nombre de followers
- nombre d'abonnements

L'utilisateur peut :

- modifier son profil
- ouvrir les parametres
- acceder au dashboard admin si son role est `admin`
- se deconnecter

#### 5.7.2 Profil externe

Quand un utilisateur consulte le profil d'une autre personne, il peut :

- voir ses informations publiques
- voir ses posts
- la suivre ou ne plus la suivre
- lui envoyer un message

Les followers et followings sont aussi consultables depuis des onglets dedies.

#### 5.7.3 Mise a jour en temps reel

Lorsqu'un profil est modifie, le backend emet `profileUpdated`. Le frontend ecoute cet event et met a jour automatiquement le profil concerne. Cela ameliore la coherence des donnees affichees.

### 5.8 Systeme de suivi social

Le suivi d'utilisateur repose sur deux tableaux dans le document `User` :

- `followers`
- `following`

Lorsqu'un utilisateur suit un autre utilisateur :

- son identifiant est ajoute dans `following`
- son identifiant est ajoute dans `followers` du compte cible
- une notification `follow` est creee

Cette relation sert aussi a construire :

- le feed
- la liste des contacts de messagerie
- le public cible des stories
- les notifications de nouveaux posts

### 5.9 Messagerie privee

#### 5.9.1 Liste des conversations

L'ecran `ChatScreen` affiche les conversations existantes. Le backend regroupe les messages par interlocuteur et renvoie pour chacun :

- le resume du partenaire
- le dernier message

#### 5.9.2 Creation d'une nouvelle conversation

Le bouton flottant de la messagerie ouvre `NewMessageScreen`. L'utilisateur choisit un ami dans la liste des contacts. Cette liste est construite a partir du graphe social :

- followers
- following

Cela correspond a une logique sociale realiste pour une application universitaire.

#### 5.9.3 Detail d'une conversation

Dans `ChatDetailScreen`, l'utilisateur peut :

- lire l'historique
- envoyer un texte
- joindre un ou plusieurs fichiers
- voir si l'autre utilisateur est en train d'ecrire

#### 5.9.4 Pieces jointes

La piece jointe est desormais prise en charge pour :

- documents
- images
- audios
- videos

Le frontend :

- selectionne les fichiers avec `file_picker`
- verifie leur taille
- envoie les donnees en multipart

Le backend :

- recoit jusqu'a 6 fichiers
- les stocke sur disque
- reconstruit les metadonnees
- determine un `kind` coherent
- rattache les pieces jointes au message

Si un message contient une image, celle-ci peut s'afficher directement dans la bulle de discussion.

#### 5.9.5 Temps reel dans la messagerie

La messagerie utilise Socket.IO pour :

- recevoir le message sans recharger manuellement
- actualiser la liste des conversations
- indiquer la frappe en cours

Quand un message est envoye au format HTTP, le backend emet aussi `newMessage` vers la room du destinataire.

### 5.10 Stories

#### 5.10.1 Publication d'une story

Depuis le feed, l'utilisateur peut publier une story via le composant de stories en haut de l'ecran. La story contient :

- une image ou un media
- une legende optionnelle

#### 5.10.2 Consultation des stories

Les stories visibles sont celles :

- des personnes suivies
- de l'utilisateur lui-meme

L'ecran `StoryViewerScreen` permet de visualiser le contenu. Une story non vue est marquee comme vue a l'ouverture.

#### 5.10.3 Duree de vie

Chaque story expire automatiquement apres 24 heures grace a l'index TTL de MongoDB.

#### 5.10.4 Temps reel des stories

Lorsqu'une story est creee ou supprimee, le frontend la recoit via `storyCreated` ou `storyDeleted` et met a jour la liste sans rechargement complet.

### 5.11 Notifications

L'ecran de notifications regroupe les events sociaux importants. Les types actuellement geres par le backend sont :

- `follow`
- `like`
- `comment`
- `message`
- `post`

Le frontend affiche :

- la liste des notifications
- le nombre de non lues
- un badge sur l'icone de cloche

L'utilisateur peut marquer une notification comme lue ou tout marquer comme lu.

### 5.12 Recherche

Le module de recherche interroge simultanement :

- les utilisateurs
- les posts
- les groupes
- les facultes

Cette fonctionnalite permet de retrouver rapidement une personne, un contenu ou une structure de l'ecosysteme universitaire.

### 5.13 Facultes, groupes et evenements

Le backend contient aussi des modules complementaires :

#### 5.13.1 Facultes

Les facultes sont exposees via `/api/faculties` avec :

- la liste des facultes
- les membres par faculte
- les posts par faculte
- la gestion CRUD admin

#### 5.13.2 Groupes

Le module groupes permet :

- la creation d'un groupe
- la consultation
- l'adhesion
- la sortie
- la consultation des posts d'un groupe

#### 5.13.3 Evenements

Le module evenements permet :

- la creation d'un evenement
- le filtrage par categorie ou faculte
- l'affichage du detail
- le RSVP des participants

### 5.14 Dashboard administrateur

Le dashboard admin est accessible depuis le profil si le role est `admin`.

Il propose :

- un resume statistique
- la liste des utilisateurs
- la liste des reports
- la liste des posts recents

L'administrateur peut :

- bloquer ou debloquer un utilisateur
- resoudre un report
- supprimer un post

L'interface a ete modernisee pour mieux visualiser les publications, les medias, les comptes moderes et les reports en attente.

### 5.15 Conclusion du chapitre

Fonctionnellement, USMBA Social couvre les besoins essentiels d'un reseau social universitaire moderne. L'application combine communication, partage, moderation, temps reel et experience multi-plateforme dans une meme solution.

---

## Chapitre 6 : Explication technique des modules et du code

### 6.1 Introduction

Ce chapitre explique le fonctionnement interne du code. L'objectif n'est pas seulement de lister les fichiers, mais de montrer comment chaque composant participe au comportement global de l'application.

### 6.2 Point d'entree backend

#### 6.2.1 `backend/server.js`

Ce fichier joue le role d'orchestrateur principal. Il :

- charge les variables d'environnement avec `dotenv`
- cree l'application Express grace a `createApp()`
- cree le serveur HTTP
- initialise Socket.IO avec `initializeSocket(server)`
- attache `io` a l'application
- connecte MongoDB
- applique la regularisation des anciens comptes non verifies
- lance le serveur sur le port configure

Cette centralisation permet de disposer d'un seul point d'entree pour la couche serveur.

#### 6.2.2 Regularisation des comptes existants

Le helper `backend/utils/userMaintenance.js` contient la fonction `backfillEmailVerificationIfDisabled()`. Son role est simple :

- si la verification email est active, ne rien faire
- sinon, marquer automatiquement comme verifies tous les comptes non verifies
- supprimer leur ancien code de verification

Cette logique corrige un probleme frequent dans les applications evolutives : les changements de regles ne doivent pas casser les comptes deja existants.

### 6.3 Construction de l'application Express

#### 6.3.1 `backend/app.js`

`createApp()` construit l'application web en couches.

Ordre logique :

1. securite HTTP avec `helmet`
2. compression des reponses
3. regles CORS
4. limitation du trafic
5. parsing JSON et formulaire
6. exposition du dossier `/uploads`
7. route de sante
8. montage des routes metier
9. route not found
10. middleware global d'erreurs

Ce fichier est important car il garantit que toutes les routes partagent les memes conventions techniques.

#### 6.3.2 `backend/config/cors.js`

Ce module centralise les origines autorisees. Il accepte :

- les URL `localhost`
- les URL declarees dans les variables d'environnement

Si l'origine n'est pas autorisee, une erreur `CORS_ORIGIN_DENIED` est retournee. Ce comportement a aussi ete teste automatiquement.

### 6.4 Middleware d'authentification et gestion des erreurs

#### 6.4.1 `backend/middleware/auth.js`

Ce middleware :

- lit le header `Authorization`
- accepte `Bearer <token>` ou `x-auth-token`
- verifie la signature JWT
- injecte `req.user`

Sans token valide, l'acces est refuse avec `AUTH_REQUIRED` ou `INVALID_TOKEN`.

#### 6.4.2 `backend/middleware/errorHandler.js`

Le gestionnaire d'erreurs transforme les exceptions en reponse JSON uniforme. Il traite notamment :

- les erreurs de validation Mongoose
- les erreurs de duplication MongoDB
- les erreurs JWT
- les erreurs applicatives personnalisees

Cette standardisation simplifie les traitements cote frontend.

#### 6.4.3 `backend/utils/request.js`

Ce helper renvoie toujours un objet pour `req.body`. Son importance est pratique : il evite les erreurs de type destructuring quand `req.body` est `undefined`. Cela stabilise les routes et evite les crashs de type :

- impossibilite de destructurer `name` depuis `req.body`

### 6.5 Serialisation des donnees

#### 6.5.1 `backend/utils/serializers.js`

Ce fichier est l'un des plus importants du backend. Il transforme les documents internes en objets lisibles par le frontend.

Exemples :

- `serializeUserSummary()` nettoie et normalise un utilisateur
- `serializeUserProfile()` ajoute les compteurs et le statut `isFollowing`
- `serializePost()` construit un post complet avec compteurs et commentaires
- `serializeMessage()` ajoute `hasAttachments`
- `serializeStory()` calcule `hasViewed`
- `serializeNotification()` uniformise les notifications

Sans cette couche, le frontend devrait gerer lui-meme beaucoup de logique de transformation.

### 6.6 Gestion des fichiers et uploads

#### 6.6.1 `backend/utils/uploads.js`

Ce module encapsule tout le comportement fichier :

- creation automatique du dossier `uploads`
- sanitation des noms de fichiers
- configuration Multer
- limitation de taille
- detection du type MIME par extension
- deduction du type fonctionnel `image`, `audio`, `video`, `document`

Cette partie est essentielle pour la messagerie, les stories, les avatars et les posts avec image.

#### 6.6.2 Pourquoi la deduction par extension est utile

Dans certains contextes, le navigateur ou la plateforme envoie `application/octet-stream`. Sans correction, le backend ne saurait pas si le fichier est une image ou un document. La fonction `inferMimeTypeFromFileName()` corrige ce cas a partir de l'extension du nom de fichier.

### 6.7 Module d'authentification

#### 6.7.1 `backend/routes/auth.js`

Ce module implemente :

- `POST /register`
- `POST /verify-email`
- `POST /login`
- `POST /google`
- `POST /request-password-reset`
- `POST /reset-password`

#### 6.7.2 Logique du register

La route d'inscription :

- recupere le body avec `getRequestBody()`
- verifie les champs obligatoires
- verifie l'unicite de l'email
- convertit la faculte en ObjectId valide
- genere un code de verification
- cree l'utilisateur
- peuple la faculte
- genere le token JWT
- renvoie l'utilisateur serialise

#### 6.7.3 Logique du login

La route de connexion :

- accepte `email` ou `username`
- charge l'utilisateur avec le mot de passe
- regularise le compte si la verification email est desactivee
- bloque la connexion si l'email n'est pas verifie alors qu'il devrait l'etre
- refuse l'acces si le compte est bloque
- compare le mot de passe
- renvoie un token et un utilisateur propre

#### 6.7.4 Role du modele `User`

Le modele `backend/models/User.js` :

- hash le mot de passe avant sauvegarde
- fournit `comparePassword()`
- masque automatiquement les champs sensibles dans `toJSON`

Ce schema contient aussi le role et tout le graphe social.

### 6.8 Module utilisateurs

#### 6.8.1 `backend/routes/users.js`

Ce module couvre :

- le profil courant
- les contacts de messagerie
- la mise a jour de profil
- le changement de mot de passe
- l'acces a un profil externe
- le follow / unfollow
- le blocage admin

#### 6.8.2 Chargement d'un profil

La fonction `loadUserProfile()` :

- charge l'utilisateur avec ses relations
- compte le nombre de posts
- calcule le statut `isFollowing`
- retourne un objet pret pour le frontend

#### 6.8.3 Contacts de messagerie

`loadMessageContacts()` construit une liste unique a partir :

- des followers
- des following

Le resultat est trie alphabetiquement. Ce choix evite d'avoir des contacts dupliques.

#### 6.8.4 Emission temps reel du profil

`emitProfileUpdate()` envoie un event Socket.IO `profileUpdated` a la room de l'utilisateur concerne. Cela permet au frontend de resynchroniser les profils ouverts.

#### 6.8.5 Follow / unfollow

Les routes modifient les deux comptes en parallele, puis :

- generent une notification `follow`
- recalculent les profils
- diffusent les mises a jour de profil

### 6.9 Module posts

#### 6.9.1 `backend/routes/posts.js`

Ce module est central dans l'application sociale. Il gere :

- la creation de post
- le feed pagine
- les posts d'un utilisateur
- le like
- le commentaire
- la sauvegarde
- le report
- la suppression

#### 6.9.2 Creation de post

Flux de creation :

1. lecture du body
2. recuperation d'un eventuel fichier `image`
3. normalisation des medias
4. validation : texte ou media obligatoire
5. creation du document `Post`
6. rechargement avec populate
7. serialisation
8. creation de notifications `post` pour les followers

#### 6.9.3 Feed

Le feed renvoie :

- les posts des comptes suivis
- les posts de l'utilisateur courant

En cas de filtre par faculte, la requete est adaptee. La reponse inclut :

- la liste des posts
- les metadonnees de pagination

#### 6.9.4 Like

La route `/posts/:id/like` fonctionne comme un toggle :

- si l'utilisateur n'a pas aime, son id est ajoute
- sinon, son id est retire

Une notification `like` est creee uniquement lorsqu'on aime le post d'un autre utilisateur.

#### 6.9.5 Commentaire

La route `/posts/:id/comment` :

- verifie l'existence du post
- verifie le contenu
- cree un `Comment`
- rattache ce commentaire au post
- retourne le commentaire peuple
- notifie le proprietaire du post

#### 6.9.6 Sauvegarde et report

La sauvegarde est geree par le modele `Save`. Le signalement est gere par le modele `Report`. Cela permet de distinguer le stockage personnel des actions de moderation.

### 6.10 Module messagerie

#### 6.10.1 `backend/routes/messages.js`

Ce fichier expose :

- `GET /conversations`
- `POST /`
- `GET /:userId`

#### 6.10.2 Recuperation des conversations

Le backend charge tous les messages lies a l'utilisateur courant, puis construit une map par interlocuteur. Le premier message rencontre pour chaque interlocuteur devient le dernier message de la conversation grace au tri descendant.

#### 6.10.3 Envoi d'un message

Lorsqu'un message est envoye :

- le destinataire est verifie
- le texte est nettoye
- les pieces jointes sont serialisees
- le document `Message` est cree
- le message peuple est serialise
- le destinataire recoit `newMessage`
- une notification `message` peut etre creee

#### 6.10.4 Chargement d'une conversation

Le endpoint `GET /api/messages/:userId` :

- verifie que l'utilisateur cible existe
- retourne l'historique trie du plus ancien au plus recent
- marque les messages recus comme lus

### 6.11 Module stories

#### 6.11.1 `backend/routes/stories.js`

Le module stories implemente :

- `GET /feed`
- `POST /`
- `POST /:id/view`
- `DELETE /:id`

#### 6.11.2 Logique de feed des stories

Le backend recupere les stories :

- des personnes suivies
- de l'utilisateur lui-meme
- non expirees

Cela correspond au comportement attendu d'une story sociale ephemere.

#### 6.11.3 Publication d'une story

Le backend :

- serialise le media charge
- construit le `mediaUrl`
- cree la story
- la recharge avec populate
- l'envoie en temps reel a l'auteur et a ses followers

#### 6.11.4 Visualisation

Quand une story est vue, l'identifiant du viewer est ajoute au tableau `viewers` s'il n'est pas deja present. Le serialiseur peut alors calculer `hasViewed`.

### 6.12 Module notifications

#### 6.12.1 `backend/routes/notifications.js`

Ce module gere :

- le chargement pagine
- la lecture unitaire
- la lecture globale
- la suppression

#### 6.12.2 `backend/utils/notifications.js`

Le helper `createAndEmitNotification()` :

- cree un document `Notification`
- le diffuse immediatement via Socket.IO

Cette fonction est reutilisee dans plusieurs routes et evite la duplication du code de notification.

### 6.13 Module administration

#### 6.13.1 `backend/routes/admin.js`

Ce module est protege par `ensureAdmin(req)`. Il fournit :

- les statistiques du dashboard
- la liste des utilisateurs
- la liste des posts
- la liste des reports
- le blocage utilisateur
- la resolution de report
- la suppression d'un post
- la suppression d'un utilisateur

#### 6.13.2 Aggregation des reports sur les posts

Lors du chargement des posts admin, une aggregation MongoDB calcule le nombre de reports en attente par post. Cela enrichit l'interface de moderation avec `pendingReportsCount` et `isReported`.

### 6.14 Point d'entree frontend

#### 6.14.1 `frontend/lib/main.dart`

Le frontend :

- initialise les providers
- configure le theme
- prepare les routes
- choisit l'ecran de depart selon la session

Cette approche rend la structure du frontend lisible des le point d'entree.

#### 6.14.2 `AppConfig`

Le fichier `frontend/lib/utils/app_config.dart` centralise :

- l'URL API
- l'URL websocket
- le client ID Google
- la resolution d'URL absolues pour les medias
- les constantes de timeout, pagination, cache, validation et animation

Le fait d'avoir un fichier de configuration unique facilite le deploiement sur web, emulateur Android, iOS ou telephone reel.

### 6.15 Providers frontend

#### 6.15.1 `AuthProvider`

`AuthProvider` gere :

- le token
- l'utilisateur courant
- la validation de session
- login
- register
- Google login
- verification email
- reset password
- logout

Il conserve aussi localement le token et le `userId`.

#### 6.15.2 `FeedProvider`

Il gere :

- la liste des posts
- le chargement initial
- la pagination
- le filtre de faculte
- le rafraichissement
- la mise a jour d'un like

#### 6.15.3 `UserProvider`

Il gere le profil courant :

- chargement
- mise a jour
- merge des donnees temps reel

#### 6.15.4 `NotificationProvider`

Il gere :

- la liste des notifications
- le compteur de non lues
- le marquage en lecture
- l'insertion ou mise a jour d'une notification temps reel

### 6.16 Service temps reel frontend

#### 6.16.1 `frontend/lib/services/realtime_service.dart`

Le service temps reel :

- ouvre le socket vers `AppConfig.wsBaseUrl`
- active la reconnexion
- envoie `join`
- expose des streams `messages`, `notifications`, `stories`, `profileUpdates`, `typingEvents`

Ce service constitue le pont entre Socket.IO et les widgets Flutter.

### 6.17 Ecrans Flutter majeurs

#### 6.17.1 `MainNavigationScreen`

Cet ecran :

- charge le feed et les notifications apres la connexion
- connecte le service temps reel
- ecoute les notifications en direct
- ecoute les mises a jour de profil

Il agit comme un point de coordination apres l'authentification.

#### 6.17.2 `ModernFeedScreen`

Cet ecran gere :

- le feed
- le filtre par faculte
- la pagination infinie
- la section des stories
- l'ouverture des notifications
- l'ouverture de la messagerie
- le partage et les commentaires

Il ecoute aussi les events `storyCreated` et `storyDeleted`.

#### 6.17.3 `ChatScreen` et `ChatDetailScreen`

Ces ecrans gerent :

- la liste des conversations
- la creation d'une conversation
- la selection de pieces jointes
- l'envoi du message
- l'affichage conditionnel du type de piece jointe
- la frappe en cours
- la mise a jour temps reel des messages

Une fonction utilitaire deduit aussi le type d'une piece jointe a partir du `mimeType` ou de l'extension.

#### 6.17.4 `ModernProfileScreen`

Cet ecran :

- affiche soit le profil courant, soit un profil externe
- propose le follow/unfollow
- ouvre le chat
- charge les posts de l'utilisateur
- ecoute les mises a jour de profil
- expose l'acces admin dans les options du profil courant

#### 6.17.5 `AdminDashboardScreen`

Le dashboard admin charge en parallele :

- les stats
- les posts
- les utilisateurs
- les reports

Il offre une interface de moderation visuelle avec :

- resume hero
- cartes de statistiques
- liste des posts avec medias
- moderation utilisateur
- resolution des reports

### 6.18 API frontend et upload multipart

#### 6.18.1 `frontend/lib/services/api_service.dart`

Ce fichier unifie :

- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`
- `multipart`

Le point essentiel est `_sendMultipart()`. Cette methode :

- cree une `MultipartRequest`
- ajoute les champs texte
- ajoute les fichiers par chemin si disponible
- sinon ajoute les octets

Cette priorite au `path` rend les uploads plus fiables sur mobile et desktop.

### 6.19 Cohesion globale du code

Le projet montre une cohesion technique interessante :

- les models representent le stockage
- les serializers representent la sortie JSON
- les routes representent les cas d'usage
- les providers representent l'etat de presentation
- les services representent les acces reseau
- les ecrans representent l'experience utilisateur

Cette decomposition rend le code plus robuste et plus facile a faire evoluer.

---

## Chapitre 7 : Tests, securite, performance, limites et perspectives

### 7.1 Strategie de test

Le backend contient une suite de tests automatises dans `backend/tests/api.test.js`. Les tests couvrent des cas concrets de l'application.

Cas verifies :

- politique CORS
- inscription et connexion sans fuite du mot de passe
- regularisation des comptes non verifies
- follow / unfollow et notifications
- format du feed pagine
- dashboard admin
- conversations et moderation
- messages avec pieces jointes
- stories et graphe social
- notifications `message` et `post`

Cette couverture garantit que les contrats les plus critiques du backend restent stables.

### 7.2 Securite

Les principaux mecanismes de securite sont :

- hashage du mot de passe avec bcrypt
- authentification par JWT
- protection des routes via middleware
- limitation du trafic avec rate limiting
- controle des origines CORS
- durcissement des headers HTTP avec helmet
- masquage des champs sensibles dans les serialiseurs et schemas

### 7.3 Performance

Plusieurs choix ameliorent les performances :

- pagination des posts et notifications
- compression HTTP
- chargement conditionnel des donnees
- reconnection automatique Socket.IO
- TTL MongoDB pour les stories
- reutilisation des providers pour eviter des requetes inutiles
- cache d'images cote Flutter

### 7.4 Robustesse

Le projet contient plusieurs mecanismes de robustesse :

- `getRequestBody()` evite les crashs si `req.body` est absent
- le backend valide l'existence des utilisateurs cibles
- les erreurs sont centralisees
- la connexion MongoDB tente de se reconnecter en cas d'echec
- le frontend gere les cas reseau et affiche des messages utilisateur

### 7.5 Limites actuelles

Malgre son niveau de maturite, le projet peut encore etre approfondi. Quelques limites actuelles sont :

- la couche frontend n'expose pas encore tout le potentiel des modules groupes et evenements
- le stockage de fichiers est local dans `/uploads` et non sur un service cloud
- le dashboard admin peut encore gagner en filtres avances et pagination sur plus gros volumes
- certaines actions temps reel sont concentrees sur les events essentiels et peuvent etre etendues
- le module sauvegarde est present cote backend mais pas encore completement branche dans l'UX du profil

### 7.6 Perspectives d'amelioration

Les perspectives naturelles du projet sont :

- ajout d'un stockage cloud pour les fichiers
- chat enrichi avec previsualisation audio/video avancee
- moderation automatique assistee
- systeme de recommandations de contenu
- version plus complete des groupes et evenements cote frontend
- analytics d'usage pour l'administrateur
- deploiement public avec CI/CD

### 7.7 Bilan technique

Du point de vue logiciel, le projet constitue une base solide pour un veritable produit social universitaire. Il combine plusieurs dimensions rarement presentes ensemble dans un projet etudiant :

- mobile et web
- temps reel
- fichiers et pieces jointes
- moderation
- authentification moderne
- gestion d'etat
- tests automatises

---

## Conclusion generale

Le projet USMBA Social repond a un besoin concret de communication et de mise en relation dans le milieu universitaire. A travers une architecture moderne basee sur Flutter, Node.js, Express, MongoDB et Socket.IO, il propose une application complete couvrant l'authentification, la publication, les interactions sociales, la messagerie, les stories, les notifications et l'administration.

L'etude du code montre une structuration claire entre les couches frontend et backend, une bonne separation des responsabilites et une prise en compte reelle de la securite, de la robustesse et de l'experience utilisateur.

Ce travail constitue donc a la fois une realisation fonctionnelle et un support technique riche pour un rapport de PFE. Il peut servir de base a des extensions futures ou a une mise en production plus large dans un contexte universitaire.

---

## Annexes

### Annexe A : Arborescence simplifiee

```text
PFE/
|-- backend/
|   |-- app.js
|   |-- server.js
|   |-- config/
|   |-- middleware/
|   |-- models/
|   |-- routes/
|   |-- tests/
|   |-- uploads/
|   |-- utils/
|
|-- frontend/
|   |-- lib/
|   |   |-- main.dart
|   |   |-- providers/
|   |   |-- screens/
|   |   |-- services/
|   |   |-- widgets/
|   |   |-- theme/
|   |   |-- utils/
```

### Annexe B : Endpoints principaux

#### Authentification

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/auth/verify-email`
- `POST /api/auth/request-password-reset`
- `POST /api/auth/reset-password`

#### Utilisateurs

- `GET /api/users/profile`
- `PUT /api/users/profile`
- `PUT /api/users/profile/password`
- `GET /api/users/contacts`
- `GET /api/users/:id`
- `POST /api/users/follow/:id`
- `POST /api/users/unfollow/:id`

#### Posts

- `POST /api/posts`
- `GET /api/posts`
- `GET /api/posts/user/:userId`
- `POST /api/posts/:id/like`
- `POST /api/posts/:id/comment`
- `GET /api/posts/:id/comments`
- `POST /api/posts/:id/save`
- `POST /api/posts/:id/report`
- `DELETE /api/posts/:id`

#### Messages

- `GET /api/messages/conversations`
- `POST /api/messages`
- `GET /api/messages/:userId`

#### Stories

- `GET /api/stories/feed`
- `POST /api/stories`
- `POST /api/stories/:id/view`
- `DELETE /api/stories/:id`

#### Notifications

- `GET /api/notifications`
- `PUT /api/notifications/:id/read`
- `PUT /api/notifications/mark-all-read`

#### Administration

- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `GET /api/admin/posts`
- `GET /api/admin/reports`
- `PATCH /api/admin/users/:id/block`
- `PUT /api/admin/reports/:id`
- `DELETE /api/admin/posts/:id`

### Annexe C : Variables de configuration importantes

Exemples de variables utilisees par le projet :

```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb+srv://...
JWT_SECRET=...
CLIENT_URL=http://localhost:3000
CLIENT_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
REQUIRE_EMAIL_VERIFICATION=false
```

### Annexe D : Fichiers structurants du projet

#### Backend

- `backend/server.js`
- `backend/app.js`
- `backend/socket.js`
- `backend/routes/auth.js`
- `backend/routes/users.js`
- `backend/routes/posts.js`
- `backend/routes/messages.js`
- `backend/routes/stories.js`
- `backend/routes/admin.js`
- `backend/utils/serializers.js`
- `backend/utils/uploads.js`

#### Frontend

- `frontend/lib/main.dart`
- `frontend/lib/utils/app_config.dart`
- `frontend/lib/providers/auth_provider.dart`
- `frontend/lib/providers/feed_provider.dart`
- `frontend/lib/providers/user_provider.dart`
- `frontend/lib/providers/notification_provider.dart`
- `frontend/lib/services/api_service.dart`
- `frontend/lib/services/realtime_service.dart`
- `frontend/lib/screens/modern_feed_screen.dart`
- `frontend/lib/screens/chat_screen.dart`
- `frontend/lib/screens/modern_profile_screen.dart`
- `frontend/lib/screens/admin_dashboard_screen.dart`

### Annexe E : Utilisation du rapport

Ce document peut etre reutilise comme base de memoire PFE. Les prochaines ameliorations possibles sont :

- ajouter une page de garde officielle de l'etablissement
- inserer des captures d'ecran de l'application
- ajouter des diagrammes UML complements
- convertir ce Markdown en document Word ou PDF
- ajouter un chapitre sur le deploiement
