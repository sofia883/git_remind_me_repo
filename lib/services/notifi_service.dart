import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

final logger = Logger();

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final Set<int> _scheduledAlarms = {};
  // Initialize the local notification plugin
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification response received: ${response.actionId}');

        // Check if the cancel action was pressed
        if (response.actionId == 'cancel') {
          print('Cancel action pressed');
          cancelNotificationAndAlarm(response.id); // Call the cancel function
        } else {
          // Handle tapping on the body (if needed)
          print('Notification body tapped, ID: ${response.id}');
          cancelNotificationAndAlarm(
              response.id); // Optionally cancel on body tap as well
        }
      },
    );
  }

  static Future<void> showNotificationWithActions(
      int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel name
      channelDescription: 'This channel is used for reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      // Define action buttons
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'cancel', // The action ID
          'Cancel',
          showsUserInterface:
              false, // This should allow the user to see the action
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'cancel', // Set payload to identify cancel action (optional)
    );
  }

  static void cancelNotificationAndAlarm(int? id) async {
    if (id != null) {
      try {
        await _flutterLocalNotificationsPlugin.cancel(id);
        _scheduledAlarms.remove(id); // Remove from scheduled alarms
        print('Notification with id $id cancelled.');
      } catch (e) {
        print('Error canceling notification: $e');
      }
    } else {
      print('Cannot cancel notification: ID is null');
    }
  }

  // Create notification channel for Android 8.0+
  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel name
      description: 'This channel is used for reminder notifications',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Schedule a notification using Alarm Manager with optional repeat
  // Schedule a notification using Alarm Manager with optional repeat

  static Future<void> scheduleNotification(
      DateTime scheduledTime,
      int notificationId,
      String title,
      String body,
      String payload,
      String repeatOption,
      String actionId) async {
    if (!_scheduledAlarms.contains(notificationId)) {
      _scheduledAlarms.add(notificationId);
      // Schedule the notification as before
    } else {
      print('Notification $notificationId already scheduled.');
    }
  }

// This callback will be invoked when the alarm triggers
  static Future<void> _showNotificationCallback(
      int id, Map<String, dynamic> params) async {
    print('_showNotificationCallback called');

    // Extract the parameters from the alarm
    String title = params['title'];
    String body = params['body'];
    String payload = params['payload'];
    String repeatOption = params['repeatOption'];
    String actionId = params['actionId']; // Extract action ID

    // Show the notification when the alarm triggers
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
                actionId, 'Cancel Alarm'), // Use the action ID here
          ],
        ),
      ),
      payload: payload,
    );

    // Handle repeat option
    if (repeatOption != 'None') {
      DateTime nextTime = getNextScheduledTime(repeatOption);
      await scheduleNotification(
        nextTime,
        id,
        title,
        body,
        payload,
        repeatOption,
        actionId, // Pass action ID for repeat
      );
    }
  }

  // Show notification immediately
  static Future<void> showNotification(
      int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'your_channel_id', // Channel ID
            'your_channel_name', // Channel name
            channelDescription:
                'This channel is used for reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: false);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
        id, title, body, platformChannelSpecifics);
  }

  // This callback will be invoked when the alarm triggers
// This callback will be invoked when the alarm triggers
  // static Future<void> _showNotificationCallback(
  //     int id, Map<String, dynamic> params) async {
  //   print('_showNotificationCallback called');

  //   // Extract the parameters from the alarm
  //   String title = params['title'];
  //   String body = params['body'];
  //   String payload = params['payload'];
  //   String repeatOption = params['repeatOption'];

  //   // Show the notification when the alarm triggers
  //   await _flutterLocalNotificationsPlugin.show(
  //     id,
  //     title,
  //     body,
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'your_channel_id',
  //         'your_channel_name',
  //         importance: Importance.max,
  //         priority: Priority.high,
  //         actions: <AndroidNotificationAction>[
  //           AndroidNotificationAction('cancel', 'Cancel Alarm'),
  //           // Add any other actions you want
  //         ],
  //       ),
  //     ),
  //     payload: payload,
  //   );

  //   // Handle the action button tap);

  //   // Handle repeat option
  //   if (repeatOption != 'None') {
  //     DateTime nextTime = getNextScheduledTime(repeatOption);
  //     await scheduleNotification(
  //       nextTime,
  //       id,
  //       title,
  //       body,
  //       payload,
  //       repeatOption,
  //     );
  //   }
  // }

  // Calculate the next scheduled time based on repeat option
  static DateTime getNextScheduledTime(String repeatOption) {
    DateTime now = DateTime.now();
    switch (repeatOption) {
      case 'Every 5 seconds':
        return now.add(Duration(seconds: 5));
      case 'Every 5 minutes':
        return now.add(Duration(minutes: 5));
      case 'Every 10 minutes':
        return now.add(Duration(minutes: 10));
      case 'Every 30 minutes':
        return now.add(Duration(minutes: 30));
      case 'Every day':
        return now.add(Duration(days: 1));
      case 'Every week':
        return now.add(Duration(days: 7));
      case 'Every month':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return now; // No repetition
    }
  }
}
