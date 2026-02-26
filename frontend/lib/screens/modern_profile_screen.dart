import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/base_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/extensions.dart';
import '../utils/notification_utils.dart';

/// Écran Profil Moderne avec Riverpod
/// Démontre:
/// - Chargement de données avec FutureProvider
/// - Gestion du suivre/ne pas suivre
/// - Affichage des posts de l'utilisateur
/// - Animations fluides
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger le profil utilisateur
    if (widget.userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(currentUserProvider.notifier)
            .loadUserProfile(widget.userId!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
