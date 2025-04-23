// lib/community/screen/edit_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../utils/ui_helpers.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageUrlController;
  String? _selectedCategory;
  bool _isPinned = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Question',
    'Announcement',
    'Suggestion',
    'Event',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing post data
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content ?? '');
    _imageUrlController = TextEditingController(text: widget.post.imgUrl ?? '');
    _selectedCategory = widget.post.category;
    _isPinned = widget.post.isPinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);

      final updatedPost = Post(
        id: widget.post.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imgUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        category: _selectedCategory,
        isPinned: _isPinned,
        creatorId: widget.post.creatorId,
        datetime: widget.post.datetime,
        likesCount: widget.post.likesCount,
        expirationDate: widget.post.expirationDate,
      );

      final success = await postProvider.updatePost(updatedPost);

      if (success && mounted) {
        UIHelpers.showSnackBar(
          context,
          'Post updated successfully!',
          isSuccess: true,
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      } else if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Failed to update post',
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (error) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Error updating post: ${error.toString()}',
          isError: true,
        );

        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _updatePost,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a descriptive title',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Write your post content here',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
            ),

            const SizedBox(height: 16),

            // Image URL field
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'Enter a URL to an image to include',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),

            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Pin post checkbox
            CheckboxListTile(
              title: const Text('Pin this post to the top'),
              subtitle: const Text('Pinned posts will appear at the top of the board'),
              value: _isPinned,
              onChanged: (value) {
                setState(() {
                  _isPinned = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // Submit button for mobile users (in addition to app bar button)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _updatePost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'SAVE CHANGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Info about expiration
            if (widget.post.expirationDate != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Post Expiration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This post will expire on ${widget.post.expirationDate!.toLocal().toString().split(' ')[0]}. '
                            'You can extend the expiration date from the post details screen.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}