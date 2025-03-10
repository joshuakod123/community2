// lib/community/models/bookmark.dart
class Bookmark {
  final dynamic id;
  final dynamic postId;
  final String? userId;
  final DateTime? savedAt;
  final bool isDeleted;
  final String? localPostData; // JSON string of post data for local storage

  Bookmark({
    this.id,
    required this.postId,
    required this.userId,
    this.savedAt,
    this.isDeleted = false,
    this.localPostData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'postId': postId?.toString(),
      'userId': userId,
      'savedAt': savedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'localPostData': localPostData,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      savedAt: json['savedAt'] != null ?
      DateTime.parse(json['savedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      localPostData: json['localPostData'],
    );
  }
}