import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../main.dart' show apiUrl;
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  List<dynamic> _reports = [];
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (token == null) {
      setState(() {
        _error = 'Utilisateur non authentifie';
        _isLoading = false;
      });
      return;
    }

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$apiUrl/api/admin/dashboard'),
          headers: _headers(token),
        ),
        http.get(
          Uri.parse('$apiUrl/api/admin/posts?limit=20'),
          headers: _headers(token),
        ),
        http.get(
          Uri.parse('$apiUrl/api/admin/users?limit=20'),
          headers: _headers(token),
        ),
        http.get(
          Uri.parse('$apiUrl/api/admin/reports?limit=20'),
          headers: _headers(token),
        ),
      ]);

      final statsData = jsonDecode(responses[0].body);
      final postsData = jsonDecode(responses[1].body);
      final usersData = jsonDecode(responses[2].body);
      final reportsData = jsonDecode(responses[3].body);

      if (responses.any((response) => response.statusCode != 200)) {
        setState(() {
          _error =
              statsData['message'] ??
              postsData['message'] ??
              usersData['message'] ??
              reportsData['message'] ??
              'Chargement admin impossible';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _stats = statsData['stats'];
        _posts = postsData['posts'] ?? [];
        _users = usersData['users'] ?? [];
        _reports = reportsData['reports'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur reseau: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _toggleBlock(String userId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      return;
    }

    await http.patch(
      Uri.parse('$apiUrl/api/admin/users/$userId/block'),
      headers: _headers(token),
    );

    await _loadDashboard();
  }

  Future<void> _resolveReport(String reportId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      return;
    }

    await http.put(
      Uri.parse('$apiUrl/api/admin/reports/$reportId'),
      headers: _headers(token),
      body: jsonEncode({'status': 'resolved'}),
    );

    await _loadDashboard();
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer ce post ?'),
          content: const Text(
            'Cette action supprimera la publication du dashboard admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      return;
    }

    final response = await http.delete(
      Uri.parse('$apiUrl/api/admin/posts/$postId'),
      headers: _headers(token),
    );

    if (!mounted) {
      return;
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post supprime avec succes')),
      );
      await _loadDashboard();
      return;
    }

    final body = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          body['message']?.toString() ?? 'Suppression du post impossible',
        ),
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'Recemment';
    }

    try {
      final date = DateTime.parse(rawDate).toLocal();
      final delta = DateTime.now().difference(date);

      if (delta.inMinutes < 1) {
        return 'A l instant';
      }
      if (delta.inHours < 1) {
        return 'Il y a ${delta.inMinutes} min';
      }
      if (delta.inDays < 1) {
        return 'Il y a ${delta.inHours} h';
      }

      return 'Il y a ${delta.inDays} j';
    } catch (_) {
      return 'Recemment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1120;
                  final isTablet = constraints.maxWidth >= 760;

                  if (isWide) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroHeader(),
                          const SizedBox(height: 18),
                          _buildStatsSection(true),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildPostsSection()),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildUsersSection(),
                                    const SizedBox(height: 18),
                                    _buildReportsSection(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isTablet ? 18 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 16),
                        _buildStatsSection(false),
                        const SizedBox(height: 16),
                        _buildPostsSection(),
                        const SizedBox(height: 16),
                        _buildUsersSection(),
                        const SizedBox(height: 16),
                        _buildReportsSection(),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeroHeader() {
    final stats = _stats ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1E6BA1), Color(0xFF6AA7D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 16,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d administration',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Surveillance des comptes,\npublications et reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 220),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume rapide',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${stats['totalPosts'] ?? 0} posts a surveiller',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats['totalReports'] ?? 0} reports en attente',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isWide) {
    final stats = _stats ?? {};
    final items = [
      _StatCard(
        label: 'Utilisateurs',
        value: '${stats['totalUsers'] ?? 0}',
        icon: Icons.groups_2_outlined,
        accent: const Color(0xFF2563EB),
      ),
      _StatCard(
        label: 'Posts',
        value: '${stats['totalPosts'] ?? 0}',
        icon: Icons.article_outlined,
        accent: const Color(0xFF0F766E),
      ),
      _StatCard(
        label: 'Reports',
        value: '${stats['totalReports'] ?? 0}',
        icon: Icons.flag_outlined,
        accent: const Color(0xFFDC2626),
      ),
      _StatCard(
        label: 'Bloques',
        value: '${stats['blockedUsers'] ?? 0}',
        icon: Icons.block_outlined,
        accent: const Color(0xFF7C3AED),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: isWide ? 240 : 168, child: item))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPostsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Posts recents',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_posts.length} affiches',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Aucun post visible pour le moment'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final post = Map<String, dynamic>.from(_posts[index] as Map);
                  final user = Map<String, dynamic>.from(
                    post['user'] as Map? ?? const {},
                  );
                  final faculty = Map<String, dynamic>.from(
                    post['faculty'] as Map? ?? const {},
                  );
                  final mediaUrl = AppConfig.resolveUrl(
                    post['media']?.toString(),
                  );
                  final avatarUrl = AppConfig.resolveUrl(
                    user['avatar']?.toString(),
                  );
                  final pendingReportsCount =
                      post['pendingReportsCount'] as int? ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.grey[50],
                      border: Border.all(
                        color: post['isReported'] == true
                            ? const Color(0xFFFECACA)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name']?.toString() ?? 'Utilisateur',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                          faculty['name']?.toString(),
                                          _formatDate(
                                            post['createdAt']?.toString(),
                                          ),
                                        ]
                                        .whereType<String>()
                                        .where((e) => e.isNotEmpty)
                                        .join(' | '),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (pendingReportsCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$pendingReportsCount report(s)',
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post['content']?.toString().trim().isNotEmpty == true
                              ? post['content'].toString()
                              : 'Post sans texte',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        if (mediaUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              mediaUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  height: 120,
                                  alignment: Alignment.center,
                                  color: Colors.grey[200],
                                  child: const Text('Media indisponible'),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.favorite_border,
                              label: '${post['likesCount'] ?? 0} likes',
                            ),
                            _InfoChip(
                              icon: Icons.mode_comment_outlined,
                              label:
                                  '${post['commentsCount'] ?? 0} commentaires',
                            ),
                            if (faculty['name']?.toString().isNotEmpty == true)
                              _InfoChip(
                                icon: Icons.school_outlined,
                                label: faculty['name'].toString(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () =>
                                _deletePost(post['_id']?.toString() ?? ''),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Supprimer'),
                            style: FilledButton.styleFrom(
                              foregroundColor: const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilisateurs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_users.isEmpty)
              const Text('Aucun utilisateur charge')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final user = Map<String, dynamic>.from(_users[index] as Map);
                  final faculty = user['faculty'];
                  final facultyName = faculty is Map
                      ? faculty['name']?.toString() ?? ''
                      : faculty?.toString() ?? '';
                  final avatarUrl = AppConfig.resolveUrl(
                    user['avatar']?.toString(),
                  );

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['name'] ?? user['email'] ?? 'Utilisateur'),
                    subtitle: Text(
                      '${user['email']} | ${user['role']} | $facultyName',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () =>
                          _toggleBlock(user['_id']?.toString() ?? ''),
                      child: Text(
                        user['blocked'] == true ? 'Debloquer' : 'Bloquer',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_reports.isEmpty)
              const Text('Aucun report en cours')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reports.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final report = Map<String, dynamic>.from(
                    _reports[index] as Map,
                  );
                  final post = report['post'] as Map<String, dynamic>?;
                  final reportedBy =
                      report['reportedBy'] as Map<String, dynamic>? ?? {};

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(report['reason']?.toString() ?? 'Report'),
                    subtitle: Text(
                      '${post?['content'] ?? 'Contenu indisponible'}\nPar ${reportedBy['name'] ?? 'Utilisateur'}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () =>
                          _resolveReport(report['_id']?.toString() ?? ''),
                      child: const Text('Resoudre'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
