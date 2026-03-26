import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: post['author']?['avatar'] != null
                  ? NetworkImage(post['author']['avatar'])
                  : null,
              child: post['author']?['avatar'] == null
                  ? Text(
                      post['author']?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              post['author']?['name'] ?? 'Utilisateur',
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

          // Content
          if (post['content'] != null && post['content'].toString().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post['content'],
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],

          // Media
          if (post['media'] != null) ...[
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(post['media']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Like
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                    color: post['isLiked'] == true ? Colors.red : Colors.grey,
                  ),
                ),
                Text(
                  '${post['likesCount'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(width: 16),

                // Comment
                IconButton(
                  onPressed: onComment,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Text(
                  '${post['commentsCount'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),

                const Spacer(),

                // Share
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
      } else if (difference.inHours > 0) {
        return 'il y a ${difference.inHours} h';
      } else if (difference.inMinutes > 0) {
        return 'il y a ${difference.inMinutes} min';
      } else {
        return 'il y a quelques instants';
      }
    } catch (e) {
      return 'il y a quelques instants';
    }
  }
}
