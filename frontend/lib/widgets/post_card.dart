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

class _PostCardState extends State<PostCard> {
  late bool _showComments;
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;

  @override
  void initState() {
    super.initState();
    _showComments = false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'à l\'instant';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}j';
    
    return DateFormat('dd MMM', 'fr_FR').format(dateTime);
  }

  void _toggleComments() async {
    setState(() {
      _showComments = !_showComments;
      if (_showComments && _comments.isEmpty) {
        _loadingComments = true;
        // Simuler le chargement des commentaires
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _loadingComments = false;
              _comments = [
                {
                  'id': '1',
                  'author': 'Ahmed Alami',
                  'avatar': null,
                  'text': 'Super post! 🎉',
                  'likes': 5,
                },
                {
                  'id': '2',
                  'author': 'Fatima Ben',
                  'avatar': null,
                  'text': 'Bien vu!',
                  'likes': 2,
                },
              ];
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, nom, faculty, menu
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CachedAvatarImage(
                  imageUrl: widget.authorAvatarUrl,
                  size: AppImageSize.avatarMd,
                ),
                const SizedBox(width: AppSpacing.md),
                // Infos auteur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.faculty,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTime(widget.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                    ],
                  ),
                ),
                // Menu button
                if (widget.onMore != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: widget.onMore,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),

          // Contenu texte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              widget.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Image
          if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: AppImageSize.postImageHeight,
              color: Theme.of(context).disabledColor.withOpacity(0.1),
              child: Stack(
                children: [
                  Image.network(
                    widget.mediaUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: AppImageSize.postImageHeight,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: AppImageSize.postImageHeight,
                          borderRadius: BorderRadius.zero,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppColors.greyLight400,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Image non disponible',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.greyLight500,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),

          // Stats (likes, comments)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (widget.likesCount > 0)
                  Expanded(
                    child: Text(
                      '${widget.likesCount} j\'aime',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (widget.commentsCount > 0)
                  GestureDetector(
                    onTap: _toggleComments,
                    child: Text(
                      '${widget.commentsCount} commentaire${widget.commentsCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HeartLikeButton(
                  isLiked: widget.isLiked,
                  count: widget.likesCount,
                  onPressed: widget.onLike,
                ),
                AnimatedActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Commenter',
                  onPressed: () {
                    _toggleComments();
                    widget.onComment();
                  },
                ),
                if (widget.onShare != null)
                  AnimatedActionButton(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    onPressed: widget.onShare!,
                  ),
                if (widget.onSave != null)
                  AnimatedActionButton(
                    icon: widget.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    label: widget.isSaved ? 'Enregistré' : 'Enregistrer',
                    isSelected: widget.isSaved,
                    onPressed: widget.onSave!,
                  ),
              ],
            ),
          ),

          // Commentaires
          if (_showComments) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commentaires existants
                  if (_loadingComments)
                    Column(
                      children: List.generate(
                        2,
                        (index) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader(
                                width: AppImageSize.avatarSm,
                                height: AppImageSize.avatarSm,
                                isCircle: true,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: SkeletonLoader(
                                  width: double.infinity,
                                  height: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedAvatarImage(
                              imageUrl: comment['avatar'],
                              size: AppImageSize.avatarSm,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['author'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['text'],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: AppSpacing.md),
                  // Input nouveau commentaire
                  Row(
                    children: [
                      CachedAvatarImage(
                        size: AppImageSize.avatarSm,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            suffixIcon: _commentController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.send,
                                      size: 18,
                                      color: AppColors.primaryBlue,
                                    ),
                                    onPressed: () {
                                      // Envoyer le commentaire
                                      _commentController.clear();
                                    },
                                  )
                                : null,
                          ),
                          minLines: 1,
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
