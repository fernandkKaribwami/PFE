@echo off
echo ============================================
echo 🚀 USMBA Social Network - Démarrage Rapide
echo ============================================
echo.

echo 🔧 Vérification des prérequis...
echo.

REM Vérifier si Node.js est installé
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org
    pause
    exit /b 1
)

REM Vérifier si MongoDB est installé et démarré
net start MongoDB >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  MongoDB n'est pas démarré. Tentative de démarrage...
    net start MongoDB >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Impossible de démarrer MongoDB. Veuillez le démarrer manuellement.
        pause
        exit /b 1
    )
)

REM Vérifier si Flutter est installé
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas installé. Veuillez l'installer depuis https://flutter.dev
    pause
    exit /b 1
)

echo ✅ Prérequis vérifiés avec succès !
echo.

echo ============================================
echo 🚀 Démarrage du Backend
echo ============================================
cd backend
echo 📦 Installation des dépendances backend...
call npm install

echo 🗄️  Démarrage du serveur backend...
start "Backend Server" cmd /k "node server.js"

echo ✅ Backend démarré sur http://localhost:5000
echo.

timeout /t 3 /nobreak >nul

echo ============================================
echo 📱 Démarrage du Frontend Flutter
echo ============================================
cd ../frontend
echo 📦 Installation des dépendances Flutter...
call flutter pub get

echo 🌐 Lancement de l'application Flutter...
call flutter run -d chrome

echo.
echo ============================================
echo 🎉 Application USMBA Social Network prête !
echo ============================================
echo.
echo 🌐 Frontend: http://localhost:3000 (ou port Flutter)
echo 🔗 Backend API: http://localhost:5000/api
echo 🗄️  Base de données: MongoDB localhost:27017
echo.
echo 📱 Fonctionnalités disponibles:
echo   • Authentification sécurisée
echo   • Feed avec posts et stories
echo   • Recherche d'utilisateurs
echo   • Création de posts
echo   • Profils utilisateur
echo   • Messagerie (base)
echo.
echo 🛑 Pour arrêter: Ctrl+C dans chaque terminal
echo.
pause