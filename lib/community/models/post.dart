class Post {
  // Change the type to dynamic to accept both int and String
  final dynamic id;
  final String? title;
  final String? content;
  final DateTime? datetime;
  final String? imgURL;
  final String? userId;
  final int? initialLikes;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.datetime,
    this.imgURL,
    required this.userId,
    this.initialLikes,
  });
}