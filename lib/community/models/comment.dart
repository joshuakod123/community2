class Comment {
  final int? id;
  final int? postId;
  final String? contents;
  final DateTime? datetime;
  final String? userId;

  Comment({
    required this.id,
    required this.postId,
    required this.contents,
    required this.datetime,
    required this.userId
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      contents: json['text'],
      datetime: json['datetime'],
      userId: json['user_id'],
    );
  }
}