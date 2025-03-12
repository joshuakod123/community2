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
  final DateTime? expirationDate; // Expiration date field for auto-deletion

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

  // Add factory method to create from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      datetime: json['datetime'] != null ? DateTime.parse(json['datetime']) : null,
      imgURL: json['imgURL'],
      userId: json['userId'],
      initialLikes: json['initialLikes'],
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'title': title,
      'content': content,
      'datetime': datetime?.toIso8601String(),
      'imgURL': imgURL,
      'userId': userId,
      'initialLikes': initialLikes,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }
}