import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/faculty_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/faculty_selector.dart';
import '../theme/app_colors.dart';

class ModernFeedScreen extends StatefulWidget {
  const ModernFeedScreen({super.key});

  @override
  State<ModernFeedScreen> createState() => _ModernFeedScreenState();
}

class _ModernFeedScreenState extends State<ModernFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load feed and faculties if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );

      // Load faculties
      facultyProvider.loadFaculties();

      // Load initial feed
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
      if (!feedProvider.isLoadingMore &&
          feedProvider.hasMore &&
          authProvider.token != null) {
        feedProvider.loadMorePosts(authProvider.token!);
      }
    }
  }

  Future<void> _onRefresh(FacultyProvider facultyProvider) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await feedProvider.refreshFeed(
      authProvider.token!,
      facultyId: facultyProvider.selectedFacultyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'USMBA Social',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
      body: Consumer2<FeedProvider, FacultyProvider>(
        builder: (context, feedProvider, facultyProvider, child) {
          if (feedProvider.isLoading && feedProvider.posts.isEmpty) {
            return const LoadingShimmer();
          }

          if (feedProvider.error != null && feedProvider.posts.isEmpty) {
            return _buildErrorState(feedProvider);
          }

          return RefreshIndicator(
            onRefresh: () => _onRefresh(facultyProvider),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Faculty Selector
                SliverToBoxAdapter(
                  child: FacultySelector(
                    onFacultyChanged: (facultyId) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      feedProvider.loadFeed(
                        authProvider.token!,
                        facultyId: facultyId,
                      );
                    },
                  ),
                ),

                // Stories Section
                SliverToBoxAdapter(child: _buildStoriesSection()),

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
                    childCount:
                        feedProvider.posts.length +
                        (feedProvider.isLoadingMore ? 1 : 0),
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
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StoryCircle(userName: 'User ${index + 1}'),
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
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Partage du post $postId')));
  }
}
