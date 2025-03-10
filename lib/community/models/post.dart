// lib/community/models/post.dart
class Post {
  // Change the type to dynamic to accept both int and String
  final dynamic id;
  final String? title;
  final String? content;
  final DateTime? datetime;
  final String? imgURL;
  final String? userId;
  final int? initialLikes;
  final DateTime? expirationDate; // Add expiration date field

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.datetime,
    this.imgURL,
    required this.userId,
    this.initialLikes,
    this.expirationDate, // Initialize expiration date
  });
}