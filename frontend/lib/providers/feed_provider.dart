import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class FeedProvider with ChangeNotifier {
  List<dynamic> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  static const int _postsPerPage = 10;

  List<dynamic> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadFeed(String token) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$API_URL/api/posts?page=1&limit=$_postsPerPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _posts = data['posts'] ?? [];
        _currentPage = 1;
        _hasMore = _posts.length >= _postsPerPage;
        _error = null;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Failed to load feed';
      }
    } catch (e) {
      _error = 'Network error: $e';
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
      final response = await http.get(
        Uri.parse('$API_URL/api/posts?page=$nextPage&limit=$_postsPerPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newPosts = data['posts'] ?? [];

        if (newPosts.isNotEmpty) {
          _posts.addAll(newPosts);
          _currentPage = nextPage;
          _hasMore = newPosts.length >= _postsPerPage;
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

  Future<void> refreshFeed(String token) async {
    _currentPage = 1;
    _hasMore = true;
    await loadFeed(token);
  }

  Future<void> likePost(String postId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/api/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update the post in the list
        final postIndex = _posts.indexWhere((post) => post['_id'] == postId);
        if (postIndex != -1) {
          final updatedPost = Map<String, dynamic>.from(_posts[postIndex]);
          final isLiked = updatedPost['isLiked'] ?? false;
          updatedPost['isLiked'] = !isLiked;
          updatedPost['likesCount'] =
              (updatedPost['likesCount'] ?? 0) + (isLiked ? -1 : 1);
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
