import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/comment.dart';
import 'package:experiment3/services/notification_service.dart';

class Comments with ChangeNotifier {
  List<Comment> _items = [];
  Comments();

  List<Comment> get items {
    _items.sort((a, b) => a.datetime!.compareTo(b.datetime!));
    return [..._items];
  }

  // Initialize Supabase client
  final supabase = Supabase.instance.client;

  Future<void> fetchAndSetComments(dynamic postId) async {
    try {
      // Ensure postId is correctly formatted for the query
      String postIdQuery;
      if (postId is int) {
        postIdQuery = 'postId.eq.$postId';
      } else if (postId is String) {
        postIdQuery = 'postId.eq.$postId';
      } else {
        throw Exception('Invalid postId type: ${postId.runtimeType}');
      }

      final response = await supabase
          .from('comments')
          .select()
          .eq('postId', postId)
          .order('datetime', ascending: true);

      final List<Comment> loadedComments = (response as List<dynamic>)
          .map((commentData) => Comment(
        id: commentData['id'],
        postId: commentData['postId'],
        contents: commentData['contents'],
        datetime: DateTime.parse(commentData['datetime']),
        userId: commentData['userId'],
      ))
          .toList();

      _items = loadedComments;
      notifyListeners();
    } catch (error) {
      print("Error fetching comments: $error");
      throw error;
    }
  }

  Future<void> addComment(Comment comment) async {
    final timeStamp = DateTime.now().toUtc();
    try {
      String? userId = supabase.auth.currentUser?.userMetadata?['Display name'] ??
          supabase.auth.currentUser?.email ??
          supabase.auth.currentUser?.id;

      final response = await supabase.from('comments').insert({
        'contents': comment.contents,
        'datetime': timeStamp.toIso8601String(),
        'postId': comment.postId,
        'userId': userId,
      }).select();

      if (response != null && response.isNotEmpty) {
        final commentData = response[0];
        final newComment = Comment(
          id: commentData['id'],
          contents: comment.contents,
          datetime: timeStamp,
          postId: comment.postId,
          userId: userId,
        );

        _items.add(newComment);
        notifyListeners();

        // No need to manually create a notification here
        // The Supabase trigger will handle it automatically
      }
    } catch (error) {
      print("Error adding comment: $error");
      throw error;
    }
  }

  Future<void> deleteComment(int? id) async {
    if (id == null) return;

    final existingCommentIndex = _items.indexWhere((comment) => comment.id == id);
    if (existingCommentIndex < 0) return; // Comment not found

    var existingComment = _items[existingCommentIndex];

    // Remove from local state first
    _items.removeAt(existingCommentIndex);
    notifyListeners();

    try {
      // Then delete from Supabase
      await supabase.from('comments').delete().eq('id', id);
      print("Comment deleted successfully: $id");
    } catch (error) {
      // If deletion fails, add the comment back to the list
      _items.insert(existingCommentIndex, existingComment);
      notifyListeners();
      print("Error deleting comment: $error");
      throw error;
    }
  }
}