# USMBA Social

Reseau social universitaire construit avec Flutter, Node.js, Express, MongoDB Atlas et Socket.IO.

## Stack

- Frontend: Flutter Web, Android, iOS
- Backend: Node.js + Express
- Base de donnees: MongoDB Atlas via `backend/.env`
- Temps reel: Socket.IO
- Uploads: Multer

## Base de donnees

Le backend utilise la variable `MONGODB_URI` du fichier `backend/.env`.

Si ton `backend/.env` contient une URI MongoDB Atlas, alors l'application utilise la base cloud.

Exemple:

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/usmba_db?retryWrites=true&w=majority
```

Le fichier `backend/.env.example` est seulement un modele sans secrets.

## Demarrage rapide

### Windows

Depuis la racine du projet:

```powershell
.\start.bat
```

### Linux / macOS

```bash
chmod +x start.sh
./start.sh
```

## Demarrage manuel

### 1. Backend

```bash
cd backend
npm install
npm run seed
npm start
```

Le backend demarre sur `http://localhost:5000`.

### 2. Frontend Web

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 3000 --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_BASE_URL=ws://localhost:5000 --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID_GOOGLE
```

Le frontend demarre sur `http://localhost:3000`.

## Mobile

### Android emulator

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=WS_BASE_URL=ws://10.0.2.2:5000 --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID_GOOGLE
```

### iOS simulator

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_BASE_URL=ws://localhost:5000 --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID_GOOGLE
```

### Telephone physique

Remplace `localhost` par l'adresse IP locale de ton PC:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000 --dart-define=WS_BASE_URL=ws://192.168.1.10:5000 --dart-define=GOOGLE_CLIENT_ID=VOTRE_CLIENT_ID_GOOGLE
```

Les scripts `start.bat` et `start.sh` lisent automatiquement `GOOGLE_CLIENT_ID` depuis `backend/.env` et le transmettent au frontend.

Pour Google Sign-In Web, configure aussi dans Google Cloud Console :

- `Authorized JavaScript origins` : `http://localhost:3000`
- utilise un vrai client OAuth de type `Web application`

## Dashboard administrateur

Le dashboard admin est dans la meme application Flutter.

Pour y acceder:

- connecte-toi avec un utilisateur dont `role=admin`
- ouvre l'icone admin dans la barre du haut

## Variables importantes

Dans `backend/.env`:

```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb+srv://...
JWT_SECRET=...
CLIENT_URL=http://localhost:3000
CLIENT_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

## Important

- MongoDB Atlas est tres bien pour ce projet si tu veux une base unique, accessible depuis plusieurs machines.
- Pour le developpement local, elle evite d'avoir un MongoDB local a installer partout.
- Il faut autoriser ton IP dans MongoDB Atlas Network Access.
- Tes secrets MongoDB, SMTP et Cloudinary ne doivent pas etre partages publiquement. Pense a les regenerer si tu les as exposes.
