import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../utils/app_config.dart';

class PostCommentsSheet extends StatefulWidget {
  final String postId;
  final Future<void> Function()? onCommentAdded;

  const PostCommentsSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await _postService.getComments(widget.postId);
    if (!mounted) {
      return;
    }

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    if (_isSubmitting || _commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await _postService.commentPost(
      widget.postId,
      _commentController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d envoyer le commentaire')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    _commentController.clear();
    await _loadComments();
    final onCommentAdded = widget.onCommentAdded;
    if (onCommentAdded != null) {
      await onCommentAdded();
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: screenHeight * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Commentaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? const Center(
                        child: Text('Aucun commentaire pour le moment'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final comment =
                              _comments[index] as Map<String, dynamic>;
                          final user =
                              comment['user'] as Map<String, dynamic>? ?? {};
                          final avatarUrl = AppConfig.resolveUrl(
                            user['avatar']?.toString(),
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        (user['name']?.toString().isNotEmpty ??
                                                false)
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
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name']?.toString() ??
                                            'Utilisateur',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment['content']?.toString() ?? ''),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(
                                          comment['createdAt']?.toString(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: _comments.length,
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitComment,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'À l instant';
    }

    try {
      final date = DateTime.parse(rawDate).toLocal();
      final difference = DateTime.now().difference(date);

      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays} j';
      }
      if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours} h';
      }
      if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'À l instant';
    } catch (_) {
      return 'À l instant';
    }
  }
}
