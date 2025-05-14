// lib/community/models/notification.dart
class CommunityNotification {
  final int? id;
  final String title;
  final String? body;
  final String? category;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final bool isRead;

  CommunityNotification({
    this.id,
    required this.title,
    this.body,
    this.category,
    this.data,
    this.createdAt,
    this.isRead = false,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedData;

    // Handle possible data formats safely
    if (json['data'] != null) {
      try {
        if (json['data'] is String) {
          // Try to parse string as JSON if needed
          parsedData = Map<String, dynamic>.from(json['data'] as Map<String, dynamic>);
        } else if (json['data'] is Map) {
          // Direct map usage if already parsed
          parsedData = Map<String, dynamic>.from(json['data']);
        }
      } catch (e) {
        print('Error parsing notification data: $e');
        parsedData = {'error': 'Failed to parse data'};
      }
    }

    return CommunityNotification(
      id: json['id'],
      title: json['title'] ?? 'New Notification',
      body: json['body'],
      category: json['category'],
      data: parsedData,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'data': data,
      'created_at': createdAt?.toIso8601String(),
      'is_read': isRead,
    };
  }
}