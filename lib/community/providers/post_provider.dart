// lib/community/providers/post_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostProvider with ChangeNotifier {
  final List<Post> _posts = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => [..._posts];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all posts
  Future<void> fetchPosts() async {
    try {
      _isLoading = true;
      _errorMessage = null;

      // Get current date for filtering expired posts
      final now = DateTime.now().toIso8601String();

      // Query posts that haven't expired yet
      final response = await _supabase
          .from('posts')
          .select()
          .gte('expiration_date', now)
          .order('is_pinned', ascending: false)
          .order('datetime', ascending: false);

      final List<Post> loadedPosts = [];

      for (final postData in response) {
        loadedPosts.add(Post.fromJson(postData));
      }

      _posts.clear();
      _posts.addAll(loadedPosts);

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error fetching posts: $error');
    }
  }

  // Fetch posts with search
  Future<void> searchPosts(String searchTerm) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('posts')
          .select()
          .or('title.ilike.%$searchTerm%,content.ilike.%$searchTerm%')
          .gte('expiration_date', now)
          .order('datetime', ascending: false);

      final List<Post> searchResults = [];
      for (final postData in response) {
        searchResults.add(Post.fromJson(postData));
      }

      _posts.clear();
      _posts.addAll(searchResults);

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error searching posts: $error');
    }
  }

  // Fetch a single post by id
  Future<Post?> fetchPostById(int postId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (response != null) {
        return Post.fromJson(response);
      }
      return null;
    } catch (error) {
      print('Error fetching post by id: $error');
      return null;
    }
  }

  // Add a new post - FIXED VERSION
  Future<Post?> addPost(Post post) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to create a post");
      }

      // Calculate expiration date (7 days from now)
      final expirationDate = DateTime.now().add(const Duration(days: 7));

      // Prepare post data with the creator_id explicitly set
      final postData = {
        'title': post.title,
        'content': post.content,
        'img_url': post.imgUrl,
        'expiration_date': expirationDate.toIso8601String(),
        'category': post.category,
        'creator_id': currentUser.id,
        'datetime': DateTime.now().toIso8601String(),
        'likes': 0,
        'is_pinned': false,
      };

      // Insert the post
      final response = await _supabase
          .from('posts')
          .insert(postData)
          .select();

      if (response != null && response.isNotEmpty) {
        final newPost = Post.fromJson(response[0]);
        _posts.insert(0, newPost);

        _isLoading = false;
        notifyListeners();
        return newPost;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error adding post: $error');
      return null;
    }
  }

  // Update a post
  Future<bool> updatePost(Post post) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (post.id == null) return false;

      // Get current user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to update a post");
      }

      // First check if the user is the creator of the post
      final existingPost = await _supabase
          .from('posts')
          .select('creator_id')
          .eq('id', post.id as Object)
          .single();

      if (existingPost['creator_id'] != currentUser.id) {
        throw Exception("You can only update your own posts");
      }

      await _supabase
          .from('posts')
          .update({
        'title': post.title,
        'content': post.content,
        'img_url': post.imgUrl,
        'is_pinned': post.isPinned,
        'category': post.category,
      })
          .eq('id', post.id as Object);

      // Update local list
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index >= 0) {
        _posts[index] = post;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error updating post: $error');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(int postId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to delete a post");
      }

      // First check if the user is the creator of the post
      final existingPost = await _supabase
          .from('posts')
          .select('creator_id')
          .eq('id', postId)
          .single();

      if (existingPost['creator_id'] != currentUser.id) {
        throw Exception("You can only delete your own posts");
      }

      // Delete from Supabase
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId);

      // Remove from local list
      _posts.removeWhere((post) => post.id == postId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error deleting post: $error');
      return false;
    }
  }

  // Like a post
  Future<bool> likePost(int postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already liked
      final existingLike = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) return false; // Already liked

      // Add like
      await _supabase
          .from('likes')
          .insert({
        'post_id': postId,
        'user_id': userId,
      });

      // Update local post
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index >= 0) {
        _posts[index] = _posts[index].copyWith(
            likesCount: _posts[index].likesCount + 1
        );
        notifyListeners();
      }

      return true;
    } catch (error) {
      print('Error liking post: $error');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(int postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Delete like
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      // Update local post
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index >= 0 && _posts[index].likesCount > 0) {
        _posts[index] = _posts[index].copyWith(
            likesCount: _posts[index].likesCount - 1
        );
        notifyListeners();
      }

      return true;
    } catch (error) {
      print('Error unliking post: $error');
      return false;
    }
  }

  // Check if post is liked by current user
  Future<bool> isPostLiked(int postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      print('Error checking if post is liked: $error');
      return false;
    }
  }

  // Extend post expiration date
  Future<bool> extendPostExpiration(int postId) async {
    try {
      // Get current user ID
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to extend a post's expiration");
      }

      // First check if the user is the creator of the post
      final postResponse = await _supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (postResponse == null) return false;
      final post = Post.fromJson(postResponse);

      if (post.creatorId != currentUser.id) {
        throw Exception("You can only extend your own posts");
      }

      // Calculate new expiration date (current expiration + 7 days or now + 7 days)
      final currentExpiration = post.expirationDate ?? DateTime.now();
      final newExpiration = currentExpiration.add(const Duration(days: 7));

      // Update the expiration date
      await _supabase
          .from('posts')
          .update({
        'expiration_date': newExpiration.toIso8601String(),
      })
          .eq('id', postId);

      // Update local post if in list
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index >= 0) {
        _posts[index] = _posts[index].copyWith(
            expirationDate: newExpiration
        );
        notifyListeners();
      }

      return true;
    } catch (error) {
      print('Error extending post expiration: $error');
      return false;
    }
  }

  // Get days remaining until expiration
  int getDaysRemaining(Post post) {
    if (post.expirationDate == null) return 7; // Default to 7 days

    final now = DateTime.now();
    final difference = post.expirationDate!.difference(now);

    return difference.inDays < 0 ? 0 : difference.inDays;
  }
}