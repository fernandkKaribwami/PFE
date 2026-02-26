#!/bin/bash

# Script de configuration rapide de l'architecture Flutter moderne
# Utilisation: bash setup.sh

echo "🚀 Configuration de l'Architecture Flutter Moderne..."
echo "=================================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour vérifier si un fichier existe
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

echo ""
echo -e "${BLUE}1. Vérification du Design System...${NC}"
check_file "lib/theme/app_colors.dart"
check_file "lib/theme/app_typography.dart"
check_file "lib/theme/app_spacing.dart"
check_file "lib/theme/app_theme.dart"

echo ""
echo -e "${BLUE}2. Vérification des Providers Riverpod...${NC}"
check_file "lib/providers/theme_provider.dart"
check_file "lib/providers/auth_provider.dart"
check_file "lib/providers/feed_provider.dart"
check_file "lib/providers/user_provider.dart"
check_file "lib/providers/notification_provider.dart"

echo ""
echo -e "${BLUE}3. Vérification des Widgets Réutilisables...${NC}"
check_file "lib/widgets/base_widgets.dart"
check_file "lib/widgets/story_circle.dart"
check_file "lib/widgets/post_card.dart"
check_file "lib/widgets/photo_view_screen.dart"

echo ""
echo -e "${BLUE}4. Vérification des Utilitaires...${NC}"
check_file "lib/utils/extensions.dart"
check_file "lib/utils/image_utils.dart"
check_file "lib/utils/validation_utils.dart"
check_file "lib/utils/notification_utils.dart"
check_file "lib/utils/app_config.dart"

echo ""
echo -e "${BLUE}5. Vérification des Exemples d'Écrans...${NC}"
check_file "lib/screens/modern_feed_screen.dart"
check_file "lib/screens/modern_profile_screen.dart"

echo ""
echo -e "${BLUE}6. Vérification de la Documentation...${NC}"
check_file "lib/INTEGRATION_GUIDE.dart"
check_file "ARCHITECTURE.md"
check_file "IMPLEMENTATION_CHECKLIST.md"
check_file "INSTALLATION_GUIDE.md"

echo ""
echo -e "${BLUE}7. Vérification de pubspec.yaml...${NC}"
if grep -q "flutter_riverpod" pubspec.yaml; then
    echo -e "${GREEN}✅ flutter_riverpod${NC}"
else
    echo -e "${RED}❌ flutter_riverpod manquant dans pubspec.yaml${NC}"
fi

if grep -q "cached_network_image" pubspec.yaml; then
    echo -e "${GREEN}✅ cached_network_image${NC}"
else
    echo -e "${RED}❌ cached_network_image manquant dans pubspec.yaml${NC}"
fi

if grep -q "photo_view" pubspec.yaml; then
    echo -e "${GREEN}✅ photo_view${NC}"
else
    echo -e "${RED}❌ photo_view manquant dans pubspec.yaml${NC}"
fi

echo ""
echo "=================================================="
echo -e "${YELLOW}Étapes suivantes:${NC}"
echo ""
echo "1. Exécuter: ${YELLOW}flutter pub get${NC}"
echo "2. Exécuter: ${YELLOW}flutter pub run build_runner build${NC}"
echo "3. Exécuter: ${YELLOW}flutter run${NC}"
echo ""
echo -e "${GREEN}✨ Configuration terminée!${NC}"
echo ""
echo -e "${BLUE}Pour plus d'informations, consultez:${NC}"
echo "  - ARCHITECTURE.md - Documentation détaillée"
echo "  - INSTALLATION_GUIDE.md - Guide d'installation"
echo "  - IMPLEMENTATION_CHECKLIST.md - Checklist d'implémentation"
echo ""
