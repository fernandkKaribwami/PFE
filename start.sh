#!/bin/bash

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOOGLE_CLIENT_ID="$(grep '^GOOGLE_CLIENT_ID=' "$ROOT_DIR/backend/.env" 2>/dev/null | head -n 1 | cut -d '=' -f 2- | tr -d '\r')"

echo "============================================"
echo "USMBA Social - Lancement Web"
echo "============================================"
echo

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js est requis: https://nodejs.org"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter est requis: https://flutter.dev"
  exit 1
fi

echo "Installation des dependances backend..."
cd "$ROOT_DIR/backend"
npm install

echo "Installation des dependances Flutter..."
cd "$ROOT_DIR/frontend"
flutter pub get

echo
echo "Demarrage backend sur http://localhost:5000"
cd "$ROOT_DIR/backend"
npm start &
BACKEND_PID=$!

sleep 3

echo "Demarrage Flutter Web sur http://localhost:3000"
cd "$ROOT_DIR/frontend"
FLUTTER_ARGS=(
  -d chrome
  --web-hostname localhost
  --web-port 3000
  --dart-define=API_BASE_URL=http://localhost:5000
  --dart-define=WS_BASE_URL=ws://localhost:5000
)

if [ -n "$GOOGLE_CLIENT_ID" ]; then
  FLUTTER_ARGS+=("--dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID")
fi

flutter run "${FLUTTER_ARGS[@]}"

cleanup() {
  kill $BACKEND_PID 2>/dev/null || true
}

trap cleanup EXIT INT TERM
