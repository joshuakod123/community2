// lib/community/providers/notification_provider.dart
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

  // Fetch notifications for current user
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

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('data->>user_id', userId) // Using JSONB query
          .order('created_at', ascending: false);

      final List<CommunityNotification> loadedNotifications = [];

      for (final notificationData in response) {
        loadedNotifications.add(CommunityNotification.fromJson(notificationData));
      }

      _notifications = loadedNotifications;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      print('Error fetching notifications: $error');

      // Try alternative query approach if the first one fails
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) {
          _isLoading = false;
          _errorMessage = "User not authenticated";
          notifyListeners();
          return;
        }

        // Get all notifications and filter locally
        final response = await _supabase
            .from('notifications')
            .select()
            .order('created_at', ascending: false);

        final List<CommunityNotification> loadedNotifications = [];

        for (final notificationData in response) {
          final notification = CommunityNotification.fromJson(notificationData);

          // Only include notifications for this user
          if (notification.data != null &&
              notification.data!['user_id'] == userId) {
            loadedNotifications.add(notification);
          }
        }

        _notifications = loadedNotifications;
        _isLoading = false;
        notifyListeners();
      } catch (secondError) {
        _isLoading = false;
        _errorMessage = secondError.toString();
        notifyListeners();
        print('Error with backup notification fetch: $secondError');
      }
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

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Update in Supabase - marking all of the user's notifications as read
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('data->>user_id', userId);

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

      // Try a different approach if the first one fails
      try {
        // Update local notifications at least
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

        // Try to update each notification individually
        for (final notification in _notifications) {
          if (notification.id != null) {
            await _supabase
                .from('notifications')
                .update({'is_read': true})
                .eq('id', notification.id as Object);
          }
        }

        return true;
      } catch (secondError) {
        print('Error with backup mark all read: $secondError');
        return false;
      }
    }
  }

  // Create a notification
  Future<bool> createNotification({
    required String title,
    required String body,
    required String userId,
    String? category,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create data object
      final Map<String, dynamic> data = {'user_id': userId};

      // Add any additional data
      if (additionalData != null) {
        data.addAll(additionalData);
      }

      // Insert notification
      await _supabase.from('notifications').insert({
        'title': title,
        'body': body,
        'category': category ?? 'general',
        'data': data,
      });

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

  // Delete all notifications
  Future<bool> deleteAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Delete all notifications for this user
      await _supabase
          .from('notifications')
          .delete()
          .eq('data->>user_id', userId);

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