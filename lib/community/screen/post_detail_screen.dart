// lib/community/screen/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../providers/post_provider.dart';
import '../providers/comment_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/comment_card.dart';
import '../utils/date_formatter.dart';
import '../utils/ui_helpers.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final bool isFromBookmark;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.isFromBookmark = false,
  }) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _supabase = Supabase.instance.client;
  Post? _post;
  bool _isLoading = true;
  bool _isSendingComment = false;
  bool _isLiked = false;
  bool _isBookmarked = false;
  String? _errorMessage;
  late CommentProvider _commentProvider;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store a reference to the provider that we'll need in dispose
    _commentProvider = Provider.of<CommentProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Use the stored reference instead of looking up the provider in dispose
    if (mounted) {
      _commentProvider.clearComments();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get providers
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);

      // Load post details
      _post = await postProvider.fetchPostById(widget.postId);

      if (_post == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Post not found';
        });
        return;
      }

      // Load comments
      await commentProvider.fetchComments(widget.postId);

      // Check if post is liked by current user
      if (_post?.id != null) {
        _isLiked = await postProvider.isPostLiked(_post!.id!);
        _isBookmarked = bookmarkProvider.isBookmarked(_post!.id!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading post: ${error.toString()}';
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post?.id == null) return;

    final postProvider = Provider.of<PostProvider>(context, listen: false);

    try {
      if (_isLiked) {
        await postProvider.unlikePost(_post!.id!);
      } else {
        await postProvider.likePost(_post!.id!);
      }

      setState(() {
        _isLiked = !_isLiked;
      });

      // Refresh post data
      _post = await postProvider.fetchPostById(widget.postId);
    } catch (error) {
      UIHelpers.showSnackBar(
        context,
        'Error updating like status: ${error.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _toggleBookmark() async {
    if (_post == null) return;

    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);

    try {
      bool success;

      if (_isBookmarked) {
        success = await bookmarkProvider.removeBookmark(_post!.id!);
        if (success && mounted) {
          UIHelpers.showSnackBar(context, 'Post removed from bookmarks');
        }
      } else {
        success = await bookmarkProvider.addBookmark(_post!);
        if (success && mounted) {
          UIHelpers.showSnackBar(context, 'Post saved to bookmarks', isSuccess: true);
        }
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (error) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Error updating bookmark: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _post?.id == null) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);

      final newComment = Comment(
        postId: _post!.id!,
        contents: _commentController.text.trim(),
      );

      await commentProvider.addComment(newComment);

      _commentController.clear();
      setState(() {
        _isSendingComment = false;
      });
    } catch (error) {
      setState(() {
        _isSendingComment = false;
      });

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Error posting comment: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _extendPostExpiration() async {
    if (_post?.id == null) return;

    try {
      UIHelpers.showLoadingDialog(context, 'Extending post expiration...');

      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final success = await postProvider.extendPostExpiration(_post!.id!);

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success && mounted) {
        UIHelpers.showSnackBar(
          context,
          'Post expiration extended by 7 days',
          isSuccess: true,
        );

        // Refresh post data
        _post = await postProvider.fetchPostById(widget.postId);
        setState(() {});
      } else if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Failed to extend post expiration',
          isError: true,
        );
      }
    } catch (error) {
      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Error: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deletePost() async {
    if (_post?.id == null) return;

    final shouldDelete = await UIHelpers.showConfirmationDialog(
      context: context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!shouldDelete) return;

    try {
      UIHelpers.showLoadingDialog(context, 'Deleting post...');

      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final success = await postProvider.deletePost(_post!.id!);

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success && mounted) {
        UIHelpers.showSnackBar(
          context,
          'Post deleted successfully',
          isSuccess: true,
        );

        // Navigate back
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate post was deleted
        }
      } else if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Failed to delete post',
          isError: true,
        );
      }
    } catch (error) {
      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Error: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  void _navigateToEditPost() async {
    if (_post == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: _post!),
      ),
    );

    if (result == true && mounted) {
      // Refresh post data
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final isPostCreator = currentUserId != null && _post?.creatorId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
          ),
          if (isPostCreator)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPost();
                } else if (value == 'delete') {
                  _deletePost();
                } else if (value == 'extend') {
                  _extendPostExpiration();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Post'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'extend',
                  child: ListTile(
                    leading: Icon(Icons.timer),
                    title: Text('Extend Expiration'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Post', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _post == null
          ? const Center(child: Text('Post not found'))
          : _buildPostDetails(),
    );
  }

  Widget _buildPostDetails() {
    final commentProvider = Provider.of<CommentProvider>(context);
    final comments = commentProvider.comments;
    final currentUserId = _supabase.auth.currentUser?.id;
    final isPostCreator = currentUserId != null && _post?.creatorId == currentUserId;

    return Column(
      children: [
        // Post content in a scrollable area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header with author info
                Row(
                  children: [
                    UserAvatar(
                      userId: _post?.creatorId ?? 'anonymous',
                      displayName: _post?.creatorId ?? 'Anonymous',
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post?.creatorId ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_post?.datetime != null)
                            Text(
                              DateFormatter.getDetailDateTime(_post!.datetime!),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_post?.isPinned ?? false)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Post title
                Text(
                  _post?.title ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Expiration notice
                if (_post?.expirationDate != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(DateFormatter.getExpirationColor(_post!.expirationDate!)).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(DateFormatter.getExpirationColor(_post!.expirationDate!)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: Color(DateFormatter.getExpirationColor(_post!.expirationDate!)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.getExpirationText(_post!.expirationDate!),
                          style: TextStyle(
                            color: Color(DateFormatter.getExpirationColor(_post!.expirationDate!)),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPostCreator)
                          TextButton(
                            onPressed: _extendPostExpiration,
                            child: const Text('Extend'),
                          ),
                      ],
                    ),
                  ),

                // Post content
                if (_post?.content != null)
                  Text(
                    _post!.content!,
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 16),

                // Post image
                if (_post?.imgUrl != null && _post!.imgUrl!.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _post!.imgUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Like and comment counts
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text(
                      '${_post?.likesCount ?? 0} likes',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment_outlined),
                    const SizedBox(width: 8),
                    Text(
                      '${comments.length} comments',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Comments section
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Comments list
                commentProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : comments.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No comments yet. Be the first to comment!'),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return CommentCard(comment: comments[index]);
                  },
                ),
              ],
            ),
          ),
        ),

        // Comment input field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isSendingComment
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                onPressed: _isSendingComment ? null : _addComment,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}