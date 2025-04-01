// lib/community/models/comment.dart
class Comment {
  final int? id;
  final int postId;
  final String contents;
  final DateTime? datetime;
  final String? userId;
  final String? userDisplayName;

  Comment({
    this.id,
    required this.postId,
    required this.contents,
    this.datetime,
    this.userId,
    this.userDisplayName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      contents: json['contents'] ?? '',
      datetime: json['datetime'] != null ? DateTime.parse(json['datetime']) : null,
      userId: json['user_id'],
      userDisplayName: json['user_display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'contents': contents,
      'datetime': datetime?.toIso8601String(),
      'user_id': userId,
    };
  }
}