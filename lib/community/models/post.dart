// lib/community/models/post.dart
class Post {
  final int? id;
  final String title;
  final String? content;
  final DateTime? datetime;
  final String? imgUrl; // Match database column img_url
  final String? creatorId; // Match database column creator_id
  final int likesCount;
  final DateTime? expirationDate;
  final bool isPinned;
  final String? category;

  Post({
    this.id,
    required this.title,
    this.content,
    this.datetime,
    this.imgUrl,
    this.creatorId,
    this.likesCount = 0,
    this.expirationDate,
    this.isPinned = false,
    this.category,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      content: json['content'],
      datetime: json['datetime'] != null ? DateTime.parse(json['datetime']) : null,
      imgUrl: json['img_url'], // Updated from imgUrl to img_url
      creatorId: json['creator_id'], // Updated from creatorId to creator_id
      likesCount: json['likes'] ?? 0,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      isPinned: json['is_pinned'] ?? false, // Updated from isPinned to is_pinned
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'datetime': datetime?.toIso8601String(),
      'img_url': imgUrl, // Updated to match database column name
      'creator_id': creatorId, // Updated to match database column name
      'likes': likesCount,
      'expiration_date': expirationDate?.toIso8601String(),
      'is_pinned': isPinned, // Updated to match database column name
      'category': category,
    };
  }

  Post copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? datetime,
    String? imgUrl,
    String? creatorId,
    int? likesCount,
    DateTime? expirationDate,
    bool? isPinned,
    String? category,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      datetime: datetime ?? this.datetime,
      imgUrl: imgUrl ?? this.imgUrl,
      creatorId: creatorId ?? this.creatorId,
      likesCount: likesCount ?? this.likesCount,
      expirationDate: expirationDate ?? this.expirationDate,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
    );
  }
}