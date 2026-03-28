import 'package:flutter/material.dart';

import '../screens/modern_profile_screen.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final author = post['user'] ?? post['author'] ?? {};
    final authorId = author['_id']?.toString() ?? author['id']?.toString();
    final authorName = author['name']?.toString() ?? 'Utilisateur';
    final avatarUrl = AppConfig.resolveUrl(author['avatar']?.toString());
    final mediaUrl = AppConfig.resolveUrl(post['media']?.toString());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: authorId == null || authorId.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModernProfileScreen(userId: authorId),
                      ),
                    );
                  },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      (authorName.isNotEmpty
                              ? authorName.substring(0, 1)
                              : 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              authorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _formatTimeAgo(post['createdAt']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
          if (post['content'] != null && post['content'].toString().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post['content'],
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
          if (mediaUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(0),
              ),
              child: Image.network(
                mediaUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 36),
                        SizedBox(height: 8),
                        Text('Image indisponible'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post['isLiked'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post['isLiked'] == true ? Colors.red : Colors.grey,
                  ),
                ),
                Text(
                  '${post['likesCount'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onComment,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Text(
                  '${post['commentsCount'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null) return 'il y a quelques instants';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'il y a ${difference.inDays} j';
      }
      if (difference.inHours > 0) {
        return 'il y a ${difference.inHours} h';
      }
      if (difference.inMinutes > 0) {
        return 'il y a ${difference.inMinutes} min';
      }
      return 'il y a quelques instants';
    } catch (e) {
      return 'il y a quelques instants';
    }
  }
}
