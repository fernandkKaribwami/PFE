import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/search_service.dart';
import '../utils/app_config.dart';

class PostShareSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostShareSheet({super.key, required this.post});

  @override
  State<PostShareSheet> createState() => _PostShareSheetState();
}

class _PostShareSheetState extends State<PostShareSheet> {
  final ChatService _chatService = ChatService();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSending = false;
  List<Map<String, dynamic>> _conversationUsers = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.getConversations();
    if (!mounted) {
      return;
    }

    setState(() {
      _conversationUsers = conversations
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) {
            final conversation = Map<String, dynamic>.from(item);
            final user = Map<String, dynamic>.from(
              conversation['user'] as Map? ?? const {},
            );
            final lastMessage = Map<String, dynamic>.from(
              conversation['lastMessage'] as Map? ?? const {},
            );

            return {
              '_id': user['_id']?.toString() ?? '',
              'name': user['name'] ?? 'Utilisateur',
              'avatar': user['avatar'] ?? '',
              'subtitle': lastMessage['content']?.toString() ?? '',
            };
          })
          .where((user) => (user['_id'] ?? '').toString().isNotEmpty)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _searchPeople(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final result = await _searchService.search(query);
    if (!mounted) {
      return;
    }

    final users = (result['users'] as List? ?? [])
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => {
            '_id': item['_id']?.toString() ?? '',
            'name': item['name'] ?? 'Utilisateur',
            'avatar': item['avatar'] ?? '',
            'subtitle': item['faculty']?['name'] ?? item['email'] ?? '',
          },
        )
        .toList();

    setState(() {
      _searchResults = users;
      _isSearching = false;
    });
  }

  Future<void> _shareWithUser(Map<String, dynamic> user) async {
    final userId = user['_id']?.toString();
    if (userId == null || userId.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final sendResult = await _chatService.sendMessage(
      userId,
      text: _buildShareMessage(),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    if (!sendResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendResult.error ?? 'Partage impossible pour le moment',
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Publication partagee avec ${user['name'] ?? 'cet utilisateur'}',
        ),
      ),
    );
  }

  String _buildShareMessage() {
    final author = widget.post['user'] as Map<String, dynamic>? ?? {};
    final authorName = author['name']?.toString() ?? 'Utilisateur';
    final content = widget.post['content']?.toString().trim() ?? '';
    final mediaUrl = AppConfig.resolveUrl(widget.post['media']?.toString());

    final buffer = StringBuffer('Publication partagee par $authorName');
    if (content.isNotEmpty) {
      buffer.write('\n\n$content');
    }
    if (mediaUrl.isNotEmpty) {
      buffer.write('\n\n$mediaUrl');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final List<Map<String, dynamic>> usersToDisplay =
        _searchController.text.trim().isEmpty
        ? _conversationUsers
        : _searchResults;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partager la publication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.post['content']?.toString().trim().isNotEmpty ==
                                true
                            ? widget.post['content'].toString()
                            : 'Publication avec media',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: _searchPeople,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Choisir une personne',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : usersToDisplay.isEmpty
                    ? const Center(
                        child: Text('Aucune personne trouvee pour le partage'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final user = usersToDisplay[index];
                          final avatarUrl = AppConfig.resolveUrl(
                            user['avatar']?.toString(),
                          );

                          return ListTile(
                            onTap: _isSending
                                ? null
                                : () => _shareWithUser(user),
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
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
                            title: Text(
                              user['name']?.toString() ?? 'Utilisateur',
                            ),
                            subtitle: Text(
                              user['subtitle']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: usersToDisplay.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
