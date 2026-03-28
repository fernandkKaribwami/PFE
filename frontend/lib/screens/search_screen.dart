import 'package:flutter/material.dart';

import '../services/search_service.dart';
import '../theme/app_colors.dart';
import 'modern_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();

  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    final result = await _searchService.search(query);

    final users = (result['users'] as List? ?? []).map<Map<String, dynamic>>(
      (item) => {
        'type': 'user',
        'id': item['_id']?.toString(),
        'name': item['name'] ?? 'Utilisateur',
        'subtitle': item['faculty']?['name'] ?? item['email'] ?? '',
        'avatar': item['avatar'],
      },
    );
    final posts = (result['posts'] as List? ?? []).map<Map<String, dynamic>>(
      (item) => {
        'type': 'post',
        'id': item['_id']?.toString(),
        'userId': item['user']?['_id']?.toString(),
        'name': item['content'] ?? 'Post',
        'subtitle': 'Par ${item['user']?['name'] ?? 'Utilisateur'}',
        'avatar': item['user']?['avatar'],
      },
    );
    final groups = (result['groups'] as List? ?? []).map<Map<String, dynamic>>(
      (item) => {
        'type': 'group',
        'id': item['_id']?.toString(),
        'name': item['name'] ?? 'Groupe',
        'subtitle': item['description'] ?? '',
        'avatar': item['avatar'],
      },
    );
    final faculties =
        (result['faculties'] as List? ?? []).map<Map<String, dynamic>>(
      (item) => {
        'type': 'faculty',
        'id': item['_id']?.toString(),
        'name': item['name'] ?? 'Faculte',
        'subtitle': item['location'] ?? '',
        'avatar': item['image'],
      },
    );

    if (mounted) {
      setState(() {
        _searchResults = [...users, ...posts, ...groups, ...faculties];
        _isLoading = false;
      });
    }
  }

  void _openUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModernProfileScreen(userId: userId),
      ),
    );
  }

  void _handleSearchResultTap(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'user':
        _openUserProfile(result['id']?.toString());
        return;
      case 'post':
        _openUserProfile(result['userId']?.toString());
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Navigation non disponible pour ${result['type']} pour le moment',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher utilisateurs, posts, groupes...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _searchResults = [];
                });
              },
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            } else {
              setState(() {
                _searchQuery = '';
                _searchResults = [];
              });
            }
          },
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _searchQuery.isEmpty
          ? _buildSearchSuggestions()
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Rechercher dans USMBA Social',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisateurs, publications, groupes...',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun resultat trouve',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _handleSearchResultTap(result),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                _getIconForType(result['type']),
                color: AppColors.primary,
              ),
            ),
            title: Text(
              result['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(result['subtitle'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'user':
        return Icons.person;
      case 'post':
        return Icons.article;
      case 'group':
        return Icons.group;
      case 'faculty':
        return Icons.school;
      default:
        return Icons.search;
    }
  }
}
