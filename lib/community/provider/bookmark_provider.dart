// lib/community/provider/bookmark_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bookmark.dart';
import '../models/post.dart';

class BookmarkProvider with ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  final _supabase = Supabase.instance.client;
  static const String _bookmarksStorageKey = 'user_bookmarks';

  List<Bookmark> get bookmarks {
    return [..._bookmarks];
  }

  bool isBookmarked(dynamic postId) {
    if (postId == null) return false;

    String postIdStr = postId.toString();
    return _bookmarks.any((bookmark) =>
    bookmark.postId.toString() == postIdStr &&
        bookmark.isDeleted == false);
  }

  // Fetch bookmarks from both Supabase and local storage
  Future<void> fetchBookmarks() async {
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // First, check if the bookmarks table exists and create it if needed
      try {
        print("Checking if bookmarks table exists");

        // Try a simple query to see if table exists
        await _supabase.from('bookmarks').select('id').limit(1);
        print("Bookmarks table exists");
      } catch (e) {
        if (e.toString().contains(
            'relation "public.bookmarks" does not exist')) {
          print("Bookmarks table doesn't exist - using local storage only");
          // Just continue with local storage
        } else {
          print("Unexpected error checking bookmarks table: $e");
        }
      }

      // Fetch from Supabase first with error handling
      List<Bookmark> serverBookmarks = [];
      try {
        print("Fetching bookmarks from server for user ID: $userId");

        final response = await _supabase
            .from('bookmarks')
            .select()
            .eq('userId', userId);

        if (response != null && response is List) {
          print("Received ${response.length} bookmarks from server");

          serverBookmarks = response.map((item) =>
              Bookmark(
                id: item['id'],
                postId: item['postId'],
                userId: item['userId'],
                savedAt: item['savedAt'] != null ? DateTime.parse(
                    item['savedAt']) : null,
                isDeleted: item['isDeleted'] ?? false,
              )).toList();
        }
      } catch (e) {
        print('Error fetching bookmarks from server: $e');
        // Continue with local bookmarks if server fetch fails
      }

      // Then fetch locally saved bookmarks
      final prefs = await SharedPreferences.getInstance();
      final String? storedBookmarks = prefs.getString(_bookmarksStorageKey);

      print("Checking local storage for bookmarks");

      List<Bookmark> localBookmarks = [];
      if (storedBookmarks != null && storedBookmarks.isNotEmpty) {
        try {
          print("Found bookmarks in local storage: $storedBookmarks");

          final List<dynamic> decodedData = json.decode(storedBookmarks);
          localBookmarks = decodedData
              .map((item) => Bookmark.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          print("Parsed ${localBookmarks.length} bookmarks from local storage");
        } catch (e) {
          print('Error decoding stored bookmarks: $e');
        }
      }

      // Merge server and local bookmarks, prioritizing server data
      final Map<String, Bookmark> mergedBookmarks = {};

      // Add all local bookmarks first
      for (var bookmark in localBookmarks) {
        if (bookmark.postId != null) {
          mergedBookmarks[bookmark.postId.toString()] = bookmark;
        }
      }

      // Override with server bookmarks when available
      for (var bookmark in serverBookmarks) {
        if (bookmark.postId != null) {
          mergedBookmarks[bookmark.postId.toString()] = bookmark;
        }
      }

      _bookmarks = mergedBookmarks.values.toList();
      notifyListeners();

      print("Final merged bookmarks count: ${_bookmarks.length}");

      // Save the merged list back to local storage
      await _saveBookmarksLocally();
    } catch (error) {
      print('Error fetching bookmarks: $error');
    }
  }

  // Add a bookmark with proper error handling
  Future<void> addBookmark(Post post) async {
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Check if already bookmarked
    if (isBookmarked(post.id)) {
      print('Post is already bookmarked');
      return;
    }

    final now = DateTime.now();
    int? bookmarkId;

    try {
      // First add to Supabase with error handling
      try {
        print("Adding bookmark to server: Post ID ${post.id}");

        final response = await _supabase.from('bookmarks').insert({
          'postId': post.id,
          'userId': userId,
          'savedAt': now.toIso8601String(),
          'isDeleted': false,
        }).select();

        if (response != null && response is List && response.isNotEmpty) {
          bookmarkId = response[0]['id'];
          print("Successfully added bookmark to server with ID: $bookmarkId");
        }
      } catch (e) {
        print('Error adding bookmark to server: $e');
        // Continue with local storage even if server fails
      }

      // Create bookmark object with post data for local storage
      final newBookmark = Bookmark(
        id: bookmarkId,
        postId: post.id,
        userId: userId,
        savedAt: now,
        isDeleted: false,
        localPostData: json.encode({
          'id': post.id,
          'title': post.title,
          'content': post.content,
          'datetime': post.datetime?.toIso8601String(),
          'imgURL': post.imgURL,
          'userId': post.userId,
          'initialLikes': post.initialLikes,
          'expirationDate': post.expirationDate?.toIso8601String(),
        }),
      );

      _bookmarks.add(newBookmark);
      notifyListeners();

      // Save updated bookmarks to local storage
      await _saveBookmarksLocally();

      print("Bookmark added and saved locally: Post ID ${post.id}");
    } catch (error) {
      print('Error adding bookmark: $error');
    }
  }

  // Remove a bookmark with proper error handling
  Future<void> removeBookmark(dynamic postId) async {
    if (postId == null) return;

    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    String postIdStr = postId.toString();
    final index = _bookmarks.indexWhere((bookmark) =>
    bookmark.postId.toString() == postIdStr);

    if (index < 0) return;

    try {
      // Remove from Supabase if bookmark has ID
      if (_bookmarks[index].id != null) {
        try {
          print("Removing bookmark from server: ID ${_bookmarks[index].id}");

          await _supabase
              .from('bookmarks')
              .delete()
              .eq('id', _bookmarks[index].id);

          print("Successfully removed bookmark from server");
        } catch (e) {
          print('Error removing bookmark from server: $e');
          // Continue with local removal even if server fails
        }
      }

      // Remove from local list
      _bookmarks.removeAt(index);
      notifyListeners();

      // Save updated bookmarks to local storage
      await _saveBookmarksLocally();

      print("Bookmark removed and local storage updated: Post ID $postId");
    } catch (error) {
      print('Error removing bookmark: $error');
    }
  }

  // Mark a bookmark as referring to a deleted post
  Future<void> markAsDeleted(dynamic postId) async {
    if (postId == null) return;

    String postIdStr = postId.toString();
    final index = _bookmarks.indexWhere((bookmark) =>
    bookmark.postId.toString() == postIdStr);

    if (index < 0) return;

    try {
      // Update in Supabase if bookmark has ID
      if (_bookmarks[index].id != null) {
        try {
          print("Marking bookmark as deleted on server: ID ${_bookmarks[index]
              .id}");

          await _supabase
              .from('bookmarks')
              .update({'isDeleted': true})
              .eq('id', _bookmarks[index].id);

          print("Successfully marked bookmark as deleted on server");
        } catch (e) {
          print('Error updating bookmark on server: $e');
          // Continue with local update even if server fails
        }
      }

      // Update local bookmark
      final updatedBookmark = Bookmark(
        id: _bookmarks[index].id,
        postId: _bookmarks[index].postId,
        userId: _bookmarks[index].userId,
        savedAt: _bookmarks[index].savedAt,
        isDeleted: true,
        localPostData: _bookmarks[index].localPostData,
      );

      _bookmarks[index] = updatedBookmark;
      notifyListeners();

      // Save updated bookmarks to local storage
      await _saveBookmarksLocally();

      print("Bookmark marked as deleted locally: Post ID $postId");
    } catch (error) {
      print('Error marking bookmark as deleted: $error');
    }
  }

  // Save bookmarks to local storage with proper error handling
  Future<void> _saveBookmarksLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(_bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_bookmarksStorageKey, jsonData);
      print("Saved ${_bookmarks.length} bookmarks to local storage");
    } catch (error) {
      print('Error saving bookmarks locally: $error');
    }
  }

  // Get a bookmarked post (either from server or local storage)
  Future<Post?> getBookmarkedPost(dynamic postId) async {
    if (postId == null) return null;

    // First check if post exists in bookmarks
    String postIdStr = postId.toString();
    final bookmarkIndex = _bookmarks.indexWhere((b) =>
    b.postId.toString() == postIdStr);

    if (bookmarkIndex < 0) {
      return null; // No bookmark found
    }

    final bookmark = _bookmarks[bookmarkIndex];

    // If bookmark is marked as deleted but we have local data, still show it
    if (bookmark.isDeleted && bookmark.localPostData != null) {
      try {
        print("Loading deleted post from local data: Post ID $postId");

        final postData = json.decode(bookmark.localPostData!);
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'],
          datetime: postData['datetime'] != null ? DateTime.parse(
              postData['datetime']) : null,
          imgURL: postData['imgURL'],
          userId: postData['userId'],
          initialLikes: postData['initialLikes'],
          expirationDate: postData['expirationDate'] != null
              ? DateTime.parse(postData['expirationDate'])
              : null,
        );
      } catch (e) {
        print('Error parsing local post data for deleted post: $e');
        return null;
      }
    }

    try {
      // Try to fetch from server first
      print("Attempting to fetch post from server: ID $postId");

      final response = await _supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (response != null) {
        // Post exists on server
        print("Post found on server: ID $postId");

        return Post(
          id: response['id'],
          title: response['title'],
          content: response['content'],
          datetime: response['datetime'] != null ? DateTime.parse(
              response['datetime']) : null,
          imgURL: response['imgURL'],
          userId: response['creatorId'],
          initialLikes: response['likes'],
          expirationDate: response['expiration_date'] != null
              ? DateTime.parse(response['expiration_date'])
              : null,
        );
      } else if (bookmark.localPostData != null) {
        // Post doesn't exist on server, but we have local data
        print("Post not found on server, using local data: Post ID $postId");

        try {
          final postData = json.decode(bookmark.localPostData!);
          return Post(
            id: postData['id'],
            title: postData['title'],
            content: postData['content'],
            datetime: postData['datetime'] != null ? DateTime.parse(
                postData['datetime']) : null,
            imgURL: postData['imgURL'],
            userId: postData['userId'],
            initialLikes: postData['initialLikes'],
            expirationDate: postData['expirationDate'] != null
                ? DateTime.parse(postData['expirationDate'])
                : null,
          );
        } catch (e) {
          print('Error parsing local post data: $e');
          return null;
        }
      }
    } catch (error) {
      print('Error getting bookmarked post from server: $error');
      // If server fetch fails but we have local data
      if (bookmark.localPostData != null) {
        try {
          print("Using local data as fallback due to server error");

          final postData = json.decode(bookmark.localPostData!);
          return Post(
            id: postData['id'],
            title: postData['title'],
            content: postData['content'],
            datetime: postData['datetime'] != null ? DateTime.parse(
                postData['datetime']) : null,
            imgURL: postData['imgURL'],
            userId: postData['userId'],
            initialLikes: postData['initialLikes'],
            expirationDate: postData['expirationDate'] != null
                ? DateTime.parse(postData['expirationDate'])
                : null,
          );
        } catch (e) {
          print('Error parsing local post data in catch block: $e');
          return null;
        }
      }
    }
  }
}
