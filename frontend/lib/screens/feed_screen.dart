import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class FeedScreen extends StatefulWidget {
  final String token;
  const FeedScreen({super.key, required this.token});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  late ScrollController _scrollController;

  static final List<Map<String, dynamic>> _samplePosts = [
    {
      '_id': 'sample1',
      'author': {
        'nom': 'USMBA News',
        'avatarUrl': 'https://picsum.photos/seed/usmba1/200/200',
        'faculty': {'name': 'Faculté des Sciences Dhar El Mahraz'},
      },
      'text':
          'Bienvenue sur USMBA Social! Voici quelques posts d\'exemple pour commencer.',
      'mediaUrl': 'https://picsum.photos/seed/post1/800/400',
      'likesCount': 12,
      'commentsCount': 3,
    },
    {
      '_id': 'sample2',
      'author': {
        'nom': 'Clubs USMBA',
        'avatarUrl': 'https://picsum.photos/seed/usmba2/200/200',
        'faculty': {'name': 'Club Culturel'},
      },
      'text': 'Rejoignez le club de photographie — réunion ce jeudi!',
      'mediaUrl': null,
      'likesCount': 8,
      'commentsCount': 1,
    },
    {
      '_id': 'sample3',
      'author': {
        'nom': 'Étudiant·e',
        'avatarUrl': 'https://picsum.photos/seed/usmba3/200/200',
        'faculty': {'name': 'Faculté des Lettres'},
      },
      'text': 'Bon courage pour les examens!',
      'mediaUrl': 'https://picsum.photos/seed/post2/800/400',
      'likesCount': 20,
      'commentsCount': 5,
    },
  ];

  List<dynamic> posts = [];
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMore = true;
  int selectedIndex = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    userId = await _authService.getUserId();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => isLoadingMore = true);
    final newPosts = await _postService.getFeed(page: currentPage, limit: 10);

    if (mounted) {
      setState(() {
        if (currentPage == 1) {
          posts = newPosts;
          // If backend returned no posts (fresh install), seed with sample posts
          if (posts.isEmpty) {
            posts = List<Map<String, dynamic>>.from(_samplePosts);
          }
        } else {
          posts.addAll(newPosts);
        }
        isLoadingMore = false;
        hasMore = newPosts.length == 10;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!isLoadingMore && hasMore) {
        setState(() => currentPage++);
        _loadPosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    setState(() => selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ).then((_) {
          setState(() => selectedIndex = 0);
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(
              onPostCreated: () {
                setState(() {
                  currentPage = 1;
                  _loadPosts();
                });
              },
            ),
          ),
        ).then((_) {
          setState(() => selectedIndex = 0);
        });
        break;
      case 3:
        // Notifications
        setState(() => selectedIndex = 0);
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
        ).then((_) {
          setState(() => selectedIndex = 0);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USMBA Social'),
        elevation: 0,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => currentPage = 1);
          await _loadPosts();
        },
        child: posts.isEmpty
            ? Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator()
                    : const Text('Aucun post pour l\'instant'),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: posts.length + (isLoadingMore && hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final post = posts[index];
                  return PostCard(
                    post: post,
                    onLike: () {
                      _postService.likePost(post['_id']);
                      setState(() {});
                    },
                    onComment: (text) {
                      _postService.commentPost(post['_id'], text);
                      setState(() {});
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _handleTabChange,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF003366),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final Function(String) onComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late TextEditingController _commentController;
  bool showComments = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post['author'] ?? {};

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: author['avatarUrl'] != null
                  ? NetworkImage(author['avatarUrl'])
                  : null,
              child: author['avatarUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(author['nom'] ?? 'Utilisateur'),
            subtitle: Text(
              author['faculty']?['name'] ?? 'Faculté inconnue',
              maxLines: 1,
            ),
          ),
          if (post['text'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post['text']),
            ),
          if (post['mediaUrl'] != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                post['mediaUrl'],
                errorBuilder: (_, __, _) => const SizedBox(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${post['likesCount'] ?? 0} j\'aime'),
                Text('${post['commentsCount'] ?? 0} commentaires'),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: Icons.favorite_border,
                  label: 'J\'aime',
                  onPressed: widget.onLike,
                ),
                _ActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Commenter',
                  onPressed: () => setState(() => showComments = !showComments),
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: Icons.bookmark_outline,
                  label: 'Enregistrer',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (showComments)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        widget.onComment(_commentController.text);
                        _commentController.clear();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
