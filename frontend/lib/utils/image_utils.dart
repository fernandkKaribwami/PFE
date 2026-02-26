import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Utilitaires pour les images avec caching automatique
class ImageUtils {
  /// Charger une image avec caching
  static Widget cachedNetworkImage({
    required String imageUrl,
    required BoxFit fit,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    Duration cacheDuration = const Duration(days: 7),
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      cacheKey: imageUrl, // Cache key unique
      maxHeightDiskCache: 1024,
      maxWidthDiskCache: 1024,
      memCacheHeight: (height?.toInt() ?? 200),
      memCacheWidth: (width?.toInt() ?? 200),
      cacheManager: CacheManager.getInstance(),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported_outlined),
          ),
    );
  }

  /// Thumbnail optimisé pour les listes
  static Widget cachedThumbnail({
    required String imageUrl,
    double size = 100,
    BoxFit fit = BoxFit.cover,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: size,
      height: size,
      cacheKey: '${imageUrl}_thumb_$size',
      memCacheHeight: size.toInt(),
      memCacheWidth: size.toInt(),
      cacheManager: CacheManager.getInstance(),
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const SizedBox.expand(),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  /// Importer de multiples images
  static List<String> optimizeImageUrls(List<String> urls) {
    return urls.map((url) {
      // Ajouter des paramètres d'optimisation si nécessaire (ex: pour imgix, Cloudinary)
      // Exemple: if (url.contains('cloudinary')) { return '$url?w=800&q=auto'; }
      return url;
    }).toList();
  }
}

/// Cache Manager personnalisé
class CacheManager {
  static late CachedNetworkImageProvider _instance;

  static CachedNetworkImageProvider getInstance() {
    try {
      // Retourner le default cache manager de cached_network_image
      return cachedNetworkImageProvider;
    } catch (e) {
      // Fallback au provider standard
      return cachedNetworkImageProvider;
    }
  }
}

// Dummy provider pour l'exemple
const cachedNetworkImageProvider = CachedNetworkImageProvider('');

/// Gestion de la mémoire pour les images
class ImageMemoryManager {
  /// Vider le cache des images
  static Future<void> clearImageCache() async {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Obtenir la taille du cache
  static String getCacheSummary() {
    final summary = imageCache.statusForKey(NetworkAssetImage(''));
    return 'Cache Status: $summary';
  }
}
