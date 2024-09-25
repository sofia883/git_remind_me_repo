import 'package:flutter/material.dart';
import 'package:remind_me/services/notifi_service.dart';
import 'dart:async';
import 'package:remind_me/services/reminder_utils.dart';

import 'expired_reminders.dart';
import 'package:remind_me/screens/create_reminders.dart';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:remind_me/screens/added_reminders.dart';
import 'package:remind_me/services/search_service.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void printHello() {
  final DateTime now = DateTime.now();
  print("[$now] Hello, world! Alarm triggered.");
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> expiredReminders = [];
  List<Map<String, String>> filteredReminders = [];
  Timer? _timer;
  bool _isLoading = true;
  Map<String, String>? mostUpcomingReminder;
  String remainingTime = '';
  Timer? _remainingTimeTimer;
  final ReminderUtils reminderUtils = ReminderUtils();
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> searchResults = [];
  bool _showSearchResults = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Map<String, String>? highlightedReminder;
  @override
  void initState() {
    super.initState();
    _loadReminders();
    _scheduleNextExpirationCheck();
    _startUpdatingRemainingTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingTimeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        _showSearchResults = false;
      });
    } else {
      setState(() {
        searchResults = ReminderUtils.searchReminders(
          query,
          reminders,
          expiredReminders,
        );
        _showSearchResults = true;
      });
    }
  }

  void handleReminderTap(BuildContext context, Map<String, String> reminder,
      bool isExpired, bool isMostUpcoming) {
    setState(() {
      highlightedReminder = reminder;
    });

    onReminderTap(context, reminder, isExpired, isMostUpcoming);
  }

  void onReminderTap(BuildContext context, Map<String, String> reminder,
      bool isExpired, bool isMostUpcoming) {
    if (isExpired) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExpiredRemindersPage(
            expiredReminders: expiredReminders,
            highlightedReminder:
                reminder, // Ensure the correct reminder is passed
            onRestore: (restoredReminder) {
              setState(() {
                reminders.add(restoredReminder);
                expiredReminders.remove(restoredReminder);
                _saveReminders();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reminder restored')),
              );
            },
          ),
        ),
      );
    } else if (isMostUpcoming) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddedRemindersPage(
            highlightedReminder:
                reminder, // Ensure the correct reminder is passed
            onEdit: (updatedReminder) {
              // ... (existing code)
            },
            onDelete: (deletedReminder) {
              setState(() {
                reminders.removeWhere((r) => r['id'] == deletedReminder['id']);
                _saveReminders();
              });
            },
          ),
        ),
      );
    }
  }

  void _startUpdatingRemainingTime() {
    if (mounted) {
      _updateRemainingTime();
    }
    _remainingTimeTimer =
        Timer.periodic(Duration(seconds: 1), (_) => _updateRemainingTime());
  }

  void _updateRemainingTime() {
    if (mostUpcomingReminder != null) {
      if (mounted) {
        setState(() {
          remainingTime =
              ReminderUtils.calculateRemainingTime(mostUpcomingReminder!);
        });
      }
    }
  }

  void _scheduleNextExpirationCheck() {
    DateTime now = DateTime.now();
    DateTime nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .add(Duration(minutes: 1));
    Duration durationUntilNextMinute = nextMinute.difference(now);

    _timer = Timer(durationUntilNextMinute, () {
      _processExpiredReminders();
      _scheduleNextExpirationCheck();
    });
  }

  Future<void> _loadReminders() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading

    List<List<Map<String, String>>> loadedReminders =
        await ReminderUtils.loadReminders();

    setState(() {
      reminders = loadedReminders[0];
      expiredReminders = loadedReminders[1];
      mostUpcomingReminder = ReminderUtils.getMostUpcomingReminder(reminders);
      _isLoading = false;
      _updateRemainingTime();
    });

    print('Reminders loaded: $reminders');
    print('Expired reminders loaded: $expiredReminders');
    print('Most upcoming reminder: $mostUpcomingReminder');

    _processExpiredReminders();
  }

  Future<void> _showLoadingIndicator() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }

  void _processExpiredReminders() {
    List<Map<String, String>> activeReminders = [];
    List<Map<String, String>> expired = [];
    ReminderUtils.processExpiredReminders(reminders, expiredReminders);

    for (var reminder in reminders) {
      String remainingTime = ReminderUtils.calculateRemainingTime(reminder);
      if (remainingTime == 'Expired') {
        expired.add(reminder);
      } else {
        activeReminders.add(reminder);
      }
    }

    setState(() {
      reminders = activeReminders;
      expiredReminders.addAll(expired);
      mostUpcomingReminder = ReminderUtils.getMostUpcomingReminder(reminders);
      _saveReminders();
    });
  }

  Future<void> _saveReminders() async {
    await ReminderUtils.saveReminders(reminders, expiredReminders);
  }

  void _confirmDeleteReminder(int index) async {
    final result = await ReminderUtils.confirmDeleteReminder(context);
    if (result) {
      setState(() {
        reminders.removeAt(index);
        _saveReminders();
      });
    }
  }

  Future<void> _editReminder(int index) async {
    await ReminderUtils.editReminder(
      context,
      reminders[index],
      (updatedReminder) {
        setState(() {
          reminders[index] = updatedReminder;
          filteredReminders = List.from(reminders);
          mostUpcomingReminder =
              ReminderUtils.getMostUpcomingReminder(reminders);
          _saveReminders();
        });
      },
    );
  }

  void _logout() {
    ReminderUtils.showConfirmationSnackbar(context, () async {
      await ReminderUtils.showLoadingIndicatorWithBlur(context);
      ReminderUtils.navigateToLoginPage(context);
    });
  }

  void _navigateToExpiredReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpiredRemindersPage(
          expiredReminders: expiredReminders,
          highlightedReminder:
              highlightedReminder, // Pass the highlightedReminder
          onRestore: (restoredReminder) {
            setState(() {
              // Add the restored reminder back to the active reminders list
              reminders.add(restoredReminder);

              // Remove the restored reminder from the expired reminders list
              expiredReminders.remove(restoredReminder);

              // Save the updated lists
              _saveReminders();
            });

            // Show a confirmation message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reminder restored')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime scheduledTime = DateTime.now()
        .add(Duration(seconds: 10)); // Ensure this is in the future

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/
        1000; // Unique ID for the notification
    String title = 'Reminder Title';
    String body = ' not solved yetdddd? is it';
    String payload = jsonEncode({'key': 'value'}); // Pass any data
    String repeatOption =
        'Every 5 seconds'; // Options: 'None', 'Every 5 seconds', etc.
    String actionId = "cancel"; // Action ID for canceling the notification
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.white),
            onPressed: () async {
              print(
                  'Scheduled notification at: $scheduledTime'); // For debugging

              await NotificationService.scheduleNotification(
                scheduledTime,
                notificationId,
                title,
                body,
                payload,
                repeatOption,
                actionId,
              );
            },
            tooltip: 'Cancel Upcoming Reminder Notification',
          ),
          ElevatedButton(
            onPressed: () {
              // Cancel the notification with the specified ID
              NotificationService.cancelNotificationAndAlarm(notificationId);
            },
            child: Text('Cancel Notification'),
          ),
          Container(
            margin: EdgeInsets.only(right: 0),
            child: IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpiredRemindersPage(
                      expiredReminders: expiredReminders,
                      highlightedReminder: highlightedReminder,
                      onRestore: (restoredReminder) {
                        setState(() {
                          reminders.add(restoredReminder);
                          expiredReminders.remove(restoredReminder);
                          _saveReminders();
                        });
                      },
                    ),
                  ),
                );
              },
              tooltip: 'View expired reminders',
            ),
          ),
        ],
        backgroundColor: Color.fromARGB(255, 42, 41, 41),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.elliptical(180, 40),
          ),
        ),
        toolbarHeight: 140,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remind Me',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reminders...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _handleSearch,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildNormalView(),
          ),
          if (_showSearchResults)
            Positioned.fill(
              child: SearchResultsOverlay(
                searchResults: searchResults,
                searchQuery: _searchController.text,
                onTap: handleReminderTap,
                allReminders: reminders,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          // LocalNotifications.showNotification(
          //     id: 1,
          //     title: 'testing',
          //     body: 'test the notification',
          //     payload: 'action button',
          //     repeatOption: 'Every 5 seconds');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReminderPage(
                onReminderSaved: () {
                  _loadReminders();
                  _showLoadingIndicator();
                },
              ),
            ),
          );
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        tooltip: 'Create Reminder',
      ),
    );
  }

  Widget _buildNormalView() {
    return reminders.isEmpty
        ? Center(
            child: Text(
              'No reminders available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          )
        : ListView(
            children: [
              if (mostUpcomingReminder != null)
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Next reminder is in ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: remainingTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(35.0),
                          ),
                          width: double.infinity,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35.0),
                            ),
                            surfaceTintColor: Colors.white,
                            shadowColor: Colors.orange,
                            elevation: 14,
                            margin: EdgeInsets.all(1.0),
                            child: InkWell(
                              onTap: () => _editReminder(
                                  reminders.indexOf(mostUpcomingReminder!)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mostUpcomingReminder!['title'] ??
                                          'No Title',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      mostUpcomingReminder!['description'] ??
                                          'No description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    if (mostUpcomingReminder!
                                        .containsKey('date'))
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_month, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'Date: ${mostUpcomingReminder!['date']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 5),
                                    if (mostUpcomingReminder!
                                        .containsKey('time'))
                                      Row(
                                        children: [
                                          Icon(Icons.timer, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'Time: ${mostUpcomingReminder!['time']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 5),
                                    if (mostUpcomingReminder!
                                        .containsKey('scheduledTime'))
                                      Text(
                                        'Scheduled Time: ${mostUpcomingReminder!['scheduledTime']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
  }
}
