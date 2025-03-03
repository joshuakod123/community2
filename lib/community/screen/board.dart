import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/screen/add_post.dart';
import 'package:experiment3/community/screen/post_detail.dart';
import 'package:intl/intl.dart';
import 'package:experiment3/community/screen/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/board_provider.dart';
import '../provider/post_provider.dart';

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
      appBar: AppBar(
          title: const Text('Community Board', style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchPosts,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
            ),
          ]
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('No posts available. Add a post to get started!'))
          : ListView.builder(
        itemCount: posts.length,
        itemBuilder: (ctx, index) {
          final post = posts[index];
          final isPostCreator = post.userId == currentUserId;

          return Column(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
              if (index != posts.length - 1) const Divider(),
            ],
          );
        },
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
        child: const Icon(Icons.add),
      ),
    );
  }
}