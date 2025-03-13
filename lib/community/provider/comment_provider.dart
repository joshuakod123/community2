import 'dart:async';
import 'package:flutter/material.dart';
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
    if (postId == null) return;

    try {
      // Convert the postId to a string for comparison in logs
      String postIdStr = postId.toString();
      print("Fetching comments for post ID: $postIdStr");

      // Use correct filtering - no need to preprocess the postId
      final response = await supabase
          .from('comments')
          .select()
          .eq('postId', postId)
          .order('datetime', ascending: true);

      print("Comments response: $response");

      if (response == null) {
        print("No comments found or null response");
        _items = [];
        notifyListeners();
        return;
      }

      final List<Comment> loadedComments = (response as List<dynamic>)
          .map((commentData) => Comment(
        id: commentData['id'],
        postId: commentData['postId'],
        contents: commentData['contents'],
        datetime: commentData['datetime'] != null
            ? DateTime.parse(commentData['datetime'])
            : null,
        userId: commentData['userId'],
      ))
          .toList();

      print("Loaded ${loadedComments.length} comments");
      _items = loadedComments;
      notifyListeners();
    } catch (error) {
      print("Error fetching comments: $error");
      // Instead of rethrow, return empty list to avoid crashing UI
      _items = [];
      notifyListeners();
    }
  }

  Future<void> addComment(Comment comment) async {
    if (comment.postId == null) {
      print("Cannot add comment: postId is null");
      return;
    }

    final timeStamp = DateTime.now().toUtc();
    try {
      String? userId = supabase.auth.currentUser?.email ??
          supabase.auth.currentUser?.id ??
          "Anonymous";

      print("Adding comment to post ID: ${comment.postId}");
      print("Comment data: ${comment.contents}");
      print("User ID: $userId");

      final response = await supabase.from('comments').insert({
        'contents': comment.contents,
        'datetime': timeStamp.toIso8601String(),
        'postId': comment.postId,
        'userId': userId,
      }).select();

      print("Insert comment response: $response");

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

        // Try to find the post creator to notify them
        try {
          final postResponse = await supabase
              .from('posts')
              .select('creatorId')
              .eq('id', comment.postId as Object)
              .single();

          if (postResponse != null &&
              postResponse['creatorId'] != null &&
              postResponse['creatorId'] != userId) {
            // Send notification to post creator
            final notificationService = NotificationService();
            await notificationService.showLocalNotification(
              title: 'New Comment',
              body: 'Someone commented on your post',
              channelId: 'community_channel',
            );
          }
        } catch (e) {
          print("Error sending notification: $e");
          // Continue even if notification fails
        }
      }
    } catch (error) {
      print("Error adding comment: $error");
      // Don't rethrow to avoid crashing the UI
    }
  }

  Future<void> deleteComment(int? id) async {
    if (id == null) {
      print("Cannot delete comment: id is null");
      return;
    }

    final existingCommentIndex = _items.indexWhere((comment) => comment.id == id);
    if (existingCommentIndex < 0) {
      print("Comment not found in local state: $id");
      return; // Comment not found
    }

    var existingComment = _items[existingCommentIndex];

    // Remove from local state first for immediate UI update
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