import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StoryCircle extends StatelessWidget {
  const StoryCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.add,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Votre story',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = AppImageSize.storySize;
    final borderWidth = 3.0;
    final gradientColors = widget.gradientColors ??
        [
          widget.isViewed ? AppColors.greyLight400 : AppColors.accentPink,
          widget.isViewed ? AppColors.greyLight400 : AppColors.accentOrange,
        ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: () => _controller.reverse(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story ring avec gradient
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              padding: EdgeInsets.all(borderWidth),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(3),
                child: CachedAvatarImage(
                  imageUrl: widget.avatarUrl,
                  size: size - (borderWidth * 2) - 6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Username
            SizedBox(
              width: size + AppSpacing.lg,
              child: Text(
                widget.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.isViewed ? AppColors.greyLight500 : null,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row horizontal de multiple stories
class StoriesHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final Function(String) onStoryTap;
  final bool showAddYourStory;

  const StoriesHorizontalList({
    super.key,
    required this.stories,
    required this.onStoryTap,
    this.showAddYourStory = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (showAddYourStory)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppImageSize.storySize,
                  height: AppImageSize.storySize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onStoryTap('add_story'),
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Votre story',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          if (showAddYourStory) const SizedBox(width: AppSpacing.lg),
          ...stories.map(
            (story) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: StoryCircle(
                userId: story['userId'] ?? '',
                userName: story['userName'] ?? 'User',
                avatarUrl: story['avatarUrl'],
                isViewed: story['isViewed'] ?? false,
                onTap: () => onStoryTap(story['userId']),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
