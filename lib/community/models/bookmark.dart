// lib/community/models/bookmark.dart
class Bookmark {
  final int? id;
  final int postId;
  final String userId;
  final DateTime? savedAt;
  final bool isDeleted;
  final String? localPostData;  // JSON string for local storage

  Bookmark({
    this.id,
    required this.postId,
    required this.userId,
    this.savedAt,
    this.isDeleted = false,
    this.localPostData,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      savedAt: json['saved_at'] != null ? DateTime.parse(json['saved_at']) : null,
      isDeleted: json['is_deleted'] ?? false,
      localPostData: json['local_post_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'saved_at': savedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'local_post_data': localPostData,
    };
  }
}