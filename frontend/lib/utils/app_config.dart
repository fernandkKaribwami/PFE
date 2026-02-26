/// Configuration globale de l'application
class AppConfig {
  // API
  static const String apiBaseUrl = 'http://localhost:5000';
  static const String wsBaseUrl = 'ws://localhost:5000';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration socketTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Cache
  static const Duration imageCacheDuration = Duration(days: 7);
  static const Duration dataCacheDuration = Duration(hours: 1);

  // Images
  static const double maxImageWidth = 1080;
  static const double maxImageHeight = 1920;
  static const int imageQuality = 85;

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Validations
  static const int minPasswordLength = 8;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;
  static const int maxPostLength = 1000;

  // Limitations de fichiers
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageFileSize = 5 * 1024 * 1024; // 5 MB
  static const int maxVideoFileSize = 100 * 1024 * 1024; // 100 MB

  // Notifications
  static const Duration notificationDuration = Duration(seconds: 4);
  static const Duration refreshInterval = Duration(minutes: 1);

  // Logging
  static const bool enableLogging = true;
  static const bool enableDebugLogging = true;
}

/// Erreurs personnalisées
class AppException implements Exception {
  final String message;
  final dynamic originalException;

  AppException({
    required this.message,
    this.originalException,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required String message, dynamic exception})
      : super(message: message, originalException: exception);
}

class ServerException extends AppException {
  ServerException({required String message, dynamic exception})
      : super(message: message, originalException: exception);
}

class ValidationException extends AppException {
  ValidationException({required String message})
      : super(message: message);
}

class CacheException extends AppException {
  CacheException({required String message})
      : super(message: message);
}
