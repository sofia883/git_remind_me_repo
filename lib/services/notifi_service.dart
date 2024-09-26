import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:remind_me/services/reminder_utils.dart';

final logger = Logger();

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final Set<int> _scheduledAlarms = {};

  // Initialize the local notification plugin
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        logger.d('Notification response received: ${response.actionId}');

        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction) {
          if (response.actionId == 'cancel') {
            logger
                .i('Cancel action pressed for notification ID: ${response.id}');
            await cancelNotificationAndAlarm(response.id);
          }
        } else {
          await cancelNotificationAndAlarm(response.id);
          logger.d('Notification body tapped, ID: ${response.id}');
          // Do nothing when the notification body is tapped
        }
      },
    );
  }

  static Future<void> showNotificationWithActions(
      int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'This channel is used for reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'cancel',
          'Cancel',
          showsUserInterface: false, // This prevents the app from opening
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
    );
  }

  static Future<void> cancelNotificationAndAlarm(int? id) async {
    if (id != null) {
      try {
        await _flutterLocalNotificationsPlugin.cancel(id);
        await AndroidAlarmManager.cancel(id);
        _scheduledAlarms.remove(id);
        logger.i('Notification and alarm with id $id cancelled.');
      } catch (e) {
        logger.e('Error canceling notification and alarm: $e');
      }
    } else {
      logger.w('Cannot cancel notification and alarm: ID is null');
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
    // New parameter for action ID
    print('scheduleNotification called');
    bool canShowNotification = await ReminderUtils.shouldShowNotifications();

    // Schedule alarm with AlarmManager
    if (canShowNotification) {
      await AndroidAlarmManager.oneShotAt(
          scheduledTime, notificationId, _showNotificationCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'notificationId': notificationId,
            'title': title,
            'body': body,
            'payload': payload,
            'repeatOption': repeatOption,
            'actionId': actionId, // Add action ID to params
          });
    } else {
      print('Notification not shown due to user preference');
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
    bool canShowNotification = await ReminderUtils.shouldShowNotifications();
    if (canShowNotification) {
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
    } else {
      print('Notification not shown due to user preference');
    }
  }

  // Show notification immediately

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
