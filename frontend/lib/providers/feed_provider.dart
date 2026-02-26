import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/post_service.dart';

final postServiceProvider = Provider((ref) => PostService());

// État pour le feed infini
class FeedState {
  final List<dynamic> posts;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  FeedState({
    this.posts = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<dynamic>? posts,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

// Provider pour le feed infini
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(ref.watch(postServiceProvider)),
);

class FeedNotifier extends StateNotifier<FeedState> {
  final PostService _postService;
  static const int _postsPerPage = 10;

  FeedNotifier(this._postService) : super(FeedState());

  // Charger la première page
  Future<void> initializeFeed() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _postService.getFeed(
        page: 1,
        limit: _postsPerPage,
      );

      state = FeedState(
        posts: posts,
        currentPage: 1,
        isLoading: false,
        hasMore: posts.length >= _postsPerPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }

  // Charger plus de posts (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final newPosts = await _postService.getFeed(
        page: nextPage,
        limit: _postsPerPage,
      );

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        currentPage: nextPage,
        isLoading: false,
        hasMore: newPosts.length >= _postsPerPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de chargement: $e',
      );
    }
  }

  // Rafraîchir le feed
  Future<void> refresh() {
    return initializeFeed();
  }

  // Like/Unlike un post
  Future<void> toggleLike(String postId) async {
    try {
      await _postService.likePost(postId);
      
      // Mettre à jour le state local
      final updatedPosts = state.posts.map((post) {
        if (post['_id'] == postId) {
          return {
            ...post,
            'isLiked': !(post['isLiked'] ?? false),
            'likesCount': (post['likesCount'] ?? 0) + (post['isLiked'] == true ? -1 : 1),
          };
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  // Sauvegarder un post
  Future<void> toggleSave(String postId) async {
    try {
      await _postService.savePost(postId);

      final updatedPosts = state.posts.map((post) {
        if (post['_id'] == postId) {
          return {
            ...post,
            'isSaved': !(post['isSaved'] ?? false),
          };
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  // Supprimer un post
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      
      final updatedPosts = state.posts
          .where((post) => post['_id'] != postId)
          .toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }
}

// Provider pour les posts d'un utilisateur spécifique
final userPostsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, userId) async {
  final postService = ref.watch(postServiceProvider);
  return postService.getUserPosts(userId);
});

// Cache pour les commentaires
final commentsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, postId) async {
  final postService = ref.watch(postServiceProvider);
  return postService.getComments(postId);
});
