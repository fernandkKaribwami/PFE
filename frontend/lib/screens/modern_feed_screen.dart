import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle.dart';
import '../widgets/loading_shimmer.dart';
import '../theme/app_colors.dart';

class ModernFeedScreen extends StatefulWidget {
  const ModernFeedScreen({super.key});

  @override
  State<ModernFeedScreen> createState() => _ModernFeedScreenState();
}

class _ModernFeedScreenState extends State<ModernFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load feed if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (feedProvider.posts.isEmpty && authProvider.token != null) {
        feedProvider.loadFeed(authProvider.token!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!feedProvider.isLoadingMore && feedProvider.hasMore && authProvider.token != null) {
        feedProvider.loadMorePosts(authProvider.token!);
      }
    }
  }

  Future<void> _onRefresh() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isRefreshing = true);

    await feedProvider.refreshFeed(authProvider.token!);

    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'USMBA Social',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              // TODO: Navigate to messages
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
            return const LoadingShimmer();
          }

          if (feedProvider.error != null && feedProvider.posts.isEmpty) {
            return _buildErrorState(feedProvider);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Stories Section
                SliverToBoxAdapter(
                  child: _buildStoriesSection(),
                ),

                // Posts Section
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == feedProvider.posts.length) {
                        // Loading indicator at the end
                        return feedProvider.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final post = feedProvider.posts[index];
                      return PostCard(
                        post: post,
                        onLike: () => _handleLike(post['_id']),
                        onComment: () => _handleComment(post['_id']),
                        onShare: () => _handleShare(post['_id']),
                      );
                    },
                    childCount: feedProvider.posts.length + (feedProvider.isLoadingMore ? 1 : 0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10, // Mock stories count
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 12),
            child: StoryCircle(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(FeedProvider feedProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            feedProvider.error ?? 'Une erreur est survenue',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              feedProvider.loadFeed(authProvider.token!);
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _handleLike(String postId) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    feedProvider.likePost(postId, authProvider.token!);
  }

  void _handleComment(String postId) {
    // TODO: Navigate to comments screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commentaires pour le post $postId')),
    );
  }

  void _handleShare(String postId) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partage du post $postId')),
    );
  }
}

  /// Détecter quand on approche du bas de la liste
  void _onScroll() {
    final remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;

    if (remaining < 500) {
      // Charger plus de posts
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('USMBA Social'),
        elevation: 0,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
              NotificationUtils.showInfoSnackBar(
                context,
                isDark ? 'Mode clair activé' : 'Mode sombre activé',
              );
            },
          ),

          // Notifications
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Naviguer vers les notifications
                },
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                NotificationUtils.showConfirmDialog(
                  context,
                  title: 'Déconnexion',
                  message: 'Êtes-vous sûr?',
                ).then((confirmed) {
                  if (confirmed == true) {
                    // Déconnexion
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: AppSpacing.md),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: AppSpacing.md),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: feedState.posts.isEmpty && !feedState.isLoading
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                itemCount: feedState.posts.length +
                    (feedState.isLoading && feedState.hasMore ? 1 : 0) +
                    (feedState.posts.isNotEmpty ? 1 : 0), // +1 für stories
                itemBuilder: (context, index) {
                  // Stories horizontales en haut
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _buildStoriesSection(),
                    );
                  }

                  final postIndex = index - 1;

                  // Loading indicator à la fin
                  if (postIndex == feedState.posts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Chargement...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  final post = feedState.posts[postIndex];

                  return Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    child: PostCard(
                      postId: post['_id'] ?? 'unknown',
                      authorId: post['author']['_id'] ?? '',
                      authorName: post['author']['nom'] ?? 'Unknown',
                      authorAvatarUrl: post['author']['avatar'],
                      faculty: post['faculty']?['name'] ?? 'USMBA',
                      content: post['text'] ?? '',
                      mediaUrl: post['mediaUrl'],
                      createdAt: DateTime.tryParse(
                            post['createdAt'] ?? '',
                          ) ??
                          DateTime.now(),
                      likesCount: post['likesCount'] ?? 0,
                      commentsCount: post['commentsCount'] ?? 0,
                      isLiked: post['isLiked'] ?? false,
                      isSaved: post['isSaved'] ?? false,
                      onLike: () {
                        ref
                            .read(feedProvider.notifier)
                            .toggleLike(post['_id']);
                      },
                      onComment: () {
                        NotificationUtils.showInfoSnackBar(
                          context,
                          'Fonctionnalité en développement',
                        );
                      },
                      onSave: () {
                        ref
                            .read(feedProvider.notifier)
                            .toggleSave(post['_id']);
                        NotificationUtils.showSuccessSnackBar(
                          context,
                          post['isSaved'] == true
                              ? 'Post retiré des enregistrements'
                              : 'Post enregistré',
                        );
                      },
                      onMore: () {
                        _showPostMenu(context, post['_id']);
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers créer un post
          NotificationUtils.showInfoSnackBar(
            context,
            'Créer un nouveau post',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Widget des stories
  Widget _buildStoriesSection() {
    return StoriesHorizontalList(
      stories: [
        {
          'userId': '1',
          'userName': 'Ahmed Ali',
          'avatarUrl': 'https://picsum.photos/seed/user1/100/100',
          'isViewed': false,
        },
        {
          'userId': '2',
          'userName': 'Fatima Ben',
          'avatarUrl': 'https://picsum.photos/seed/user2/100/100',
          'isViewed': true,
        },
        {
          'userId': '3',
          'userName': 'Mohammed Said',
          'avatarUrl': 'https://picsum.photos/seed/user3/100/100',
          'isViewed': false,
        },
        {
          'userId': '4',
          'userName': 'Amira Karim',
          'avatarUrl': 'https://picsum.photos/seed/user4/100/100',
          'isViewed': false,
        },
      ],
      onStoryTap: (userId) {
        if (userId == 'add_story') {
          NotificationUtils.showInfoSnackBar(
            context,
            'Ajouter une story',
          );
        } else {
          NotificationUtils.showInfoSnackBar(
            context,
            'Voir la story de $userId',
          );
        }
      },
      showAddYourStory: true,
    );
  }

  /// État vide
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun post disponible',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(feedProvider.notifier).initializeFeed(),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  /// Menu post
  void _showPostMenu(BuildContext context, String postId) {
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                NotificationUtils.showInfoSnackBar(
                  context,
                  'Post signalé',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                NotificationUtils.showDeleteConfirmDialog(context)
                    .then((confirmed) {
                  if (confirmed == true) {
                    ref
                        .read(feedProvider.notifier)
                        .deletePost(postId);
                    NotificationUtils.showSuccessSnackBar(
                      context,
                      'Post supprimé',
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
