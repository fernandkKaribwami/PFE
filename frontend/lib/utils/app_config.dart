import 'package:flutter/foundation.dart';

/// Configuration globale de l'application
class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _wsBaseUrlOverride = String.fromEnvironment(
    'WS_BASE_URL',
  );
  static const String _googleClientIdOverride = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );
  static const String _defaultGoogleClientId =
      '933200279622-i4kt31bhh6738subsrjot4qrvpolg551.apps.googleusercontent.com';

  static String get apiOrigin {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
        return 'http://localhost:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  static String get apiBaseUrl => '$apiOrigin/api';

  static String get googleClientId => _googleClientIdOverride.isNotEmpty
      ? _googleClientIdOverride
      : _defaultGoogleClientId;

  static String get wsBaseUrl {
    if (_wsBaseUrlOverride.isNotEmpty) {
      return _wsBaseUrlOverride;
    }

    return apiOrigin.replaceFirst(RegExp(r'^http'), 'ws');
  }

  static String resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '';
    }

    final normalized = path.trim();
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:') ||
        normalized.startsWith('blob:')) {
      return normalized;
    }

    if (normalized.startsWith('//')) {
      return 'https:$normalized';
    }

    if (normalized.startsWith('/')) {
      return '$apiOrigin$normalized';
    }

    return '$apiOrigin/$normalized';
  }

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
