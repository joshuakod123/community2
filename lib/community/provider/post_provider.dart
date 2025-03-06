import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';

class Posts with ChangeNotifier {
  List<Post> _items = [];
  final supabaseClient = Supabase.instance.client;

  List<Post> get items {
    _items.sort((a, b) => b.datetime!.compareTo(a.datetime!));
    return [..._items];
  }

  Future<void> addPost(Post post) async {
    final timeStamp = DateTime.now();
    String? userId = supabaseClient.auth.currentUser?.userMetadata?['Display name'] ??
        supabaseClient.auth.currentUser?.email ??
        supabaseClient.auth.currentUser?.id;

    try {
      final response = await supabaseClient.from('posts').insert({
        'title': post.title,
        'content': post.content,
        'datetime': timeStamp.toIso8601String(),
        'imgURL': post.imgURL,
        'creatorId': userId,
        'likes': 0,
      }).select();

      // Get the inserted post with its ID
      if (response != null && response.isNotEmpty) {
        final newPostData = response[0];
        final newPost = Post(
          id: newPostData['id'],
          title: post.title,
          content: post.content,
          datetime: timeStamp,
          imgURL: post.imgURL,
          userId: userId,
          initialLikes: 0,
        );
        _items.add(newPost);
        notifyListeners();
      }
    } catch (error) {
      print("Error adding post: $error");
      rethrow;
    }
  }

  Future<void> fetchAndSetPostsWithSearch(String searchText) async {
    try {
      final response = await supabaseClient
          .from('posts')
          .select()
          .or('title.ilike.%$searchText%,content.ilike.%$searchText%')
          .order('datetime', ascending: false);

      final data = response as List<dynamic>;
      final List<Post> loadedPosts = data.map((postData) {
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'],
          datetime: postData['datetime'] != null
              ? DateTime.parse(postData['datetime'])
              : null,
          imgURL: postData['imgURL'],
          userId: postData['creatorId'],
          initialLikes: postData['likes'],
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching posts with search: $error");
      rethrow;
    }
  }

  Future<void> deletePost(dynamic id) async {
    if (id == null) return;

    // Handle if id is a String but can be parsed as int
    if (id is String && int.tryParse(id) != null) {
      id = int.parse(id);
    }

    // Find the post in our local list
    final existingPostIndex = _items.indexWhere((post) => post.id == id);

    if (existingPostIndex >= 0) {
      // Store the post temporarily in case we need to revert
      Post? existingPost = _items[existingPostIndex];

      // Remove from local list first for immediate UI update
      _items.removeAt(existingPostIndex);
      notifyListeners();

      try {
        // Also delete all related comments first to avoid foreign key constraints
        await supabaseClient.from('comments').delete().eq('postId', id);

        // Also delete all related likes
        await supabaseClient.from('likes').delete().eq('post_id', id);

        // Then delete the post from Supabase
        await supabaseClient.from('posts').delete().eq('id', id);
        print("Post $id successfully deleted with all related data");
      } catch (error) {
        // If deletion fails, add the post back to the list
        _items.insert(existingPostIndex, existingPost);
        notifyListeners();
        print("Error deleting post: $error");
        rethrow;
      }
    } else {
      print("Post with ID $id not found in local list");
    }
  }

  Future<void> fetchThreePosts() async {
    try {
      final _response = await supabaseClient
          .from('posts')
          .select()
          .order('datetime', ascending: false)
          .limit(5);

      final data = _response as List<dynamic>;

      final List<Post> loadedPosts = data.map((postData) {
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'] ?? postData['contents'],
          datetime: DateTime.parse(postData['datetime']),
          userId: postData['creatorId'],
          initialLikes: postData['likes'],
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching three posts: $error");
      rethrow;
    }
  }
}