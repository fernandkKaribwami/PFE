#!/bin/bash

echo "============================================"
echo "🚀 USMBA Social Network - Démarrage Rapide"
echo "============================================"
echo

echo "🔧 Vérification des prérequis..."
echo

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org"
    exit 1
fi

# Vérifier si MongoDB est installé et démarré
if ! pgrep mongod > /dev/null; then
    echo "⚠️  MongoDB n'est pas démarré. Tentative de démarrage..."
    if command -v brew &> /dev/null; then
        brew services start mongodb-community
    elif command -v systemctl &> /dev/null; then
        sudo systemctl start mongod
    else
        echo "❌ Impossible de démarrer MongoDB automatiquement. Veuillez le démarrer manuellement."
        exit 1
    fi
fi

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé. Veuillez l'installer depuis https://flutter.dev"
    exit 1
fi

echo "✅ Prérequis vérifiés avec succès !"
echo

echo "============================================"
echo "🚀 Démarrage du Backend"
echo "============================================"
cd backend
echo "📦 Installation des dépendances backend..."
npm install

echo "🗄️  Démarrage du serveur backend..."
node server.js &
BACKEND_PID=$!

echo "✅ Backend démarré sur http://localhost:5000"
echo

sleep 3

echo "============================================"
echo "📱 Démarrage du Frontend Flutter"
echo "============================================"
cd ../frontend
echo "📦 Installation des dépendances Flutter..."
flutter pub get

echo "🌐 Lancement de l'application Flutter..."
flutter run -d chrome

echo
echo "============================================"
echo "🎉 Application USMBA Social Network prête !"
echo "============================================"
echo
echo "🌐 Frontend: http://localhost:3000 (ou port Flutter)"
echo "🔗 Backend API: http://localhost:5000/api"
echo "🗄️  Base de données: MongoDB localhost:27017"
echo
echo "📱 Fonctionnalités disponibles:"
echo "  • Authentification sécurisée"
echo "  • Feed avec posts et stories"
echo "  • Recherche d'utilisateurs"
echo "  • Création de posts"
echo "  • Profils utilisateur"
echo "  • Messagerie (base)"
echo
echo "🛑 Pour arrêter: Ctrl+C ou tuer les processus"
echo

# Fonction de nettoyage
cleanup() {
    echo "Arrêt des services..."
    kill $BACKEND_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM
wait