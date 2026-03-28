@echo off
setlocal
set ROOT_DIR=%~dp0
cd /d "%ROOT_DIR%"

echo ============================================
echo USMBA Social - Lancement Web
echo ============================================
echo.

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Node.js est requis: https://nodejs.org
    pause
    exit /b 1
)

flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter est requis: https://flutter.dev
    pause
    exit /b 1
)

echo Installation des dependances backend...
cd /d "%ROOT_DIR%backend"
call npm install
if %errorlevel% neq 0 (
    echo Echec npm install
    pause
    exit /b 1
)

echo Installation des dependances Flutter...
cd /d "%ROOT_DIR%frontend"
call flutter pub get
if %errorlevel% neq 0 (
    echo Echec flutter pub get
    pause
    exit /b 1
)

echo.
echo Demarrage backend sur http://localhost:5000
start "USMBA Backend" cmd /k "cd /d %ROOT_DIR%backend && npm start"

timeout /t 3 /nobreak >nul

echo Demarrage Flutter Web sur http://localhost:3000
call flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_BASE_URL=ws://localhost:5000

echo.
echo Pour mobile:
echo   Android emulateur: flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=WS_BASE_URL=ws://10.0.2.2:5000
echo   Appareil physique: remplace localhost par l'IP locale de ton PC
echo.
pause
