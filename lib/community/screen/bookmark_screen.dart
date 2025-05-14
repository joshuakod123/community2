// lib/community/screen/bookmark_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/post_card.dart';
import '../utils/ui_helpers.dart';
import 'post_detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to prevent calling setState during build phase
    Future.microtask(() => _fetchBookmarks());
  }

  Future<void> _fetchBookmarks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      await bookmarkProvider.fetchBookmarks();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        UIHelpers.showSnackBar(
          context,
          'Error loading bookmarks: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  void _navigateToPostDetail(post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id!,
          isFromBookmark: true,
        ),
      ),
    ).then((_) => _fetchBookmarks()); // Refresh when returning
  }

  Future<void> _clearAllBookmarks() async {
    final shouldClear = await UIHelpers.showConfirmationDialog(
      context: context,
      title: 'Clear All Bookmarks',
      message: 'Are you sure you want to remove all bookmarks? This action cannot be undone.',
      confirmText: 'Clear All',
      isDestructive: true,
    );

    if (!shouldClear) return;

    try {
      UIHelpers.showLoadingDialog(context, 'Clearing bookmarks...');

      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      final bookmarks = List.from(bookmarkProvider.bookmarks);

      // Remove each bookmark one by one
      for (final bookmark in bookmarks) {
        await bookmarkProvider.removeBookmark(bookmark.postId);
      }

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'All bookmarks cleared',
          isSuccess: true,
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
          'Error clearing bookmarks: ${error.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookmarks,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllBookmarks();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear All Bookmarks'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBookmarksList(),
    );
  }

  Widget _buildBookmarksList() {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final bookmarks = bookmarkProvider.bookmarks;

        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bookmark posts to save them for later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchBookmarks,
          child: ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];

              return FutureBuilder(
                future: bookmarkProvider.getBookmarkedPost(bookmark.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Loading bookmark...'),
                        subtitle: LinearProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: const Text('Error loading bookmark'),
                        subtitle: Text('${snapshot.error}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await bookmarkProvider.removeBookmark(bookmark.postId);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  }

                  final post = snapshot.data;

                  if (post == null) {
                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: ListTile(
                        title: const Text('Post unavailable'),
                        subtitle: bookmark.savedAt != null
                            ? Text('Saved on ${bookmark.savedAt!.toLocal().toString().split(' ')[0]}')
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await bookmarkProvider.removeBookmark(bookmark.postId);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  }

                  // Post is available, show post card
                  return PostCard(
                    post: post,
                    onTap: _navigateToPostDetail,
                    isInBookmarkScreen: true,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}