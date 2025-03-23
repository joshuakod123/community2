// lib/community/provider/compatibility.dart
// This file provides compatibility with the old provider structure
// while transitioning to the new providers

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';

// Legacy compatible PostList provider - wraps the new PostProvider
class PostList with ChangeNotifier {
  final SupabaseClient supabaseClient;
  final List<Post> _items = [];

  PostList(this.supabaseClient);

  List<Post> get items {
    return [..._items];
  }

  Future<void> fetchAndSetPosts() async {
    try {
      // Get current date for filtering expired posts
      final now = DateTime.now().toIso8601String();

      // Query posts that haven't expired yet
      final response = await supabaseClient
          .from('posts')
          .select()
          .gte('expiration_date', now)
          .order('is_pinned', ascending: false)
          .order('datetime', ascending: false);

      final List<Post> loadedPosts = [];

      for (final postData in response) {
        loadedPosts.add(Post.fromJson(postData));
      }

      _items.clear();
      _items.addAll(loadedPosts);

      notifyListeners();
    } catch (error) {
      print('Error fetching posts: $error');
      rethrow;
    }
  }
}

// Legacy compatible Posts provider - wraps the new PostProvider
class Posts with ChangeNotifier {
  final List<Post> _items = [];

  List<Post> get items {
    return [..._items];
  }

  // Get days remaining until expiration
  int getDaysRemaining(Post post) {
    if (post.expirationDate == null) return 7; // Default to 7 days

    final now = DateTime.now();
    final difference = post.expirationDate!.difference(now);

    return difference.inDays < 0 ? 0 : difference.inDays;
  }

  // Delete a post
  Future<void> deletePost(int postId) async {
    try {
      // Delete from Supabase
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', postId);

      // Remove from local list
      _items.removeWhere((post) => post.id == postId);

      notifyListeners();
    } catch (error) {
      print('Error deleting post: $error');
      rethrow;
    }
  }

  // Legacy cleanup methods
  void cleanupExpiredPosts() {
    // This is now handled by the fetchPosts method in PostProvider
  }

  void checkAndNotifyExpiringSoon() {
    // This is now handled by the NotificationProvider
  }
}

// Legacy compatible Comments provider
class Comments with ChangeNotifier {
  final List<dynamic> _items = [];

  List<dynamic> get items {
    return [..._items];
  }
}