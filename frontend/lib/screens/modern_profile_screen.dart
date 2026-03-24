import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  State<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.token != null) {
        userProvider.loadUserProfile(authProvider.token!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userProvider.currentUser;

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 300,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(user),
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                        Tab(icon: Icon(Icons.bookmark_border), text: 'Sauvegardé'),
                        Tab(icon: Icon(Icons.person_add), text: 'Abonnements'),
                      ],
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(),
                  _buildSavedTab(),
                  _buildFollowingTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.4),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: user?['avatar'] != null
                  ? NetworkImage(user!['avatar'])
                  : null,
              child: user?['avatar'] == null
                  ? Text(
                      user?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user?['name'] ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // Faculty
            Text(
              user?['faculty'] ?? 'Faculté non spécifiée',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat('Posts', '12'),
                _buildStat('Abonnés', '156'),
                _buildStat('Abonnements', '89'),
              ],
            ),

            const SizedBox(height: 16),

            // Bio
            if (user?['bio'] != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  user!['bio'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Edit profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Modifier profil'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Settings
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Icon(Icons.settings),
                ),
              ],
            ),
          ],
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 12, // Mock data
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.white),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return const Center(
      child: Text('Posts sauvegardés'),
    );
  }

  Widget _buildFollowingTab() {
    return const Center(
      child: Text('Abonnements'),
    );
  }
}
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentUserProvider);
    final isFollowing = widget.userId != null
        ? ref.watch(isFollowingProvider(widget.userId!))
        : false;

    if (profileState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonLoader(
                width: 80,
                height: 80,
                isCircle: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              SkeletonLoader(width: 200, height: 20),
              const SizedBox(height: AppSpacing.md),
              SkeletonLoader(width: 150, height: 16),
            ],
          ),
        ),
      );
    }

    if (profileState.userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Profil non trouvé',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final user = profileState.userData!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec image de couverture
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de couverture
                  Container(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    child: Image.network(
                      user['coverImage'] ??
                          'https://picsum.photos/seed/cover/600/300',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryBlue,
                        );
                      },
                    ),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu du profil
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar et infos de base
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(0, -60),
                          child: CachedAvatarImage(
                            imageUrl: user['avatar'],
                            size: 120,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Nom et filière
                      Text(
                        '${user['nom'] ?? ''} ${user['prenom'] ?? ''}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (user['filiere'] != null)
                        Text(
                          user['filiere'],
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      // Bio
                      if (user['bio'] != null)
                        Text(
                          user['bio'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // Stats (followers, following, posts)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            context,
                            label: 'Posts',
                            count: user['postsCount'] ?? 0,
                          ),
                          _buildStatCard(
                            context,
                            label: 'Followers',
                            count: profileState.followers.length,
                          ),
                          _buildStatCard(
                            context,
                            label: 'Following',
                            count: profileState.following.length,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (isFollowing) {
                                  ref
                                      .read(currentUserProvider.notifier)
                                      .unfollowUser(widget.userId!);
                                  NotificationUtils.showInfoSnackBar(
                                    context,
                                    'Vous ne suivez plus cet utilisateur',
                                  );
                                } else {
                                  ref
                                      .read(currentUserProvider.notifier)
                                      .followUser(widget.userId!);
                                  NotificationUtils.showSuccessSnackBar(
                                    context,
                                    'Vous suivez maintenant cet utilisateur',
                                  );
                                }
                              },
                              icon: Icon(
                                isFollowing ? Icons.person_remove : Icons.person_add,
                              ),
                              label: Text(
                                isFollowing
                                    ? 'Ne pas suivre'
                                    : 'Suivre',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                NotificationUtils.showInfoSnackBar(
                                  context,
                                  'Message envoyé',
                                );
                              },
                              icon: const Icon(Icons.message_outlined),
                              label: const Text('Message'),
                            ),
                          ),
                        ],
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

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Média'),
                    Tab(text: 'Likes'),
                  ],
                ),
              ],
            ),
          ),

          // Contenu des tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts
                _buildPostsTab(context),

                // Média
                _buildMediaTab(context),

                // Likes
                _buildLikesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de statistique
  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Tab Posts
  Widget _buildPostsTab(BuildContext context) {
    if (widget.userId == null) {
      return Center(
        child: Text(
          'Aucun post',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final userPosts =
            ref.watch(userPostsProvider(widget.userId!));

        return userPosts.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Text(
                  'Aucun post',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['text'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${post['likesCount'] ?? 0} likes • ${post['commentsCount'] ?? 0} commentaires',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Text('Erreur: $err'),
          ),
        );
      },
    );
  }

  /// Tab Média
  Widget _buildMediaTab(BuildContext context) {
    return Center(
      child: Text(
        'Galerie média',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// Tab Likes
  Widget _buildLikesTab(BuildContext context) {
    return Center(
      child: Text(
        'Posts aimés',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
