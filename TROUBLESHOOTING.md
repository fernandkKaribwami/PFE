# Guide de Dépannage - Système de Facultés

## Erreurs Courantes et Solutions

### 1. ❌ MongoDB Connection Error

**Erreur:**
```
Could not connect to any servers in your MongoDB Atlas cluster. One common reason 
is that you're trying to access the database from an IP that isn't whitelisted.
```

**Solution:**
1. Aller sur https://cloud.mongodb.com/
2. Sélectionner le cluster `cluster0`
3. Aller dans `Security → Network Access`
4. Cliquer `Add IP Address`
5. Entrer votre IP actuelle (ou `0.0.0.0/0` pour développement local)
6. Cliquer `Confirm`
7. Réessayer: `node seed.js`

---

### 2. ❌ Duplicate Key Error lors du Seed

**Erreur:**
```
MongoServerError: E11000 duplicate key error collection: usmba_db.faculties 
index: name_1 dup key: { name: "..." }
```

**Solution 1: Automatique**
Le script seed.js détecte cela et supprime automatiquement les doublons avant d'insérer.

**Solution 2: Manuelle**
```javascript
// Dans MongoDB Compass ou shell
use usmba_db
db.faculties.deleteMany({})  // Supprimer toutes les facultés
// Puis relancer: node seed.js
```

---

### 3. ❌ Flutter Widget Errors

#### Erreur: "Faculty selector not displaying"

**Vérification:**
```dart
// Vérifier que FacultyProvider est dans MultiProvider
// En main.dart:
ChangeNotifierProvider(create: (_) => FacultyProvider()),  // ✅ Doit être présent
```

**Correction:**
1. Vérifier que `faculty_provider.dart` est importé dans `main.dart`
2. Vérifier que `FacultySelector` est importé dans `modern_feed_screen.dart`
3. Redémarrer l'app Flutter: `flutter clean && flutter pub get && flutter run`

---

#### Erreur: "API request failed"

**Solution:**
1. Vérifier que le backend fonctionne:
   ```bash
   curl http://localhost:5000/api/faculties
   ```

2. Vérifier le `API_URL` dans `frontend/lib/main.dart`:
   ```dart
   const String API_URL = kIsWeb
       ? 'http://localhost:5000'
       : 'http://10.0.2.2:5000';  // Pour Android emulator
   ```

3. Sur Android emulator, utiliser `10.0.2.2` au lieu de `localhost`

---

### 4. ❌ Feed ne filtre pas par faculté

**Vérification:**
```dart
// feedProvider.loadFeed() doit inclure facultyId:
feedProvider.loadFeed(token, facultyId: facultyId);  // ✅ Correct

// NOT:
feedProvider.loadFeed(token);  // ❌ Charge tous les posts
```

**Vérifier dans `modern_feed_screen.dart`:**
```dart
FacultySelector(
  onFacultyChanged: (facultyId) {
    feedProvider.loadFeed(authProvider.token!, facultyId: facultyId);  // ✅
  },
),
```

---

### 5. ❌ Erreur: "Slug already exists"

**Cause:** Deux facultés avec le même name ou slug

**Solution:**
```bash
# Vérifier les doublons:
# Dans MongoDB Compass:
db.faculties.find({ name: "Faculté X" }).count()

# Si > 1, supprimer les doublons:
db.faculties.deleteMany({ name: "Faculté X" })
db.faculties.insertOne({ name: "Faculté X", slug: "faculte-x", ... })
```

---

### 6. ❌ Erreur Backend: "Faculty not found"

**Cause:** L'ID de la faculté est invalide

**Vérification:**
```bash
# Obtenir toutes les facultés:
curl http://localhost:5000/api/faculties

# Copier un _id valide et tester:
curl http://localhost:5000/api/faculties/{_id_valide}
```

---

### 7. ❌ Logs Mongoose: "Duplicate schema index"

**Erreur:**
```
[MONGOOSE] Warning: Duplicate schema index on {"slug":1} found.
```

**Correction:**
C'est déjà corrigé! Vérifier `models/Faculty.js`:
```javascript
// ✅ CORRECT:
const FacultySchema = new mongoose.Schema({
  slug: { type: String, required: true, unique: true }
}, { timestamps: true });
// Ne pas ajouter: FacultySchema.index({ slug: 1 }) - c'est redondant!
```

---

## Tests Manuels

### Test 1: Seed Script
```bash
cd backend
npm install
node seed.js
```
✅ Devrait afficher "Successfully seeded 11 faculties" avec les IDs

### Test 2: API Faculties
```bash
curl http://localhost:5000/api/faculties
```
✅ Devrait retourner une liste JSON de 11 facultés

### Test 3: Frontend
```bash
cd frontend
flutter run
```
✅ Devrait voir le dropdown de sélection de facultés en haut du feed

### Test 4: Filtrage
1. Ouvrir l'app flutter
2. Faire défiler le feed
3. Sélectionner une autre faculté
4. Feed devrait se rafraîchir avec les posts de cette faculté

---

## Commandes Utiles

### Backend - Debugging
```bash
# Voir les logs du serveur
npm start

# Seed avec output détaillé
node seed.js

# Tester un endpoint spécifique
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5000/api/faculties/{id}/members
```

### Flutter - Debugging
```bash
# Voir les logs
flutter run -v

# Nettoyer et reconstruire  
flutter clean
flutter pub get
flutter run

# Accéder à DevTools
flutter run -d emulator-5554 --debuggable
```

### MongoDB - Debugging
```bash
# Utiliser MongoDB Compass (GUI) pour explorer
# ou MongoDB Shell:
mongosh "mongodb+srv://admin:1234@cluster0.ujlt08n.mongodb.net/usmba_db"

# Commands dans MongoDB Shell:
use usmba_db
db.faculties.find().pretty()
db.faculties.countDocuments()
db.faculties.deleteMany({})
```

---

## Checklist de Vérification

- [ ] MongoDB whitelist IP configurée
- [ ] Backend démarré: `npm start`
- [ ] Seed exécuté sans erreur: `node seed.js`
- [ ] API répond: `curl http://localhost:5000/api/faculties`
- [ ] Frontend compilé: `flutter run`
- [ ] FacultySelector visible dans l'app
- [ ] Sélection de faculté filtre le feed
- [ ] Pas d'erreurs dans les logs

---

## Liens Utiles

- **MongoDB Atlas Dashboard**: https://cloud.mongodb.com/
- **MongoDB Documentation**: https://docs.mongodb.com/
- **Flutter Documentation**: https://flutter.dev/docs
- **Express.js Documentation**: https://expressjs.com/

---

**Besoin d'aide?** Vérifier les logs:
- Backend: Console du serveur Node.js
- Frontend Dart: `flutter run -v`
- MongoDB: MongoDB Compass ou Atlas Dashboard
