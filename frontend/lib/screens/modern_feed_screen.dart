import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/faculty_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/notification_provider.dart';
import '../services/realtime_service.dart';
import '../services/story_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';
import '../widgets/faculty_selector.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/post_card.dart';
import '../widgets/post_comments_sheet.dart';
import '../widgets/post_share_sheet.dart';
import '../widgets/story_circle.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'story_viewer_screen.dart';

class ModernFeedScreen extends StatefulWidget {
  const ModernFeedScreen({super.key});

  @override
  State<ModernFeedScreen> createState() => _ModernFeedScreenState();
}

class _ModernFeedScreenState extends State<ModernFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final StoryService _storyService = StoryService();
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<Map<String, dynamic>>? _storySubscription;
  List<Map<String, dynamic>> _stories = [];
  bool _isStoriesLoading = false;
  bool _isCreatingStory = false;
  int _storyLoadVersion = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );

      facultyProvider.loadFaculties();

      final token = authProvider.token;
      if (feedProvider.posts.isEmpty && token != null && token.isNotEmpty) {
        feedProvider.loadFeed(token);
      }

      _loadStories();
    });

    _storySubscription = RealtimeService.instance.stories.listen(
      _handleStoryEvent,
    );
  }

  @override
  void dispose() {
    _storySubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!feedProvider.isLoadingMore &&
          feedProvider.hasMore &&
          token != null &&
          token.isNotEmpty) {
        feedProvider.loadMorePosts(token);
      }
    }
  }

  Future<void> _onRefresh(FacultyProvider facultyProvider) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      return;
    }

    await feedProvider.refreshFeed(
      token,
      facultyId: facultyProvider.selectedFacultyId,
    );
    await _loadStories();
  }

  Future<void> _loadStories() async {
    final requestVersion = ++_storyLoadVersion;
    setState(() {
      _isStoriesLoading = true;
    });

    final stories = await _storyService.getFeedStories();
    if (!mounted || requestVersion != _storyLoadVersion) {
      return;
    }

    setState(() {
      _stories = stories;
      _isStoriesLoading = false;
    });
  }

  void _handleStoryEvent(Map<String, dynamic> event) {
    if (!mounted) {
      return;
    }

    final storyId = event['_id']?.toString();
    if (storyId == null || storyId.isEmpty) {
      return;
    }

    setState(() {
      if (event['type'] == 'storyDeleted') {
        _stories.removeWhere((story) => story['_id']?.toString() == storyId);
        return;
      }

      final story = Map<String, dynamic>.from(event);
      final index = _stories.indexWhere(
        (item) => item['_id']?.toString() == storyId,
      );

      if (index == -1) {
        _stories.insert(0, story);
      } else {
        _stories[index] = story;
      }
    });
  }

  Future<void> _createStory() async {
    if (_isCreatingStory) {
      return;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedImage == null) {
      return;
    }

    setState(() {
      _isCreatingStory = true;
    });

    final bytes = await pickedImage.readAsBytes();
    final story = await _storyService.createStory(
      fileName: pickedImage.name,
      mediaPath: pickedImage.path,
      mediaBytes: bytes,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreatingStory = false;
      if (story != null) {
        _stories.removeWhere(
          (item) => item['_id']?.toString() == story['_id']?.toString(),
        );
        _stories.insert(0, story);
      }
    });

    if (story != null) {
      unawaited(_loadStories());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story publiee en temps reel')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La story a echoue. Veuillez reessayer.'),
        ),
      );
    }
  }

  Future<void> _openStory(Map<String, dynamic> story) async {
    final storyId = story['_id']?.toString();
    if (storyId == null || storyId.isEmpty) {
      return;
    }

    var openedStory = Map<String, dynamic>.from(story);
    if (openedStory['hasViewed'] != true) {
      final updatedStory = await _storyService.markViewed(storyId);
      if (updatedStory != null) {
        openedStory = updatedStory;
        if (mounted) {
          setState(() {
            final index = _stories.indexWhere(
              (item) => item['_id']?.toString() == storyId,
            );
            if (index != -1) {
              _stories[index] = updatedStory;
            }
          });
        }
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerScreen(story: openedStory)),
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
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              final unreadCount = notificationProvider.unreadCount;

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -5,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
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
                SliverToBoxAdapter(
                  child: FacultySelector(
                    onFacultyChanged: (facultyId) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final token = authProvider.token;
                      if (token == null || token.isEmpty) {
                        return;
                      }
                      feedProvider.loadFeed(token, facultyId: facultyId);
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _buildStoriesSection()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == feedProvider.posts.length) {
                        return feedProvider.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final post =
                          feedProvider.posts[index] as Map<String, dynamic>;
                      return PostCard(
                        post: post,
                        onLike: () =>
                            _handleLike(post['_id']?.toString() ?? ''),
                        onComment: () => _handleComment(post),
                        onShare: () => _handleShare(post),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user ?? const <String, dynamic>{};
    final currentAvatar = AppConfig.resolveUrl(
      currentUser['avatar']?.toString(),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 102,
        child: _isStoriesLoading && _stories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _stories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StoryCircle(
                      userName: _isCreatingStory
                          ? 'Publication...'
                          : 'Votre story',
                      avatarUrl: currentAvatar,
                      isAddStory: true,
                      onTap: _isCreatingStory ? null : _createStory,
                    );
                  }

                  final story = _stories[index - 1];
                  final user = story['user'] as Map<String, dynamic>? ?? {};

                  return StoryCircle(
                    userId: user['_id']?.toString(),
                    userName: user['name']?.toString() ?? 'Story',
                    avatarUrl: AppConfig.resolveUrl(user['avatar']?.toString()),
                    previewUrl: AppConfig.resolveUrl(
                      story['mediaUrl']?.toString(),
                    ),
                    isViewed: story['hasViewed'] == true,
                    onTap: () => _openStory(story),
                  );
                },
              ),
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
              final token = authProvider.token;
              if (token == null || token.isEmpty) {
                return;
              }
              feedProvider.loadFeed(token);
            },
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }

  void _handleLike(String postId) {
    if (postId.isEmpty) {
      return;
    }

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      return;
    }

    feedProvider.likePost(postId, token);
  }

  Future<void> _handleComment(Map<String, dynamic> post) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final postId = post['_id']?.toString() ?? '';

    if (postId.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentsSheet(
        postId: postId,
        onCommentAdded: token == null || token.isEmpty
            ? null
            : () => feedProvider.refreshFeed(
                token,
                facultyId: feedProvider.selectedFacultyId,
              ),
      ),
    );
  }

  Future<void> _handleShare(Map<String, dynamic> post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostShareSheet(post: post),
    );
  }
}
