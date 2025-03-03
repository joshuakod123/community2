import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/provider/comment_provider.dart';
import 'package:experiment3/community/models/comment.dart';
import 'package:experiment3/community/provider/post_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post posts;

  const PostDetailScreen({Key? key, required this.posts}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = false;
  final _commentController = TextEditingController();
  String? _postCreator;
  bool isLiked = false;
  late int? likesCount;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPostCreator();
    _fetchComments();
    likesCount = widget.posts.initialLikes ?? 0;
    checkIfLiked();
  }

  Future<void> _fetchComments() async {
    if (widget.posts.id == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      // Handle the case when id might be a string
      var postId = widget.posts.id;
      if (postId is String && int.tryParse(postId) != null) {
        postId = int.parse(postId);
      }

      await Provider.of<Comments>(context, listen: false)
          .fetchAndSetComments(postId);
    } catch (error) {
      print("Error fetching comments: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments. ${error.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPostCreator() async {
    if (widget.posts.id == null) return;

    try {
      // Use the id directly without casting
      final response = await supabase
          .from('posts')
          .select('creatorId')
          .eq('id', widget.posts.id)
          .single();

      if (response != null) {
        setState(() {
          _postCreator = response['creatorId']?.toString();
        });
      }
    } catch (error) {
      print('Error fetching post creator: $error');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = Comment(
      id: null,
      postId: widget.posts.id,
      contents: _commentController.text.trim(),
      datetime: DateTime.now(),
      userId: supabase.auth.currentUser?.userMetadata?['Display name'] ?? supabase.auth.currentUser?.email,
    );

    try {
      await Provider.of<Comments>(context, listen: false).addComment(newComment);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (error) {
      print("Error adding comment: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> checkIfLiked() async {
    if (widget.posts.id == null) return;

    final _userId = supabase.auth.currentUser?.userMetadata?['Display name'] ?? supabase.auth.currentUser?.id;
    if (_userId == null) return;

    try {
      // Use the id directly - Supabase will convert types as needed
      final response = await supabase
          .from('likes')
          .select()
          .match({
        'user_id': _userId,
        'post_id': widget.posts.id,
      })
          .single();

      setState(() {
        isLiked = response != null;
      });
    } catch (error) {
      // If no match is found, it will throw an error, which means the post is not liked
      print("Like check error (expected if not liked): $error");
      setState(() {
        isLiked = false;
      });
    }
  }

  Future<void> likePost() async {
    if (isLiked || widget.posts.id == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Insert like - Supabase will handle type conversion
      await supabase.from('likes').insert({
        'user_id': userId,
        'post_id': widget.posts.id,
      });

      // Update like count
      await supabase.from('posts').update({
        'likes': likesCount! + 1
      }).eq('id', widget.posts.id);

      setState(() {
        isLiked = true;
        likesCount = likesCount! + 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post liked!')),
      );
    } catch (e) {
      print('Error liking post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsData = Provider.of<Comments>(context);
    final comments = commentsData.items;
    String? _user = supabase.auth.currentUser?.userMetadata?['Display name'] ?? supabase.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post title
              Text(
                widget.posts.title ?? 'Untitled',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Date and Time
              Row(
                children: [
                  Text(
                    widget.posts.datetime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(widget.posts.datetime!)
                        : 'No date available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  if (_postCreator == _user)
                    IconButton(
                      onPressed: () async {
                        try {
                          await Provider.of<Posts>(context, listen: false)
                              .deletePost(widget.posts.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deleted successfully')),
                          );
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting post: $error')),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(' $_postCreator')
                ],
              ),

              const SizedBox(height: 10),

              // Post Content
              Text(
                widget.posts.content ?? 'No content available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Image (optional)
              if (widget.posts.imgURL != null && widget.posts.imgURL!.isNotEmpty)
                Image.network(
                  widget.posts.imgURL!,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Could not load image.');
                  },
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      likePost();
                    },
                  ),
                  Text('${likesCount ?? 0}')
                ],
              ),
              const SizedBox(height: 20),

              // Comments Section
              const Divider(),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ),

              // Display comments or loading indicator
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                  ? const Text('No comments yet. Be the first to comment!')
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (ctx, index) => ListTile(
                  leading: Icon(Icons.person, color: Colors.grey[600]),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comments[index].userId ?? 'Anonymous',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(comments[index].contents ?? ''),
                    ],
                  ),
                  subtitle: Text(
                    comments[index].datetime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(
                      comments[index].datetime!,
                    )
                        : '',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: comments[index].userId == _user
                      ? IconButton(
                    onPressed: () async {
                      try {
                        await Provider.of<Comments>(context, listen: false).deleteComment(comments[index].id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment deleted')),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting comment: $error')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete),
                  )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}