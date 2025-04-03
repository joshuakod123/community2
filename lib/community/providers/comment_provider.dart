// lib/community/providers/comment_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';

class CommentProvider with ChangeNotifier {
  final List<Comment> _comments = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentPostId;

  List<Comment> get comments => [..._comments];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentPostId => _currentPostId;

  // Fetch comments for a specific post
  Future<void> fetchComments(int postId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentPostId = postId;
      notifyListeners();

      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('datetime', ascending: true);

      final List<Comment> loadedComments = [];

      for (final commentData in response) {
        loadedComments.add(Comment.fromJson(commentData));
      }

      _comments.clear();
      _comments.addAll(loadedComments);

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error fetching comments: $error');
    }
  }

  // Add a new comment
  Future<Comment?> addComment(Comment comment) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user information
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        _errorMessage = "User not authenticated";
        notifyListeners();
        return null;
      }

      final response = await _supabase
          .from('comments')
          .insert({
        'post_id': comment.postId,
        'contents': comment.contents,
        'user_id': userId,
      })
          .select();

      if (response != null && response.isNotEmpty) {
        final newComment = Comment.fromJson(response[0]);
        _comments.add(newComment);

        _isLoading = false;
        notifyListeners();
        return newComment;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error adding comment: $error');
      return null;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First get the comment to verify ownership
      final commentData = await _supabase
          .from('comments')
          .select()
          .eq('id', commentId)
          .maybeSingle();

      if (commentData == null) {
        _isLoading = false;
        _errorMessage = "Comment not found";
        notifyListeners();
        return false;
      }

      final comment = Comment.fromJson(commentData);
      final currentUserId = _supabase.auth.currentUser?.id;

      // Verify ownership - only the comment creator can delete it
      if (currentUserId != comment.userId) {
        _isLoading = false;
        _errorMessage = "You can only delete your own comments";
        notifyListeners();
        return false;
      }

      // Delete the comment
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId);

      // Remove from local list
      _comments.removeWhere((c) => c.id == commentId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error deleting comment: $error');
      return false;
    }
  }

  // Get user display name for comments
  Future<String> getUserDisplayName(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return "Anonymous";

      final firstName = userData['first_name'] ?? '';
      final lastName = userData['last_name'] ?? '';

      if (firstName.isEmpty && lastName.isEmpty) return "Anonymous";
      return "$firstName $lastName".trim();
    } catch (error) {
      print('Error getting user name: $error');
      return "Anonymous";
    }
  }

  // Clear comments when navigating away from post
  void clearComments() {
    // Safe clearing of comments without notifying listeners
    // which would trigger an error if the widget is being disposed
    _comments.clear();
    _currentPostId = null;

    // We do not call notifyListeners() here since this method
    // might be called during widget disposal
  }
}