import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:experiment3/community/models/post.dart';
import 'package:experiment3/community/provider/post_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final newPost = Post(
      id: null,
      title: _titleController.text,
      content: _contentController.text,
      datetime: DateTime.now(),
      imgURL: _imgUrlController.text.isEmpty ? null : _imgUrlController.text,
      userId: Supabase.instance.client.auth.currentUser?.id,
      initialLikes: null,
    );

    try {
      await Provider.of<Posts>(context, listen: false).addPost(newPost);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.of(context).pop(true); // Return to the previous screen after adding
    } catch (error) {
      _showError('Failed to add post. Please try again. Error: $error');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imgUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitPost,
                child: const Text('Add Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imgUrlController.dispose();
    super.dispose();
  }
}