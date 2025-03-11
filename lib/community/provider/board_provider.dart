import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:experiment3/community/models/post.dart';

class PostList with ChangeNotifier {
  List<Post> _items = [];
  late final SupabaseClient supabaseClient;

  PostList(this.supabaseClient);

  List<Post> get items {
    return [..._items];
  }

  Future<void> fetchAndSetPosts() async {
    try {
      // Query the 'posts' table
      final response = await supabaseClient
          .from('posts')
          .select();

      final data = response as List<dynamic>;

      final List<Post> loadedPosts = data.map((postData) {
        // We keep the id as is (can be string or int) since our Post model now accepts dynamic
        return Post(
          id: postData['id'],
          title: postData['title'],
          content: postData['content'],
          datetime: postData['datetime'] != null
              ? DateTime.parse(postData['datetime'])
              : null,
          imgURL: postData['imgURL'],
          userId: postData['creatorId'],
          initialLikes: postData['likes'] != null ?
          (postData['likes'] is int ? postData['likes'] :
          int.tryParse(postData['likes'].toString()) ?? 0) : 0,
        );
      }).toList();

      _items = loadedPosts;
      notifyListeners();
    } catch (error) {
      print("Error fetching posts: $error");
      throw (error);
    }
  }
}