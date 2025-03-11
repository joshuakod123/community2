import 'package:flutter/material.dart';
import 'package:experiment3/community/screen/post_detail.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/post_provider.dart';

class BoardSearch extends StatefulWidget {
  final String search;

  const BoardSearch({Key? key, required this.search}) : super(key: key);

  @override
  State<BoardSearch> createState() => _BoardSearchState();
}

class _BoardSearchState extends State<BoardSearch> {
  bool _isLoading = false;

  @override
  void initState(){
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<Posts>(context, listen: false).fetchAndSetPostsWithSearch(widget.search);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load search results. Please try again later. Error: $error')),
      );
      print('Search error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postList = Provider.of<Posts>(context);
    final posts = postList.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results for: ${widget.search}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Results Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No posts matching "${widget.search}"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
          itemCount: posts.length,
          itemBuilder: (ctx, index){
            final post = posts[index];
            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title != null && post.title!.length > 60
                        ? '${post.title!.substring(0, 60)}...'
                        : post.title ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      post.content != null && post.content!.length > 80
                          ? '${post.content!.substring(0, 80)}...'
                          : post.content ?? 'No content available.',
                      style: const TextStyle(color: Colors.grey)
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
                );
              },
            );
          }
      ),
    );
  }
}