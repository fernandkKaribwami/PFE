# Frontend USMBA Social

## Prerequis

- Flutter installe et disponible dans le `PATH`
- Backend Node.js lance sur `http://localhost:5000`
- MongoDB lance localement

## Installation

```bash
flutter pub get
```

## Lancer en Web

```bash
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_BASE_URL=ws://localhost:5000
```

Le frontend sera accessible sur `http://localhost:3000`.

## Lancer sur Android Emulator

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=WS_BASE_URL=ws://10.0.2.2:5000
```

## Lancer sur iOS Simulator

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_BASE_URL=ws://localhost:5000
```

## Lancer sur Telephone Physique

Remplace `localhost` par l'adresse IP locale de ton PC.

Exemple:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000 --dart-define=WS_BASE_URL=ws://192.168.1.10:5000
```

## Configuration prise en charge

Le frontend lit automatiquement:

- `API_BASE_URL`
- `WS_BASE_URL`

Par defaut:

- Web: `http://localhost:5000`
- Android emulator: `http://10.0.2.2:5000`
- iOS simulator: `http://localhost:5000`

## Ecrans actifs relies au backend

- Authentification
- Feed
- Creation de post
- Recherche
- Chat
- Profil moderne
- Dashboard administrateur
