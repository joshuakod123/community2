import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<CommunityNotification> _notifications = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunityNotification> get notifications => [..._notifications];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Fetch notifications for current user - simplified query with proper formatting
  Future<void> fetchNotifications() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _isLoading = false;
        _errorMessage = "User not authenticated";
        notifyListeners();
        return;
      }

      // Direct query without using jsonb operators that might cause issues
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      final List<CommunityNotification> loadedNotifications = [];

      // Filter locally instead of using problematic jsonb queries
      for (final notificationData in response) {
        final notification = CommunityNotification.fromJson(notificationData);

        // Only include notifications for this user
        if (notification.data != null &&
            notification.data is Map &&
            notification.data!['user_id'] == userId) {
          loadedNotifications.add(notification);
        }
      }

      _notifications = loadedNotifications;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      print('Error fetching notifications: $error');
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      // Update in Supabase
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        final updatedNotification = CommunityNotification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          category: _notifications[index].category,
          data: _notifications[index].data,
          createdAt: _notifications[index].createdAt,
          isRead: true,
        );

        _notifications[index] = updatedNotification;
        notifyListeners();
      }

      return true;
    } catch (error) {
      print('Error marking notification as read: $error');
      return false;
    }
  }

  // Mark all notifications as read - simplified approach without jsonb queries
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Update individual notifications one by one
      for (final notification in _notifications) {
        if (notification.id != null && !notification.isRead) {
          await _supabase
              .from('notifications')
              .update({'is_read': true})
              .eq('id', notification.id as Object);
        }
      }

      // Update all local notifications
      _notifications = _notifications.map((notification) {
        return CommunityNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          category: notification.category,
          data: notification.data,
          createdAt: notification.createdAt,
          isRead: true,
        );
      }).toList();

      notifyListeners();
      return true;
    } catch (error) {
      print('Error marking all notifications as read: $error');
      return false;
    }
  }

  // Create a notification - simplified to avoid jsonb parsing issues
  Future<bool> createNotification({
    required String title,
    required String body,
    required String userId,
    String? category,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create flat data structure to avoid JSON parsing issues
      Map<String, dynamic> notificationData = {
        'title': title,
        'body': body,
        'category': category ?? 'general',
        'data': {'user_id': userId},  // Simplified JSON structure
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add any additional non-nested data
      if (additionalData != null) {
        notificationData['data']['post_id'] = additionalData['post_id'];
      }

      // Insert notification using simplified data structure
      await _supabase.from('notifications').insert(notificationData);

      return true;
    } catch (error) {
      print('Error creating notification: $error');
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();

      return true;
    } catch (error) {
      print('Error deleting notification: $error');
      return false;
    }
  }

  // Delete all notifications for current user - simplified
  Future<bool> deleteAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Delete notifications one by one using IDs
      for (final notification in _notifications) {
        if (notification.id != null) {
          await _supabase
              .from('notifications')
              .delete()
              .eq('id', notification.id as Object);
        }
      }

      // Clear local list
      _notifications = [];
      notifyListeners();

      return true;
    } catch (error) {
      print('Error deleting all notifications: $error');
      return false;
    }
  }
}