import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StoryCircle extends StatelessWidget {
  final String? userId;
  final String userName;
  final String? avatarUrl;
  final String? previewUrl;
  final bool isViewed;
  final bool isAddStory;
  final VoidCallback? onTap;

  const StoryCircle({
    super.key,
    this.userId,
    required this.userName,
    this.avatarUrl,
    this.previewUrl,
    this.isViewed = false,
    this.isAddStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayInitial = userName.isEmpty
        ? '+'
        : userName.substring(0, 1).toUpperCase();
    final displayImageUrl = (previewUrl != null && previewUrl!.isNotEmpty)
        ? previewUrl!
        : (avatarUrl ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isAddStory
                        ? [
                            AppColors.primary.withValues(alpha: 0.92),
                            AppColors.primary.withValues(alpha: 0.68),
                          ]
                        : [
                            isViewed
                                ? Colors.grey.shade300
                                : const Color(0xFFFF8A65),
                            isViewed ? Colors.grey.shade400 : AppColors.primary,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: displayImageUrl.isNotEmpty
                        ? Image.network(
                            displayImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _StoryFallback(
                                initial: isAddStory ? '+' : displayInitial,
                                isAddStory: isAddStory,
                              );
                            },
                          )
                        : _StoryFallback(
                            initial: isAddStory ? '+' : displayInitial,
                            isAddStory: isAddStory,
                          ),
                  ),
                ),
              ),
              if (isAddStory)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAddStory ? FontWeight.w700 : FontWeight.w500,
                color: isViewed ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryFallback extends StatelessWidget {
  final String initial;
  final bool isAddStory;

  const _StoryFallback({required this.initial, this.isAddStory = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isAddStory
          ? AppColors.primary.withValues(alpha: 0.08)
          : const Color(0xFFF5F7FB),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: isAddStory ? 24 : 20,
          ),
        ),
      ),
    );
  }
}
