// lib/community/screen/post_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/provider/comment_provider.dart';
import 'package:experiment3/community/models/comment.dart';
import 'package:experiment3/community/provider/post_provider.dart';
import 'package:experiment3/community/provider/bookmark_provider.dart';
import 'package:experiment3/services/notification_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post posts;
  final bool isFromBookmark;

  const PostDetailScreen({
    Key? key,
    required this.posts,
    this.isFromBookmark = false,
  }) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = false;
  final _commentController = TextEditingController();
  String? _postCreator;
  bool isLiked = false;
  bool isBookmarked = false;
  late int? likesCount;
  final supabase = Supabase.instance.client;
  int daysRemaining = 7;
  int hoursRemaining = 168; // Default to 7 days (168 hours)
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchPostCreator();
    _fetchComments();
    likesCount = widget.posts.initialLikes ?? 0;
    checkIfLiked();

    // Calculate days remaining until expiration
    _calculateRemainingTime();

    // Check if post is bookmarked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      setState(() {
        isBookmarked = bookmarkProvider.isBookmarked(widget.posts.id);
      });
    });
  }

  void _calculateRemainingTime() {
    if (widget.posts.expirationDate != null) {
      final now = DateTime.now();
      final difference = widget.posts.expirationDate!.difference(now);
      setState(() {
        daysRemaining = difference.inDays < 0 ? 0 : difference.inDays;
        hoursRemaining = difference.inHours < 0 ? 0 : difference.inHours;
      });
    }
  }

  Future<void> _fetchComments() async {
    if (widget.posts.id == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      // Handle the case when id might be a string
      var postId = widget.posts.id;
      if (postId is String && int.tryParse(postId) != null) {
        postId = int.parse(postId);
      }

      await Provider.of<Comments>(context, listen: false)
          .fetchAndSetComments(postId);
    } catch (error) {
      print("Error fetching comments: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments. ${error.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPostCreator() async {
    if (widget.posts.id == null) return;

    try {
      // Use the id directly without casting
      final response = await supabase
          .from('posts')
          .select('creatorId')
          .eq('id', widget.posts.id)
          .single();

      if (response != null) {
        setState(() {
          _postCreator = response['creatorId']?.toString();
        });
      }
    } catch (error) {
      print('Error fetching post creator: $error');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = Comment(
      id: null,
      postId: widget.posts.id,
      contents: _commentController.text.trim(),
      datetime: DateTime.now(),
      userId: supabase.auth.currentUser?.userMetadata?['Display name'] ?? supabase.auth.currentUser?.email,
    );

    try {
      await Provider.of<Comments>(context, listen: false).addComment(newComment);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (error) {
      print("Error adding comment: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> checkIfLiked() async {
    if (widget.posts.id == null) return;

    final _userId = supabase.auth.currentUser?.userMetadata?['Display name'] ?? supabase.auth.currentUser?.id;
    if (_userId == null) return;

    try {
      // Use the id directly - Supabase will convert types as needed
      final response = await supabase
          .from('likes')
          .select()
          .match({
        'user_id': _userId,
        'post_id': widget.posts.id,
      })
          .single();

      setState(() {
        isLiked = response != null;
      });
    } catch (error) {
      // If no match is found, it will throw an error, which means the post is not liked
      print("Like check error (expected if not liked): $error");
      setState(() {
        isLiked = false;
      });
    }
  }

  Future<void> likePost() async {
    if (isLiked || widget.posts.id == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Insert like - Supabase will handle type conversion
      await supabase.from('likes').insert({
        'user_id': userId,
        'post_id': widget.posts.id,
      });

      // Update like count
      await supabase.from('posts').update({
        'likes': likesCount! + 1
      }).eq('id', widget.posts.id);

      setState(() {
        isLiked = true;
        likesCount = likesCount! + 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post liked!')),
      );
    } catch (e) {
      print('Error liking post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }
  }

  Future<void> toggleBookmark() async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      if (isBookmarked) {
        await bookmarkProvider.removeBookmark(widget.posts.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from bookmarks')),
        );
      } else {
        await bookmarkProvider.addBookmark(widget.posts);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post saved to bookmarks')),
        );
      }

      setState(() {
        isBookmarked = !isBookmarked;
      });
    } catch (error) {
      print('Error toggling bookmark: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bookmark: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to extend post expiration by 7 more days
  Future<void> _extendExpiration() async {
    if (widget.posts.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Only post creators can extend expiration
      final userId = supabase.auth.currentUser?.id;
      if (userId == null || userId != _postCreator) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only the post creator can extend the expiration')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Calculate new expiration date (current expiration + 7 days)
      final currentExpiration = widget.posts.expirationDate ?? DateTime.now().add(const Duration(days: 7));
      final newExpirationDate = currentExpiration.add(const Duration(days: 7));

      // Update expiration date in database
      await supabase.from('posts').update({
        'expiration_date': newExpirationDate.toIso8601String(),
      }).eq('id', widget.posts.id);

      // Update state
      setState(() {
        daysRemaining = daysRemaining + 7;
        hoursRemaining = hoursRemaining + 168; // 7 days * 24 hours
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post expiration extended by 7 days'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extending expiration: $error')),
      );
    }
  }

  // Method to delete the post
  Future<void> _deletePost() async {
    if (widget.posts.id == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await Provider.of<Posts>(context, listen: false).deletePost(widget.posts.id, context: context);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );

      Navigator.pop(context, true); // Return true to indicate post was deleted
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $error')),
      );
    }
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Method to delete a comment
  Future<void> _deleteComment(int? commentId) async {
    if (commentId == null) return;

    try {
      await Provider.of<Comments>(context, listen: false).deleteComment(commentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $error')),
      );
    }
  }

  // Method to show comment delete confirmation
  void _showCommentDeleteConfirmation(int? commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteComment(commentId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsData = Provider.of<Comments>(context);
    final comments = commentsData.items;
    String? _user = supabase.auth.currentUser?.userMetadata?['Display name'] ??
        supabase.auth.currentUser?.email ??
        supabase.auth.currentUser?.id;

    // Check if current user is the post creator
    final bool isCurrentUserPostCreator = _postCreator == _user || widget.posts.userId == _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          // Bookmark button
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.yellow : null,
            ),
            onPressed: toggleBookmark,
          ),
          if (isCurrentUserPostCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post title
              Text(
                widget.posts.title ?? 'Untitled',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Date and Time + Expiration info
              Row(
                children: [
                  Text(
                    widget.posts.datetime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(widget.posts.datetime!)
                        : 'No date available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 10),
                  Text('Posted by: ${_postCreator ?? "Unknown"}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),

              // Expiration notice
              if (widget.posts.expirationDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: daysRemaining <= 1 ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: daysRemaining <= 1 ? Colors.red : Colors.amber,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: daysRemaining <= 1 ? Colors.red : Colors.amber[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining <= 0 && hoursRemaining <= 0
                              ? 'This post has expired or will expire very soon'
                              : daysRemaining <= 0
                              ? 'Expires in less than ${hoursRemaining} hours'
                              : 'Expires in $daysRemaining days',
                          style: TextStyle(
                            color: daysRemaining <= 1 ? Colors.red : Colors.amber[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // If user is post creator and post is about to expire, show extend button
                        if (isCurrentUserPostCreator && daysRemaining < 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: TextButton(
                              onPressed: _extendExpiration,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Extend', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Post Content
              Text(
                widget.posts.content ?? 'No content available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Image (optional)
              if (widget.posts.imgURL != null && widget.posts.imgURL!.isNotEmpty)
                Image.network(
                  widget.posts.imgURL!,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Could not load image.');
                  },
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      likePost();
                    },
                  ),
                  Text('${likesCount ?? 0}')
                ],
              ),
              const SizedBox(height: 20),

              // Bookmark Reminder
              if (!isBookmarked && daysRemaining < 3)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This post will be deleted soon. Bookmark it to keep it accessible even after expiration.',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: isBookmarked ? null : toggleBookmark,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Bookmark'),
                      ),
                    ],
                  ),
                ),

              // Comments Section
              const Divider(),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ),

              // Display comments
              comments.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No comments yet. Be the first to comment!'),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (ctx, index) {
                  final comment = comments[index];
                  final isCommentOwner = comment.userId == _user;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                comment.userId ?? 'Anonymous',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (isCommentOwner)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _showCommentDeleteConfirmation(comment.id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment.contents ?? ''),
                          const SizedBox(height: 8),
                          Text(
                            comment.datetime != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(comment.datetime!)
                                : '',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}