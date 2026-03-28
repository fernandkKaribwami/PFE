import 'package:flutter/material.dart';

import '../services/search_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final UserService _userService = UserService();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await _userService.getMessageContacts();
    if (!mounted) {
      return;
    }

    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _searchUsers(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final result = await _searchService.search(trimmedQuery);
    if (!mounted) {
      return;
    }

    final users = (result['users'] as List? ?? [])
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => {
            '_id': item['_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Utilisateur',
            'avatar': item['avatar']?.toString() ?? '',
            'subtitle': item['faculty']?['name']?.toString() ?? '',
          },
        )
        .where((user) => user['_id']!.isNotEmpty)
        .toList();

    setState(() {
      _searchResults = users;
      _isSearching = false;
    });
  }

  List<Map<String, dynamic>> _visibleUsers() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contacts;
    }

    final localMatches = _contacts.where((contact) {
      final name = contact['name']?.toString().toLowerCase() ?? '';
      final subtitle = contact['subtitle']?.toString().toLowerCase() ?? '';
      return name.contains(query) || subtitle.contains(query);
    });

    final merged = <String, Map<String, dynamic>>{};
    for (final user in [...localMatches, ..._searchResults]) {
      final userId = user['_id']?.toString();
      if (userId == null || userId.isEmpty) {
        continue;
      }
      merged[userId] = user;
    }

    return merged.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _visibleUsers();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Choisir un ami ou rechercher un utilisateur',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadContacts,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 72,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Aucun ami ou contact disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Suis quelqu un ou utilise la recherche pour lancer une nouvelle conversation.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadContacts,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final avatarUrl = AppConfig.resolveUrl(
                          user['avatar']?.toString(),
                        );

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context, user),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? Text(
                                            (user['name']
                                                        ?.toString()
                                                        .isNotEmpty ??
                                                    false)
                                                ? user['name']
                                                      .toString()
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name']?.toString() ??
                                              'Utilisateur',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user['subtitle']
                                                      ?.toString()
                                                      .isNotEmpty ==
                                                  true
                                              ? user['subtitle'].toString()
                                              : 'Pret pour une nouvelle conversation',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
