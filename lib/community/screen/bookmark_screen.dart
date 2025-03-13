import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/bookmark_provider.dart';
import '../models/post.dart';
import 'post_detail.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<BookmarkProvider>(context, listen: false).fetchBookmarks();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookmarks. Error: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final bookmarks = bookmarkProvider.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookmarks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarks.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Bookmarked posts will appear here and remain\naccessible even after they expire',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];

          return FutureBuilder<Post?>(
            future: bookmarkProvider.getBookmarkedPost(bookmark.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Loading...'),
                    subtitle: LinearProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: const Text('Error loading post'),
                    subtitle: Text('${snapshot.error}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await bookmarkProvider.removeBookmark(bookmark.postId);
                        setState(() {});
                      },
                    ),
                  ),
                );
              }

              final post = snapshot.data;

              if (post == null) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: Colors.grey.shade200,
                  child: ListTile(
                    title: const Text('Post unavailable'),
                    subtitle: bookmark.savedAt != null
                        ? Text('Saved on ${DateFormat('yyyy-MM-dd').format(bookmark.savedAt!)}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        await bookmarkProvider.removeBookmark(bookmark.postId);
                        setState(() {});
                      },
                    ),
                  ),
                );
              }

              // Check if post is expired but still accessible through bookmark
              bool isExpired = false;
              if (post.expirationDate != null &&
                  post.expirationDate!.isBefore(DateTime.now()) &&
                  bookmark.isDeleted) {
                isExpired = true;
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title ?? 'Untitled',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Expired',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (post.content != null)
                            Text(
                              post.content!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                post.datetime != null
                                    ? DateFormat('yyyy-MM-dd').format(post.datetime!)
                                    : 'Unknown date',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isExpired && post.expirationDate != null)
                            _buildExpirationInfo(post.expirationDate!),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.bookmark, color: Colors.yellow),
                            onPressed: () async {
                              await bookmarkProvider.removeBookmark(bookmark.postId);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              posts: post,
                              isFromBookmark: true,
                            ),
                          ),
                        ).then((_) => _fetchBookmarks());
                      },
                    ),
                    // If post is expired, show local only notification
                    if (isExpired)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This post has expired but is still available in your bookmarks',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to display expiration information
  Widget _buildExpirationInfo(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    // If already expired
    if (difference.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Expired',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    // If expires in less than a day
    if (difference.inDays < 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Expires in ${difference.inHours}h',
          style: TextStyle(fontSize: 10, color: Colors.red.shade800),
        ),
      );
    }

    // If expires in less than 3 days
    if (difference.inDays < 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Expires in ${difference.inDays}d',
          style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
        ),
      );
    }

    // For posts with more than 3 days remaining
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Expires in ${difference.inDays}d',
        style: TextStyle(fontSize: 10, color: Colors.green.shade800),
      ),
    );
  }
}