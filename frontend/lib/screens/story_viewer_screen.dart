import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_config.dart';

class StoryViewerScreen extends StatelessWidget {
  final Map<String, dynamic> story;

  const StoryViewerScreen({super.key, required this.story});

  bool _looksLikeImageUrl(String value) {
    final normalized = value.toLowerCase();
    return normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.gif') ||
        normalized.endsWith('.webp');
  }

  bool get _isImage {
    final mediaType = story['mediaType']?.toString().toLowerCase() ?? '';
    final mediaUrl = story['mediaUrl']?.toString().toLowerCase() ?? '';

    return mediaType.startsWith('image/') ||
        mediaType == 'image' ||
        _looksLikeImageUrl(mediaUrl);
  }

  @override
  Widget build(BuildContext context) {
    final user = story['user'] as Map<String, dynamic>? ?? {};
    final caption = story['caption']?.toString() ?? '';
    final mediaUrl = AppConfig.resolveUrl(story['mediaUrl']?.toString());
    final avatarUrl = AppConfig.resolveUrl(user['avatar']?.toString());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isImage && mediaUrl.isNotEmpty
                  ? InteractiveViewer(
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const _StoryMediaPlaceholder();
                        },
                      ),
                    )
                  : const _StoryMediaPlaceholder(),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    child: avatarUrl.isEmpty
                        ? Text(
                            (user['name']?.toString().isNotEmpty ?? false)
                                ? user['name']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'U',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name']?.toString() ?? 'Story',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          caption.isEmpty ? 'Story recente' : caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        caption.isEmpty
                            ? 'Story partagee en temps reel'
                            : caption,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryMediaPlaceholder extends StatelessWidget {
  const _StoryMediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Ce type de story n a pas de previsualisation',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
