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
          ? const Center(child: Text('No bookmarks yet.'))
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

              if (post == null || bookmark.isDeleted) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: Colors.grey.shade200,
                  child: ListTile(
                    title: const Text('This post has been deleted'),
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

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    post.title ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      if (post.datetime != null)
                        Text(
                          'Posted on ${DateFormat('yyyy-MM-dd').format(post.datetime!)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark, color: Colors.yellow),
                    onPressed: () async {
                      await bookmarkProvider.removeBookmark(bookmark.postId);
                      setState(() {});
                    },
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
              );
            },
          );
        },
      ),
    );
  }
}