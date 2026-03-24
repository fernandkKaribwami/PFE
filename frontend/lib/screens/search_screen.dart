import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    // Simulate search
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
        // Mock search results
        _searchResults = [
          {
            'type': 'user',
            'name': 'John Doe',
            'subtitle': 'Faculté des Sciences',
            'avatar': null,
          },
          {
            'type': 'post',
            'name': 'Comment créer une app Flutter',
            'subtitle': 'Par Jane Smith',
            'avatar': null,
          },
          {
            'type': 'group',
            'name': 'Club Informatique',
            'subtitle': '15 membres',
            'avatar': null,
          },
        ].where((item) =>
            item['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            item['subtitle'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    });
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
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
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
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                _getIconForType(result['type']),
                color: AppColors.primary,
              ),
            ),
            title: Text(
              result['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(result['subtitle']),
            onTap: () {
              // Navigate to detail page based on type
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ouverture de ${result['name']}')),
              );
            },
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
      default:
        return Icons.search;
    }
  }
}