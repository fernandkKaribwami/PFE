import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart' show apiUrl;

class FeedProvider with ChangeNotifier {
  List<dynamic> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _selectedFacultyId;
  static const int _postsPerPage = 10;

  List<dynamic> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get selectedFacultyId => _selectedFacultyId;

  Future<void> loadFeed(String token, {String? facultyId}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _selectedFacultyId = facultyId;
    _currentPage = 1;
    notifyListeners();

    try {
      String url = '$apiUrl/api/posts?page=1&limit=$_postsPerPage';
      if (facultyId != null && facultyId.isNotEmpty) {
        url += '&faculty=$facultyId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _posts = data['posts'] ?? [];
        _currentPage = 1;
        final pagination = data['pagination'] ?? {};
        _hasMore = pagination['hasMore'] ?? (_posts.length >= _postsPerPage);
        _error = null;
      } else {
        _error = data['message'] ?? 'Chargement du feed impossible';
      }
    } catch (e) {
      _error = 'Erreur reseau: $e';
      debugPrint('Error loading feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts(String token) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      String url = '$apiUrl/api/posts?page=$nextPage&limit=$_postsPerPage';
      if (_selectedFacultyId != null && _selectedFacultyId!.isNotEmpty) {
        url += '&faculty=$_selectedFacultyId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final newPosts = data['posts'] ?? [];
        final pagination = data['pagination'] ?? {};

        if (newPosts.isNotEmpty) {
          _posts.addAll(newPosts);
          _currentPage = nextPage;
          _hasMore = pagination['hasMore'] ?? (newPosts.length >= _postsPerPage);
        } else {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeed(String token, {String? facultyId}) async {
    _currentPage = 1;
    _hasMore = true;
    await loadFeed(token, facultyId: facultyId);
  }

  Future<void> likePost(String postId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedPost = data['post'];
        final postIndex = _posts.indexWhere((post) => post['_id'] == postId);
        if (postIndex != -1 && updatedPost != null) {
          _posts[postIndex] = updatedPost;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
    }
  }

  Future<void> addNewPost(dynamic newPost) async {
    _posts.insert(0, newPost);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
