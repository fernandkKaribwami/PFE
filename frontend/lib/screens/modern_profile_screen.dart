import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/post_service.dart';
import '../services/realtime_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';
import '../widgets/post_card.dart';
import '../widgets/post_comments_sheet.dart';
import '../widgets/post_share_sheet.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

class ModernProfileScreen extends StatefulWidget {
  final String? userId;

  const ModernProfileScreen({super.key, this.userId});

  @override
  State<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  Map<String, dynamic>? _externalUser;
  List<Map<String, dynamic>> _profilePosts = [];
  bool _isExternalLoading = false;
  bool _isActionLoading = false;
  bool _isPostsLoading = false;
  String? _externalError;
  String? _postsError;

  bool get _hasExternalUserId =>
      widget.userId != null && widget.userId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });

    _profileSubscription = RealtimeService.instance.profileUpdates.listen((
      profile,
    ) {
      if (!_hasExternalUserId || widget.userId == null || !mounted) {
        return;
      }

      final updatedUserId = profile['_id']?.toString();
      if (updatedUserId != widget.userId) {
        return;
      }

      setState(() {
        _externalUser = profile;
      });
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        authProvider.user?['_id']?.toString() ??
        authProvider.user?['id']?.toString();

    if (_hasExternalUserId && widget.userId != currentUserId) {
      await _loadExternalProfile();
      return;
    }

    final token = authProvider.token;
    if (token != null && token.isNotEmpty) {
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserProfile(token);
    }

    if (currentUserId != null && currentUserId.isNotEmpty) {
      await _loadPostsForUser(currentUserId);
    }
  }

  Future<void> _loadExternalProfile() async {
    if (!_hasExternalUserId) {
      return;
    }

    setState(() {
      _isExternalLoading = true;
      _externalError = null;
    });

    try {
      final user = await _userService.getUser(widget.userId!);
      if (!mounted) {
        return;
      }

      setState(() {
        _externalUser = user;
        _externalError = user == null ? 'Profil utilisateur introuvable' : null;
        _isExternalLoading = false;
      });

      if (user != null) {
        await _loadPostsForUser(widget.userId!);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _externalError = 'Erreur reseau: $e';
        _isExternalLoading = false;
      });
    }
  }

  Future<void> _loadPostsForUser(String userId) async {
    setState(() {
      _isPostsLoading = true;
      _postsError = null;
    });

    try {
      final posts = await _postService.getUserPosts(userId, limit: 30);
      if (!mounted) {
        return;
      }

      setState(() {
        _profilePosts = posts
            .whereType<Map>()
            .map((post) => Map<String, dynamic>.from(post))
            .toList();
        _isPostsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _postsError = 'Chargement des posts impossible';
        _isPostsLoading = false;
      });
    }
  }

  bool _isOwnProfile(AuthProvider authProvider, Map<String, dynamic>? user) {
    if (!_hasExternalUserId) {
      return true;
    }

    final currentUserId =
        authProvider.user?['_id']?.toString() ??
        authProvider.user?['id']?.toString();
    final viewedUserId =
        widget.userId?.toString() ??
        user?['_id']?.toString() ??
        user?['id']?.toString();

    return currentUserId != null && currentUserId == viewedUserId;
  }

  String? _viewedUserId(AuthProvider authProvider, Map<String, dynamic>? user) {
    if (_hasExternalUserId && widget.userId != null) {
      return widget.userId;
    }

    return user?['_id']?.toString() ??
        authProvider.user?['_id']?.toString() ??
        authProvider.user?['id']?.toString();
  }

  Future<void> _refreshPostsForCurrentView() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final viewedId = _viewedUserId(
      authProvider,
      _hasExternalUserId ? _externalUser : userProvider.currentUser,
    );

    if (viewedId != null && viewedId.isNotEmpty) {
      await _loadPostsForUser(viewedId);
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic>? user) async {
    if (!_hasExternalUserId || _isActionLoading) {
      return;
    }

    final isFollowing = user?['isFollowing'] == true;

    setState(() {
      _isActionLoading = true;
    });

    final success = isFollowing
        ? await _userService.unfollowUser(widget.userId!)
        : await _userService.followUser(widget.userId!);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing
                ? 'Impossible de retirer cet abonnement'
                : 'Impossible de suivre cet utilisateur',
          ),
        ),
      );
      setState(() {
        _isActionLoading = false;
      });
      return;
    }

    await _loadExternalProfile();

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _toggleLikeForPost(String postId) async {
    if (postId.isEmpty) {
      return;
    }

    final updatedPost = await _postService.toggleLikePost(postId);
    if (!mounted || updatedPost == null) {
      return;
    }

    final index = _profilePosts.indexWhere((post) => post['_id'] == postId);
    if (index == -1) {
      return;
    }

    setState(() {
      _profilePosts[index] = updatedPost;
    });
  }

  Future<void> _showCommentsForPost(String postId) async {
    if (postId.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentsSheet(
        postId: postId,
        onCommentAdded: _refreshPostsForCurrentView,
      ),
    );
  }

  Future<void> _showShareForPost(Map<String, dynamic> post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostShareSheet(post: post),
    );
  }

  void _openChat() {
    if (!_hasExternalUserId) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(userId: widget.userId!),
      ),
    );
  }

  Future<void> _showOwnProfileOptions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.role == 'admin';

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Dashboard admin'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/admin');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Deconnexion'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );

    if (updated == true && mounted) {
      await _loadProfile();
    }
  }

  void _openProfile(String? userId) {
    if (userId == null || userId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModernProfileScreen(userId: userId)),
    );
  }

  double _expandedHeightFor(
    BuildContext context,
    Map<String, dynamic>? user,
    bool isOwnProfile,
  ) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final bio = user?['bio']?.toString() ?? '';
    final hasBio = bio.trim().isNotEmpty;

    if (isOwnProfile) {
      if (compact) {
        return hasBio ? 620 : 570;
      }
      return hasBio ? 560 : 510;
    }

    if (compact) {
      return hasBio ? 600 : 550;
    }
    return hasBio ? 540 : 500;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final ownProfile = _isOwnProfile(
          authProvider,
          _hasExternalUserId ? _externalUser : userProvider.currentUser,
        );
        final isLoading = ownProfile
            ? userProvider.isLoading
            : _isExternalLoading;
        final error = ownProfile ? userProvider.error : _externalError;
        final user = ownProfile ? userProvider.currentUser : _externalUser;

        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (error != null && user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: Center(child: Text(error)),
          );
        }

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Profil utilisateur indisponible')),
          );
        }

        final tabs = ownProfile
            ? const [
                Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
                Tab(icon: Icon(Icons.bookmark_outline), text: 'Sauvegarde'),
                Tab(icon: Icon(Icons.people_outline), text: 'Abonnements'),
              ]
            : const [
                Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
                Tab(icon: Icon(Icons.favorite_border), text: 'Abonnes'),
                Tab(icon: Icon(Icons.people_outline), text: 'Abonnements'),
              ];

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: _expandedHeightFor(context, user, ownProfile),
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: !ownProfile,
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _buildProfileHeader(user, ownProfile),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: MediaQuery.of(context).size.width < 420,
                    tabs: tabs,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: ownProfile
                  ? [
                      _buildPostsTabContent(),
                      _buildSavedTab(),
                      _buildUserListTab(
                        user['following'] as List? ?? const [],
                        'Aucun abonnement',
                      ),
                    ]
                  : [
                      _buildPostsTabContent(),
                      _buildUserListTab(
                        user['followers'] as List? ?? const [],
                        'Aucun abonne',
                      ),
                      _buildUserListTab(
                        user['following'] as List? ?? const [],
                        'Aucun abonnement',
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user, bool isOwnProfile) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final avatar = AppConfig.resolveUrl(user['avatar']?.toString());
    final bio = user['bio']?.toString() ?? '';
    final faculty = user['faculty'];
    final facultyName = faculty is Map ? faculty['name'] : faculty?.toString();
    final postsCount = user['postsCount']?.toString() ?? '0';
    final followersCount = user['followersCount']?.toString() ?? '0';
    final followingCount = user['followingCount']?.toString() ?? '0';
    final isFollowing = user['isFollowing'] == true;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.96),
            AppColors.primary.withValues(alpha: 0.78),
            AppColors.primary.withValues(alpha: 0.52),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, compact ? 18 : 24, 24, 92),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: compact ? 42 : 54,
                backgroundColor: Colors.white,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(
                        (user['name']?.toString().isNotEmpty ?? false)
                            ? user['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: compact ? 28 : 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: compact ? 14 : 18),
              Text(
                user['name']?.toString() ?? 'Utilisateur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                facultyName ?? 'Faculte non specifiee',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _buildStat('Posts', postsCount),
                  _buildStat('Abonnes', followersCount),
                  _buildStat('Abonnements', followingCount),
                ],
              ),
              if (bio.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: isOwnProfile
                    ? [
                        ElevatedButton.icon(
                          onPressed: () => _openEditProfile(user),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Modifier profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showOwnProfileOptions,
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Parametres'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ]
                    : [
                        ElevatedButton.icon(
                          onPressed: _isActionLoading
                              ? null
                              : () => _toggleFollow(user),
                          icon: Icon(
                            isFollowing
                                ? Icons.person_remove_outlined
                                : Icons.person_add_alt_1,
                          ),
                          label: Text(
                            _isActionLoading
                                ? 'Chargement...'
                                : isFollowing
                                ? 'Ne plus suivre'
                                : 'Suivre',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTabContent() {
    if (_isPostsLoading && _profilePosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsError != null && _profilePosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_postsError!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshPostsForCurrentView,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_profilePosts.isEmpty) {
      return const Center(child: Text('Aucun post publie'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 96),
      itemBuilder: (context, index) {
        final post = _profilePosts[index];
        final postId = post['_id']?.toString() ?? '';

        return PostCard(
          post: post,
          onLike: () => _toggleLikeForPost(postId),
          onComment: () => _showCommentsForPost(postId),
          onShare: () => _showShareForPost(post),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemCount: _profilePosts.length,
    );
  }

  Widget _buildSavedTab() {
    return const Center(child: Text('Posts sauvegardes a brancher'));
  }

  Widget _buildUserListTab(List<dynamic> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final listedUser = users[index] as Map<String, dynamic>;
        final faculty = listedUser['faculty'];
        final facultyName = faculty is Map
            ? faculty['name']
            : faculty?.toString() ?? '';
        final userId =
            listedUser['_id']?.toString() ?? listedUser['id']?.toString();
        final avatar = AppConfig.resolveUrl(listedUser['avatar']?.toString());

        return ListTile(
          onTap: () => _openProfile(userId),
          leading: CircleAvatar(
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(listedUser['name'] ?? 'Utilisateur'),
          subtitle: Text(facultyName),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}
