import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? user;
  bool isLoading = true;
  bool isFollowing = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    currentUserId = await _authService.getUserId();
    final idToLoad = (widget.userId == null || widget.userId == '')
        ? currentUserId
        : widget.userId;
    if (idToLoad == null) {
      user = null;
    } else {
      user = await _userService.getUser(idToLoad);
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    if (isFollowing) {
      await _userService.unfollowUser(widget.userId!);
    } else {
      await _userService.followUser(widget.userId!);
    }
    setState(() => isFollowing = !isFollowing);
  }

  void navigateToProfile(String? userId) {
    if (userId == null) return;
    // use userId safely here
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header avec avatar
                  Container(
                    color: const Color(0xFF003366),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user?['avatarUrl'] != null
                              ? NetworkImage(user!['avatarUrl'])
                              : null,
                          backgroundColor: Colors.white12,
                          child: user?['avatarUrl'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?['nom'] ?? 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user?['faculty'] != null)
                          Text(
                            user!['faculty']['name'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard('Posts', user?['postsCount'] ?? 0),
                        _StatCard('Followers', user?['followersCount'] ?? 0),
                        _StatCard('Following', user?['followingCount'] ?? 0),
                      ],
                    ),
                  ),

                  // Bio
                  if (user?['bio'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user!['bio'],
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Filière et Niveau
                  if (user?['filiere'] != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${user!['filiere']} • ${user!['niveau'] ?? ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Action buttons
                  if (currentUserId != (widget.userId ?? currentUserId))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey
                                  : const Color(0xFF003366),
                            ),
                            child: Text(
                              isFollowing ? 'Ne plus suivre' : 'Suivre',
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                            ),
                            child: const Text('Envoyer message'),
                          ),
                        ],
                      ),
                    ),

                  if (currentUserId == (widget.userId ?? currentUserId))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          // Edit profile
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                        ),
                        child: const Text('Modifier le profil'),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;

  const _StatCard(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
