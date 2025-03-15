// lib/community/widgets/comment_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import '../providers/comment_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/ui_helpers.dart';
import 'user_avatar.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({
    Key? key,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId == comment.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  userId: comment.userId ?? 'anonymous',
                  displayName: comment.userDisplayName ?? 'Anonymous',
                  size: 32,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userDisplayName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.datetime != null)
                        Text(
                          DateFormatter.getTimeAgo(comment.datetime!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOwner)
                  _buildDeleteButton(context),
              ],
            ),

            // Comment Content
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                comment.contents,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.delete_outline,
        size: 18,
        color: Colors.grey[600],
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        final shouldDelete = await UIHelpers.showConfirmationDialog(
          context: context,
          title: 'Delete Comment',
          message: 'Are you sure you want to delete this comment?',
          confirmText: 'Delete',
          isDestructive: true,
        );

        if (shouldDelete && comment.id != null) {
          final commentProvider = Provider.of<CommentProvider>(context, listen: false);

          try {
            UIHelpers.showLoadingDialog(context, 'Deleting comment...');

            final success = await commentProvider.deleteComment(comment.id!);

            if (context.mounted) {
              Navigator.of(context).pop(); // Close loading dialog

              if (success) {
                UIHelpers.showSnackBar(
                  context,
                  'Comment deleted successfully',
                  isSuccess: true,
                );
              } else {
                UIHelpers.showSnackBar(
                  context,
                  'Failed to delete comment',
                  isError: true,
                );
              }
            }
          } catch (error) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Close loading dialog
              UIHelpers.showSnackBar(
                context,
                'Error: ${error.toString()}',
                isError: true,
              );
            }
          }
        }
      },
    );
  }
}