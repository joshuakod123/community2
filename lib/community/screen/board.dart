// lib/community/screen/board.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/screen/add_post.dart';
import 'package:experiment3/community/screen/post_detail.dart';
import 'package:experiment3/community/screen/search.dart';
import 'package:experiment3/community/screen/bookmark_screen.dart';
import 'package:experiment3/community/provider/board_provider.dart';
import 'package:experiment3/community/provider/post_provider.dart';
import 'package:experiment3/community/provider/bookmark_provider.dart';
import 'package:experiment3/widgets/floating_bottom_navigation_bar.dart';
import 'package:intl/intl.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({Key? key}) : super(key: key);

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    try {
      await Provider.of<BookmarkProvider>(context, listen: false).fetchBookmarks();
    } catch (error) {
      print('Error fetching bookmarks: $error');
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<PostList>(context, listen: false).fetchAndSetPosts();
    } catch (error) {
      _showError('Failed to load posts. Please try again later. Error: $error');
      print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deletePost(int? postId) async {
    if (postId == null) return;

    try {
      // First delete the post
      await Provider.of<Posts>(context, listen: false).deletePost(postId);

      // Then mark as deleted in bookmarks
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      await bookmarkProvider.markAsDeleted(postId);

      // Refresh the post list
      await _fetchPosts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(int? postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(Post post) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
    final isBookmarked = bookmarkProvider.isBookmarked(post.id);

    try {
      if (isBookmarked) {
        await bookmarkProvider.removeBookmark(post.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from bookmarks')),
        );
      } else {
        await bookmarkProvider.addBookmark(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post saved to bookmarks')),
        );
      }
      setState(() {}); // Refresh the UI
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bookmark: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postList = Provider.of<PostList>(context);
    final posts = postList.items;
    final currentUserId = supabase.auth.currentUser?.userMetadata?['Display name'] ??
        supabase.auth.currentUser?.id;
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final postsProvider = Provider.of<Posts>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Community Board',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookmarkScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchPosts,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with padding for the bottom navigation bar
          Padding(
            padding: const EdgeInsets.only(bottom: 80), // Add padding for the floating nav bar
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? const Center(child: Text('No posts available. Add a post to get started!'))
                : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (ctx, index) {
                final post = posts[index];
                final isPostCreator = post.userId == currentUserId;
                final isBookmarked = bookmarkProvider.isBookmarked(post.id);
                final daysRemaining = postsProvider.getDaysRemaining(post);

                // Build post card in modern style like image 2
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(posts: post),
                      ),
                    ).then((_) => _fetchPosts()); // Refresh after returning
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and topic label section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  post.title ?? 'Untitled Post',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (isBookmarked)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.bookmark,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Author and time info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey.shade200,
                                child: Text(
                                  post.userId != null && post.userId!.isNotEmpty
                                      ? post.userId![0].toUpperCase()
                                      : "U",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                post.userId ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                ' • ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                post.datetime != null
                                    ? _getTimeDisplay(post.datetime!)
                                    : 'Unknown time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (post.expirationDate != null && daysRemaining <= 2)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Expires soon',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Post topic label (if any)
                        if (post.title?.toLowerCase().contains('question') ?? false)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Questions & Help',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (post.title?.toLowerCase().contains('announce') ?? false)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Announcements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Post content preview
                        if (post.content != null && post.content!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              post.content!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        // Action buttons row
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Comments
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '12 comments',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              // Likes
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_outlined,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.initialLikes ?? 0} likes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              // Actions (bookmark, delete)
                              Row(
                                children: [
                                  // Bookmark button
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      color: isBookmarked ? Colors.amber : Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    onPressed: () => _toggleBookmark(post),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),

                                  // Delete button (only for creator)
                                  if (isPostCreator)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                          size: 18,
                                        ),
                                        onPressed: () => _showDeleteConfirmation(post.id),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating navigation bar at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNavigationBar(currentIndex: 1), // 1 is for Community
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // Add padding to prevent overlap with nav bar
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddPostScreen(),
              ),
            );
            if (result == true) {
              _fetchPosts();
            }
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Helper method to display time in a user-friendly format
  String _getTimeDisplay(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(postTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }
}