import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarService {
  // Singleton pattern
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  // Data structure to hold events
  Map<String, List<Map<String, dynamic>>> _events = {};

  // Get events for a specific date
  List<Map<String, dynamic>> getEventsForDay(DateTime date) {
    final dateKey = _formatDateKey(date);
    return _events[dateKey] ?? [];
  }

  // Get all events
  Map<String, List<Map<String, dynamic>>> getAllEvents() {
    return _events;
  }

  // Load events from storage
  Future<void> loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('taskData');

      if (storedData != null && storedData.isNotEmpty) {
        final decodedData = json.decode(storedData) as Map<String, dynamic>;

        _events = decodedData.map((key, value) =>
            MapEntry(key, List<Map<String, dynamic>>.from(
                value.map((task) => Map<String, dynamic>.from(task))
            )));
      } else {
        _events = {};
      }
    } catch (e) {
      print('Error loading events: $e');
      _events = {};
    }
  }

  // Add a new event
  Future<bool> addEvent({
    required DateTime date,
    required String title,
    required String description,
    required TimeOfDay time,
    Color color = Colors.blue,
  }) async {
    final dateKey = _formatDateKey(date);

    // Create event object
    final newEvent = {
      'title': title,
      'description': description,
      'time': _formatTimeOfDay(time),
      'color': color.value.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Add to local data structure
    if (!_events.containsKey(dateKey)) {
      _events[dateKey] = [];
    }
    _events[dateKey]!.add(newEvent);

    // Save to storage
    return await _saveEvents();
  }

  // Delete an event
  Future<bool> deleteEvent(DateTime date, int eventIndex) async {
    final dateKey = _formatDateKey(date);

    if (_events.containsKey(dateKey) &&
        _events[dateKey]!.length > eventIndex) {
      _events[dateKey]!.removeAt(eventIndex);

      // If no events left for this date, remove the date entry
      if (_events[dateKey]!.isEmpty) {
        _events.remove(dateKey);
      }

      return await _saveEvents();
    }
    return false;
  }

  // Update an event
  Future<bool> updateEvent({
    required DateTime date,
    required int eventIndex,
    String? title,
    String? description,
    TimeOfDay? time,
    Color? color,
  }) async {
    final dateKey = _formatDateKey(date);

    if (_events.containsKey(dateKey) &&
        _events[dateKey]!.length > eventIndex) {

      final event = _events[dateKey]![eventIndex];

      // Update fields if new values provided
      if (title != null) event['title'] = title;
      if (description != null) event['description'] = description;
      if (time != null) event['time'] = _formatTimeOfDay(time);
      if (color != null) event['color'] = color.value.toString();

      return await _saveEvents();
    }
    return false;
  }

  // Save events to storage
  Future<bool> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taskData', json.encode(_events));
      return true;
    } catch (e) {
      print('Error saving events: $e');
      return false;
    }
  }

  // Format date to string key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    final displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$displayHour:$minute $period';
  }
}