// lib/community/providers/bookmark_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/post.dart';

class BookmarkProvider with ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;
  static const String _bookmarksStorageKey = 'user_bookmarks';

  List<Bookmark> get bookmarks => [..._bookmarks];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if a post is bookmarked
  bool isBookmarked(int postId) {
    return _bookmarks.any((bookmark) =>
    bookmark.postId == postId &&
        bookmark.isDeleted == false);
  }

  // Fetch bookmarks from both Supabase and local storage
  Future<void> fetchBookmarks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final String? userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        _errorMessage = "User not authenticated";
        notifyListeners();
        return;
      }

      // Fetch from Supabase
      List<Bookmark> serverBookmarks = [];
      try {
        final response = await _supabase
            .from('bookmarks')
            .select()
            .eq('user_id', userId);

        if (response != null && response is List) {
          serverBookmarks = response.map((item) {
            // Add null checks for id and post_id to handle potential null values
            return Bookmark(
              id: item['id'] != null ? item['id'] : null,
              postId: item['post_id'] != null ? item['post_id'] : -1, // Use a default value (-1) for postId if null
              userId: item['user_id'] ?? '',
              savedAt: item['saved_at'] != null ? DateTime.parse(item['saved_at']) : null,
              isDeleted: item['is_deleted'] ?? false,
            );
          }).toList();
        }
      } catch (e) {
        print('Error fetching bookmarks from server: $e');
        // Continue with local bookmarks if server fetch fails
      }

      // Fetch local bookmarks as backup
      final prefs = await SharedPreferences.getInstance();
      final String? storedBookmarks = prefs.getString(_bookmarksStorageKey);

      List<Bookmark> localBookmarks = [];
      if (storedBookmarks != null && storedBookmarks.isNotEmpty) {
        try {
          final List<dynamic> decodedData = json.decode(storedBookmarks);
          localBookmarks = decodedData
              .map((item) => Bookmark.fromJson(Map<String, dynamic>.from(item)))
              .where((bookmark) => bookmark.postId > 0) // Filter out invalid bookmarks
              .toList();
        } catch (e) {
          print('Error decoding stored bookmarks: $e');
        }
      }

      // Merge server and local bookmarks, prioritizing server data
      final Map<int, Bookmark> mergedBookmarks = {};

      // Add local bookmarks first
      for (var bookmark in localBookmarks) {
        if (bookmark.postId > 0) { // Skip invalid postIds
          mergedBookmarks[bookmark.postId] = bookmark;
        }
      }

      // Override with server bookmarks
      for (var bookmark in serverBookmarks) {
        if (bookmark.postId > 0) { // Skip invalid postIds
          mergedBookmarks[bookmark.postId] = bookmark;
        }
      }

      _bookmarks = mergedBookmarks.values.toList();
      _isLoading = false;
      notifyListeners();

      // Save merged bookmarks back to local storage
      _saveBookmarksLocally();
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error fetching bookmarks: $error');
    }
  }

  // Add a bookmark
  Future<bool> addBookmark(Post post) async {
    try {
      if (post.id == null) return false;

      _isLoading = true;
      notifyListeners();

      final String? userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        _errorMessage = "User not authenticated";
        notifyListeners();
        return false;
      }

      // Check if already bookmarked
      if (isBookmarked(post.id!)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      int? bookmarkId;

      // Add to Supabase
      try {
        final response = await _supabase
            .from('bookmarks')
            .insert({
          'post_id': post.id,
          'user_id': userId,
          'saved_at': now.toIso8601String(),
          'is_deleted': false,
        })
            .select();

        if (response != null && response is List && response.isNotEmpty) {
          bookmarkId = response[0]['id'];
        }
      } catch (e) {
        print('Error adding bookmark to server: $e');
        // Continue with local storage even if server fails
      }

      // Create and store bookmark locally
      final newBookmark = Bookmark(
        id: bookmarkId,
        postId: post.id!,
        userId: userId,
        savedAt: now,
        isDeleted: false,
        localPostData: json.encode(post.toJson()),
      );

      _bookmarks.add(newBookmark);
      _isLoading = false;
      notifyListeners();

      // Save to local storage
      _saveBookmarksLocally();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error adding bookmark: $error');
      return false;
    }
  }

  // Remove a bookmark
  Future<bool> removeBookmark(int postId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final String? userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        _errorMessage = "User not authenticated";
        notifyListeners();
        return false;
      }

      final index = _bookmarks.indexWhere((b) => b.postId == postId);
      if (index < 0) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Remove from Supabase if bookmark has ID
      if (_bookmarks[index].id != null) {
        try {
          await _supabase
              .from('bookmarks')
              .delete()
              .eq('id', _bookmarks[index].id as Object);
        } catch (e) {
          print('Error removing bookmark from server: $e');
        }
      }

      // Remove from local list
      _bookmarks.removeAt(index);
      _isLoading = false;
      notifyListeners();

      // Update local storage
      _saveBookmarksLocally();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error removing bookmark: $error');
      return false;
    }
  }

  // Mark a bookmark as referring to a deleted post
  Future<bool> markAsDeleted(int postId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final index = _bookmarks.indexWhere((b) => b.postId == postId);
      if (index < 0) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update in Supabase if bookmark has ID
      if (_bookmarks[index].id != null) {
        try {
          await _supabase
              .from('bookmarks')
              .update({'is_deleted': true})
              .eq('id', _bookmarks[index].id as Object);
        } catch (e) {
          print('Error updating bookmark on server: $e');
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
      _isLoading = false;
      notifyListeners();

      // Update local storage
      _saveBookmarksLocally();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error marking bookmark as deleted: $error');
      return false;
    }
  }

  // Save bookmarks to local storage
  Future<void> _saveBookmarksLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(_bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_bookmarksStorageKey, jsonData);
    } catch (error) {
      print('Error saving bookmarks locally: $error');
    }
  }

  // Get a bookmarked post (from local storage or server)
  Future<Post?> getBookmarkedPost(int postId) async {
    try {
      // Find the bookmark
      final bookmark = _bookmarks.firstWhere(
            (b) => b.postId == postId,
        orElse: () => Bookmark(postId: -1, userId: ''),
      );

      if (bookmark.postId == -1) return null;

      // If bookmark is deleted but we have local data, return from local
      if (bookmark.isDeleted && bookmark.localPostData != null) {
        final postData = json.decode(bookmark.localPostData!);
        return Post.fromJson(postData);
      }

      // Try to fetch from server first
      try {
        final response = await _supabase
            .from('posts')
            .select()
            .eq('id', postId)
            .maybeSingle();

        if (response != null) {
          return Post.fromJson(response);
        }
      } catch (e) {
        print('Error fetching bookmarked post from server: $e');
      }

      // If server fetch fails but we have local data, use that
      if (bookmark.localPostData != null) {
        final postData = json.decode(bookmark.localPostData!);
        return Post.fromJson(postData);
      }

      return null;
    } catch (error) {
      print('Error getting bookmarked post: $error');
      return null;
    }
  }
}