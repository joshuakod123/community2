// lib/community/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/bookmark_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/string_helpers.dart';
import '../utils/ui_helpers.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function(Post) onTap;
  final bool isInBookmarkScreen;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
    this.isInBookmarkScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final isBookmarked = post.id != null ? bookmarkProvider.isBookmarked(post.id!) : false;
    final daysRemaining = post.expirationDate != null ?
    postProvider.getDaysRemaining(post) : 7;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: post.isPinned ?
        const BorderSide(color: Colors.amber, width: 1.5) :
        BorderSide.none,
      ),
      child: InkWell(
        onTap: () => onTap(post),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  UserAvatar(
                    userId: post.creatorId ?? 'anonymous',
                    displayName: post.creatorId ?? 'Anonymous',
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.creatorId ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          post.datetime != null ?
                          DateFormatter.getTimeAgo(post.datetime!) :
                          'Unknown time',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            ),

            // Post Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Post Content Preview
            if (post.content != null && post.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  StringHelpers.getPreview(post.content, 100),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Post Image
            if (post.imgUrl != null && post.imgUrl!.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.infinity,
                child: Image.network(
                  post.imgUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),

            // Post Footer
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like count
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        StringHelpers.formatCount(post.likesCount),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  // Expiration info
                  if (post.expirationDate != null && !isInBookmarkScreen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(DateFormatter.getExpirationColor(post.expirationDate!)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormatter.getExpirationText(post.expirationDate!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Bookmark status
                  if (post.id != null)
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.amber : Colors.grey[600],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        if (isBookmarked) {
                          await bookmarkProvider.removeBookmark(post.id!);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                                context,
                                'Post removed from bookmarks'
                            );
                          }
                        } else {
                          await bookmarkProvider.addBookmark(post);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                                context,
                                'Post saved to bookmarks',
                                isSuccess: true
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}