// lib/community/provider/post_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/provider/bookmark_provider.dart';
import 'package:provider/provider.dart';

class Posts with ChangeNotifier {
  List<Post> _items = [];
  final supabaseClient = Supabase.instance.client;

  List<Post> get items {
    _items.sort((a, b) => b.datetime!.compareTo(a.datetime!));
    return [..._items];
  }

  Future<void> cleanupExpiredPosts() async {
    try {
      final currentDate = DateTime.now();

      // Fetch posts that have expired
      final response = await supabaseClient
          .from('posts')
          .select('id')
          .lt('expiration_date', currentDate.toIso8601String());

      if (response != null && response.isNotEmpty) {
        for (var post in response) {
          // Delete the expired post
          await deletePost(post['id']);
        }

        print("Deleted ${response.length} expired posts");
      }
    } catch (error) {
      print("Error cleaning up expired posts: $error");
    }
  }

  Future<void> addPost(Post post) async {
    final timeStamp = DateTime.now();
    String? userId = supabaseClient.auth.currentUser?.userMetadata?['Display name'] ??
        supabaseClient.auth.currentUser?.email ??
        supabaseClient.auth.currentUser?.id;

    // Calculate expiration date (7 days from now)
    final expirationDate = timeStamp.add(const Duration(days: 7));

    try {
      final response = await supabaseClient.from('posts').insert({
        'title': post.title,
        'content': post.content,
        'datetime': timeStamp.toIso8601String(),
        'imgURL': post.imgURL,
        'creatorId': userId,
        'likes': 0,
        'expiration_date': expirationDate.toIso8601String(), // Add expiration date
      }).select();

      // Get the inserted post with its ID
      if (response != null && response.isNotEmpty) {
        final newPostData = response[0];
        final newPost = Post(
          id: newPostData['id'],
          title: post.title,
          content: post.content,
          datetime: timeStamp,
          imgURL: post.imgURL,
          userId: userId,
          initialLikes: 0,
          expirationDate: expirationDate, // Include expiration date in post object
        );
        _items.add(newPost);
        notifyListeners();
      }
    } catch (error) {
      print("Error adding post: $error");
      rethrow;
    }
  }

  Future<void> fetchAndSetPosts() async {
    try {
      // Only fetch posts that haven't expired
      final currentDate = DateTime.now().toIso8601String();
      final response = await supabaseClient
          .from('posts')
          .select()
          .filter('expiration_date', 'gte', currentDate) // Only get non-expired posts
          .order('datetime', ascending: false);

      final data = response as List<dynamic>;
      final List<Post> loadedPosts = data.map((postData) {
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'],
          datetime: postData['datetime'] != null
              ? DateTime.parse(postData['datetime'])
              : null,
          imgURL: postData['imgURL'],
          userId: postData['creatorId'],
          initialLikes: postData['likes'],
          expirationDate: postData['expiration_date'] != null
              ? DateTime.parse(postData['expiration_date'])
              : null,
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching posts: $error");
      rethrow;
    }
  }

  Future<void> fetchAndSetPostsWithSearch(String searchText) async {
    try {
      // Only search non-expired posts
      final currentDate = DateTime.now().toIso8601String();
      final response = await supabaseClient
          .from('posts')
          .select()
          .or('title.ilike.%$searchText%,content.ilike.%$searchText%')
          .filter('expiration_date', 'gte', currentDate) // Only get non-expired posts
          .order('datetime', ascending: false);

      final data = response as List<dynamic>;
      final List<Post> loadedPosts = data.map((postData) {
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'],
          datetime: postData['datetime'] != null
              ? DateTime.parse(postData['datetime'])
              : null,
          imgURL: postData['imgURL'],
          userId: postData['creatorId'],
          initialLikes: postData['likes'],
          expirationDate: postData['expiration_date'] != null
              ? DateTime.parse(postData['expiration_date'])
              : null,
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching posts with search: $error");
      rethrow;
    }
  }

  Future<void> deletePost(dynamic id, {BuildContext? context}) async {
    if (id == null) return;

    // Handle if id is a String but can be parsed as int
    if (id is String && int.tryParse(id) != null) {
      id = int.parse(id);
    }

    // Find the post in our local list
    final existingPostIndex = _items.indexWhere((post) => post.id == id);

    if (existingPostIndex >= 0) {
      // Store the post temporarily in case we need to revert
      Post? existingPost = _items[existingPostIndex];

      // Remove from local list first for immediate UI update
      _items.removeAt(existingPostIndex);
      notifyListeners();

      try {
        // Also delete all related comments first to avoid foreign key constraints
        await supabaseClient.from('comments').delete().eq('postId', id);

        // Also delete all related likes
        await supabaseClient.from('likes').delete().eq('post_id', id);

        // Then delete the post from Supabase
        await supabaseClient.from('posts').delete().eq('id', id);

        // If context is provided, mark post as deleted in bookmarks
        if (context != null) {
          try {
            // Fixed: Get BookmarkProvider without using Provider.of directly
            // Instead, we'll let the calling code handle this part
            // This now simply indicates success to any bookmark providers
            print("Post $id successfully deleted - bookmarks should be updated separately");
          } catch (e) {
            print("Error updating bookmarks for deleted post: $e");
          }
        }

        print("Post $id successfully deleted with all related data");
      } catch (error) {
        // If deletion fails, add the post back to the list
        _items.insert(existingPostIndex, existingPost);
        notifyListeners();
        print("Error deleting post: $error");
        rethrow;
      }
    } else {
      print("Post with ID $id not found in local list");
    }
  }

  Future<void> fetchThreePosts() async {
    try {
      // Only fetch non-expired posts
      final currentDate = DateTime.now().toIso8601String();
      final _response = await supabaseClient
          .from('posts')
          .select()
          .filter('expiration_date', 'gte', currentDate) // Only get non-expired posts
          .order('datetime', ascending: false)
          .limit(5);

      final data = _response as List<dynamic>;

      final List<Post> loadedPosts = data.map((postData) {
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'] ?? postData['contents'],
          datetime: DateTime.parse(postData['datetime']),
          userId: postData['creatorId'],
          initialLikes: postData['likes'],
          expirationDate: postData['expiration_date'] != null
              ? DateTime.parse(postData['expiration_date'])
              : null,
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching three posts: $error");
      rethrow;
    }
  }

  // Check if a post has expired
  bool isPostExpired(Post post) {
    if (post.expirationDate == null) return false;
    return DateTime.now().isAfter(post.expirationDate!);
  }

  // Get days remaining until post expires
  int getDaysRemaining(Post post) {
    if (post.expirationDate == null) return 7; // Default to 7 days

    final now = DateTime.now();
    final difference = post.expirationDate!.difference(now);

    return difference.inDays < 0 ? 0 : difference.inDays;
  }
}