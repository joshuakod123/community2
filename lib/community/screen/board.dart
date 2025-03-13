// lib/community/screen/board.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/bookmark_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/ui_helpers.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'bookmark_screen.dart';
import '../../widgets/floating_bottom_navigation_bar.dart';

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
      await Provider.of<PostProvider>(context, listen: false).fetchPosts();
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
    UIHelpers.showSnackBar(context, message, isError: true);
  }

  Future<void> _deletePost(int postId) async {
    try {
      // First delete the post
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final success = await postProvider.deletePost(postId);

      if (!success) {
        throw Exception("Failed to delete post");
      }

      // Then mark as deleted in bookmarks
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      await bookmarkProvider.markAsDeleted(postId);

      // Refresh the post list
      await _fetchPosts();

      UIHelpers.showSnackBar(
        context,
        'Post deleted successfully',
        isSuccess: true,
      );
    } catch (error) {
      UIHelpers.showSnackBar(
        context,
        'Error deleting post: $error',
        isError: true,
      );
    }
  }

  void _showDeleteConfirmation(int postId) async {
    final shouldDelete = await UIHelpers.showConfirmationDialog(
      context: context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (shouldDelete) {
      _deletePost(postId);
    }
  }

  Future<void> _toggleBookmark(Post post) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
    final isBookmarked = post.id != null ? bookmarkProvider.isBookmarked(post.id!) : false;

    try {
      if (isBookmarked && post.id != null) {
        await bookmarkProvider.removeBookmark(post.id!);
        UIHelpers.showSnackBar(context, 'Post removed from bookmarks');
      } else {
        await bookmarkProvider.addBookmark(post);
        UIHelpers.showSnackBar(context, 'Post saved to bookmarks', isSuccess: true);
      }
      setState(() {}); // Refresh the UI
    } catch (error) {
      UIHelpers.showSnackBar(
        context,
        'Error updating bookmark: $error',
        isError: true,
      );
    }
  }

  void _navigateToPostDetail(Post post) {
    if (post.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: post.id!),
      ),
    ).then((_) => _fetchPosts()); // Refresh after returning
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final posts = postProvider.posts;
    final currentUserId = supabase.auth.currentUser?.id;
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);

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
                MaterialPageRoute(builder: (context) => const SearchScreen()),
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
                final isPostCreator = post.creatorId == currentUserId;
                final isBookmarked = post.id != null ? bookmarkProvider.isBookmarked(post.id!) : false;
                final daysRemaining = postProvider.getDaysRemaining(post);

                // Build post card in modern style
                return GestureDetector(
                  onTap: () => _navigateToPostDetail(post),
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
                                  post.title,
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
                                  post.creatorId != null && post.creatorId!.isNotEmpty
                                      ? post.creatorId![0].toUpperCase()
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
                                post.creatorId ?? 'Anonymous',
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
                                    ? DateFormatter.getTimeAgo(post.datetime!)
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

                        // Post category label
                        if (post.category != null)
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
                              child: Text(
                                post.category!,
                                style: const TextStyle(
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
                              // Comments placeholder - will be updated when comments feature is implemented
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Comments',
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
                                    '${post.likesCount}',
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
                                  if (isPostCreator && post.id != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                          size: 18,
                                        ),
                                        onPressed: () => _showDeleteConfirmation(post.id!),
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
                builder: (context) => const CreatePostScreen(),
              ),
            );
            if (result == true) {
              _fetchPosts();
            }
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}