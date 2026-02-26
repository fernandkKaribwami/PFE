/// Utilitaires de validation
class ValidationUtils {
  /// Valider un email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valider un mot de passe
  static bool isValidPassword(String password) {
    // Au moins 8 caractères, 1 majuscule, 1 chiffre
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// Valider un nom d'utilisateur
  static bool isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  /// Valider un nombre de téléphone
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Valider un URL
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(url);
  }

  /// Valider le texte (non vide, longueur)
  static String? validateText(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 1000,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }

    if (value.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractères';
    }

    if (value.length > maxLength) {
      return '$fieldName ne doit pas dépasser $maxLength caractères';
    }

    return null;
  }

  /// Valider l'email (avec message)
  static String? validateEmailField(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    if (!isValidEmail(value)) {
      return 'Veuillez entrer un email valide';
    }

    return null;
  }

  /// Valider le mot de passe (avec message)
  static String? validatePasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    return null;
  }

  /// Valider la confirmation du mot de passe
  static String? validatePasswordConfirmation(
    String? value,
    String password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Extraire les hashtags d'un texte
  static List<String> extractHashtags(String text) {
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((match) => '#${match.group(1)}').toList();
  }

  /// Extraire les mentions d'utilisateurs
  static List<String> extractMentions(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((match) => '@${match.group(1)}').toList();
  }
}
