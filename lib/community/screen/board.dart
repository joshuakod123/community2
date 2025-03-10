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

    // Also fetch bookmarks
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
      await Provider.of<Posts>(context, listen: false).deletePost(postId, context: context);
      // Refresh the post list
      await _fetchPosts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $error')),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: const Text('Community Board', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmarks, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookmarkScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchPosts,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
            ),
          ]
      ),
      body: Stack(
        children: [
          // Main content with padding for the bottom navigation bar
          Padding(
            padding: const EdgeInsets.only(bottom: 80), // Add padding for the floating nav bar
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : posts.isEmpty
                ? const Center(child: Text('No posts available. Add a post to get started!', style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (ctx, index) {
                final post = posts[index];
                final isPostCreator = post.userId == currentUserId;
                final isBookmarked = bookmarkProvider.isBookmarked(post.id);
                final daysRemaining = postsProvider.getDaysRemaining(post);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    post.title != null && post.title!.length > 60
                                        ? '${post.title!.substring(0, 60)}...'
                                        : post.title ?? 'No Title',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Bookmark button
                                    IconButton(
                                      icon: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        color: isBookmarked ? Colors.yellow : Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () => _toggleBookmark(post),
                                    ),
                                    // Delete button for post creator
                                    if (isPostCreator)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _showDeleteConfirmation(post.id),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.content != null && post.content!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  post.content!.length > 100
                                      ? '${post.content!.substring(0, 100)}...'
                                      : post.content!,
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  post.datetime != null
                                      ? "${DateFormat('yyyy-MM-dd HH:mm').format(post.datetime!)} | ${post.userId ?? 'Unknown'}"
                                      : '',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                // Expiration indicator
                                if (post.expirationDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: daysRemaining <= 1 ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      daysRemaining <= 1
                                          ? 'Expires soon'
                                          : 'Expires in $daysRemaining days',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: daysRemaining <= 1 ? Colors.red[300] : Colors.amber[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(posts: post),
                            ),
                          ).then((_) => _fetchPosts()); // Refresh after returning from detail
                        },
                      ),
                    ],
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
      floatingActionButton: FloatingActionButton(
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
    );
  }
}