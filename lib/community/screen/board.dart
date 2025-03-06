import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/screen/add_post.dart';
import 'package:experiment3/community/screen/post_detail.dart';
import 'package:experiment3/community/screen/search.dart';
import 'package:experiment3/community/provider/board_provider.dart';
import 'package:experiment3/community/provider/post_provider.dart';
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
      await Provider.of<Posts>(context, listen: false).deletePost(postId);
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

  @override
  Widget build(BuildContext context) {
    final postList = Provider.of<PostList>(context);
    final posts = postList.items;
    final currentUserId = supabase.auth.currentUser?.userMetadata?['Display name'] ??
        supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: const Text('Community Board', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
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
                                if (isPostCreator)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _showDeleteConfirmation(post.id),
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
                            Text(
                              post.datetime != null
                                  ? "${DateFormat('yyyy-MM-dd HH:mm').format(post.datetime!)} | ${post.userId ?? 'Unknown'}"
                                  : '',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
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