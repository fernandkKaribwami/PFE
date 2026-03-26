import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../main.dart' show apiUrl;

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token =
        authProvider.token; // cette valeur est récupérée depuis provider

    if (token == null) {
      setState(() {
        _error = 'Utilisateur non authentifié';
        _isLoading = false;
      });
      return;
    }

    try {
      final statsResp = await http.get(
        Uri.parse('$apiUrl/api/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (statsResp.statusCode != 200) {
        setState(() {
          _error = 'Erreur chargement statistiques';
          _isLoading = false;
        });
        return;
      }
      _stats = jsonDecode(statsResp.body);

      final usersResp = await http.get(
        Uri.parse('$apiUrl/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (usersResp.statusCode != 200) {
        setState(() {
          _error = 'Erreur chargement utilisateurs';
          _isLoading = false;
        });
        return;
      }
      _users = jsonDecode(usersResp.body);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau: $e';
        _isLoading = false;
      });
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_stats != null) ...[
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                'Utilisateurs',
                                _stats!['totalUsers']?.toString() ?? '0',
                              ),
                              _statItem(
                                'Posts',
                                _stats!['totalPosts']?.toString() ?? '0',
                              ),
                              _statItem(
                                'Reports',
                                _stats!['totalReports']?.toString() ?? '0',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Utilisateurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user['avatar'] != null &&
                                    user['avatar'].toString().isNotEmpty
                                ? NetworkImage(user['avatar'])
                                : null,
                            child:
                                user['avatar'] == null ||
                                    user['avatar'].toString().isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            user['name'] ?? user['email'] ?? 'Utilisateur',
                          ),
                          subtitle: Text('${user['email']} • ${user['role']}'),
                          trailing: Text(user['faculty']?.toString() ?? ''),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
