// lib/community/provider/post_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/provider/bookmark_provider.dart';
import 'package:experiment3/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Posts with ChangeNotifier {
  List<Post> _items = [];
  final supabaseClient = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  List<Post> get items {
    _items.sort((a, b) => b.datetime!.compareTo(a.datetime!));
    return [..._items];
  }

  Future<void> cleanupExpiredPosts() async {
    try {
      final currentDate = DateTime.now();
      final formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);

      print("Checking for expired posts. Current date: $formattedCurrentDate");

      // First, try to clean up expired posts on the server
      try {
        final response = await supabaseClient
            .from('posts')
            .delete()
            .lt('expiration_date', currentDate.toIso8601String())
            .select();

        print("Server cleanup response: $response");
      } catch (e) {
        print("Server-side cleanup error (continuing with local cleanup): $e");
      }

      // Then handle local cleanup
      List<Post> expiredPosts = [];
      List<Post> validPosts = [];

      // Identify expired posts
      for (var post in _items) {
        if (post.expirationDate != null && post.expirationDate!.isBefore(currentDate)) {
          print("Found expired post ID: ${post.id}, expired on: ${post.expirationDate}");
          expiredPosts.add(post);
        } else {
          validPosts.add(post);
        }
      }

      // If we have expired posts, update our local list
      if (expiredPosts.isNotEmpty) {
        print("Removing ${expiredPosts.length} expired posts from local list");
        _items = validPosts;
        notifyListeners();

        // Also attempt to delete them from the server individually
        for (var post in expiredPosts) {
          try {
            // Use explicit type conversion for the ID
            var postId = post.id;
            await supabaseClient.from('posts').delete().eq('id', postId);
            print("Deleted expired post ID: $postId");
          } catch (e) {
            print("Error deleting expired post ${post.id}: $e");
          }
        }
      } else {
        print("No expired posts found in local list");
      }
    } catch (error) {
      print("Error cleaning up expired posts: $error");
    }
  }

  // Check for posts about to expire and notify users
  Future<void> checkAndNotifyExpiringSoon() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));

      // Find posts expiring within next 24 hours where the current user is the creator
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) return;

      for (var post in _items) {
        // Use strict equality check for userId (string comparison)
        final postUserId = post.userId?.toString() ?? "";
        final currentUserIdStr = currentUserId.toString();

        if (postUserId == currentUserIdStr &&
            post.expirationDate != null &&
            post.expirationDate!.isAfter(now) &&
            post.expirationDate!.isBefore(tomorrow)) {

          print("Found post expiring soon. Post ID: ${post.id}, Title: ${post.title}");

          // Send local notification
          await _notificationService.showLocalNotification(
            title: 'Post Expiring Soon',
            body: 'Your post "${post.title}" will expire in ${_getRemainingTimeText(post.expirationDate!)}',
            channelId: 'community_channel',
          );
        }
      }
    } catch (error) {
      print("Error checking for expiring posts: $error");
    }
  }

  String _getRemainingTimeText(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    if (difference.inHours < 1) {
      return "${difference.inMinutes} minutes";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours";
    } else {
      return "${difference.inDays} days";
    }
  }

  Future<void> addPost(Post post) async {
    final timeStamp = DateTime.now();
    String? userId = supabaseClient.auth.currentUser?.id ?? "";

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

        // Show confirmation to user about post expiration
        _notificationService.showLocalNotification(
          title: 'Post Created',
          body: 'Your post will be available for 7 days (until ${expirationDate.toString().substring(0, 10)})',
          channelId: 'community_channel',
        );
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
      print("Fetching posts that haven't expired yet (current date: $currentDate)");

      final response = await supabaseClient
          .from('posts')
          .select()
          .filter('expiration_date', 'gte', currentDate) // Only get non-expired posts
          .order('datetime', ascending: false);

      final data = response as List<dynamic>;
      print("Fetched ${data.length} non-expired posts");

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
          initialLikes: postData['initialLikes'] ?? postData['likes'],
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

    // Find the post in our local list - supporting both int and string IDs
    final existingPostIndex = _items.indexWhere((post) =>
    post.id.toString() == id.toString());

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
            final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
            await bookmarkProvider.markAsDeleted(id);
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

  // Get days remaining until post expires
  int getDaysRemaining(Post post) {
    if (post.expirationDate == null) return 7; // Default to 7 days

    final now = DateTime.now();
    final difference = post.expirationDate!.difference(now);

    return difference.inDays < 0 ? 0 : difference.inDays;
  }

  // Get hours remaining until post expires
  int getHoursRemaining(Post post) {
    if (post.expirationDate == null) return 168; // Default to 7 days (168 hours)

    final now = DateTime.now();
    final difference = post.expirationDate!.difference(now);

    return difference.inHours < 0 ? 0 : difference.inHours;
  }
}