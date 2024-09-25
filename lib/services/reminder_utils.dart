import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:remind_me/screens/profile_page.dart';
import 'dart:ui';
import 'package:remind_me/services/notifi_service.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
class ReminderUtils {
  List<Reminder> reminders = []; // Your list of active reminders
  List<Reminder> expiredReminders = []; // Your list of expired reminders

  // Search method to filter reminders based on the query

  static String calculateRemainingTime(Map<String, String> reminder) {
    DateTime? reminderDateTime =
        parseDateTime(reminder['date']!, reminder['time']!);
    if (reminderDateTime == null) {
      return 'Invalid date/time';
    }

    Duration remaining = reminderDateTime.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired';
    }

    DateTime now = DateTime.now();
    int years = (reminderDateTime.year - now.year) -
        ((now.month > reminderDateTime.month ||
                (now.month == reminderDateTime.month &&
                    now.day > reminderDateTime.day))
            ? 1
            : 0);
    int days = remaining.inDays % 365;
    int hours = remaining.inHours % 24;
    int minutes = remaining.inMinutes % 60;
    int seconds = remaining.inSeconds % 60;

    List<String> timeParts = [];

    if (years > 0) {
      timeParts.add('$years year${years > 1 ? 's' : ''}');
    }
    if (days > 0 || years > 0) {
      timeParts.add('$days day${days > 1 ? 's' : ''}');
    }
    if (hours > 0 || days > 0 || years > 0) {
      timeParts.add('$hours hour${hours > 1 ? 's' : ''}');
    }
    if (minutes > 0 || hours > 0 || days > 0 || years > 0) {
      timeParts.add('$minutes min');
    }
    if (seconds > 0 || minutes > 0 || hours > 0 || days > 0 || years > 0) {
      timeParts.add('$seconds sec');
    }

    return timeParts.join(', ');
  }

  static void startUpdatingRemainingTime(Map<String, String> reminder,
      Function(String) onUpdate, Function(Map<String, String>) onRemove) {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      String remainingTime = calculateRemainingTime(reminder);
      onUpdate(remainingTime);

      if (remainingTime == 'Expired') {
        onRemove(
            reminder); // Call the onRemove function to remove the expired reminder
        timer.cancel();
      }
    });
  }

  static Future<void> saveReminders(List<Map<String, String>> reminders,
      List<Map<String, String>> expiredReminders) async {
    // Show loading indicator for 1 second
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData =
        reminders.map((reminder) => jsonEncode(reminder)).toList();
    List<String> expiredRemindersData =
        expiredReminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersData);
    await prefs.setStringList('expiredReminders', expiredRemindersData);
  }

  static Future<List<List<Map<String, String>>>> loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> remindersData = prefs.getStringList('reminders') ?? [];
    List<String> expiredRemindersData =
        prefs.getStringList('expiredReminders') ?? [];

    List<Map<String, String>> loadedReminders = remindersData
        .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
        .toList();
    List<Map<String, String>> loadedExpiredReminders = expiredRemindersData
        .map((reminder) => Map<String, String>.from(jsonDecode(reminder)))
        .toList();

    return [loadedReminders, loadedExpiredReminders];
  }

  static final List<String> _repeatOptions = [
    'None',
    'Every 5 seconds',
    'Every 5 minutes',
    'Every 10 minutes',
    'Every 30 minutes',
    'Every day',
    'Every week',
    'Every month'
  ];
  static DateTime? parseDateTime(String date, String time) {
    try {
      DateTime parsedDate = DateFormat('d MMMM yyyy').parse(date);

      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1].split(' ')[0]);

      if (time.toLowerCase().contains('pm') && hour != 12) {
        hour += 12;
      } else if (time.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      }

      return DateTime(
          parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
    } catch (e) {
      print('Error parsing date or time: $e');
      return null;
    }
  }

  static Future<void> selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('d MMMM yyyy').format(pickedDate);
    }
  }

  static Future<void> selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay initialTime = TimeOfDay(hour: now.hour, minute: now.minute);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      controller.text = pickedTime.format(context);
    }
  }

  static Future<bool> confirmDeleteReminder(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Delete Reminder'),
              content: Text('Are you sure you want to delete this reminder?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<void> editReminder(
    BuildContext context,
    Map<String, String> reminder,
    Function(Map<String, String>) onSave,
  ) async {
    final titleController = TextEditingController(text: reminder['title']);
    final descriptionController =
        TextEditingController(text: reminder['description']);
    final dateController = TextEditingController(text: reminder['date']);
    final timeController = TextEditingController(text: reminder['time']);
    final repeatIntervalController =
        TextEditingController(text: reminder['repeatInterval']);
    final List<String> repeatOptions = [
      'None',
      'Every 5 seconds',
      'Every 5 minutes',
      'Every 10 minutes',
      'Every 30 minutes',
      'Every day',
      'Every week',
      'Every month'
    ];
    String? selectedRepeatOption = reminder['repeat'];

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Edit Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  GestureDetector(
                    onTap: () => selectDate(context, dateController),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => selectTime(context, timeController),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: timeController,
                        decoration: InputDecoration(
                          labelText: 'Time',
                          suffixIcon: Icon(Icons.access_time_filled),
                        ),
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedRepeatOption,
                    decoration: InputDecoration(
                      labelText: 'Repeat Interval',
                    ),
                    items: repeatOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      selectedRepeatOption = newValue;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  DateTime? selectedDateTime =
                      parseDateTime(dateController.text, timeController.text);

                  if (selectedDateTime == null ||
                      selectedDateTime.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Date and time should not be in the past.')),
                    );
                    return;
                  }
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please add a title')),
                    );
                    return;
                  }
                  if (descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please add a description')),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  onSave({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                    'repeatInterval': repeatIntervalController.text,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reminder edited successfully!')),
                  );
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error editing reminder: $e');
    }
  }

  static isReminderExpired(Map<String, String> reminder) {
    final now = DateTime.now();
    final reminderDateTime =
        parseDateTime(reminder['date']!, reminder['time']!);

    if (reminderDateTime != null) {
      return reminderDateTime.isBefore(now);
    } else {
      // Handle the case where reminderDateTime is null, if necessary
      return false; // or true, depending on how you want to handle null dates
    }
  }

  static bool canShowNotifications(
      bool notificationsEnabled, bool isAnyScheduleActive) {
    return notificationsEnabled && !isAnyScheduleActive;
  }

  static void processExpiredReminders(List<Map<String, String>> reminders,
      List<Map<String, String>> expiredReminders) {
    DateTime now = DateTime.now().subtract(Duration(
        seconds: DateTime.now().second,
        microseconds: DateTime.now().microsecond));

    List<Map<String, String>> newExpiredReminders = [];

    reminders.removeWhere((reminder) {
      // Parse the date and time from the reminder
      DateTime? reminderDateTime =
          parseDateTime(reminder['date']!, reminder['time']!);

      if (reminderDateTime != null && reminderDateTime.isBefore(now)) {
        // Check if the reminder is already in the expired list
        bool isAlreadyExpired = expiredReminders.any((expired) =>
            expired['title'] == reminder['title'] &&
            expired['description'] == reminder['description'] &&
            expired['date'] == reminder['date'] &&
            expired['time'] == reminder['time']);

        if (!isAlreadyExpired) {
          newExpiredReminders.add(reminder);
          print('Reminder expired: $reminder');

          String title = reminder['title'] ?? 'Reminder Expired';
          String description = reminder['description'] ?? 'No Description';
          String notificationBody = description;
          String repeatOption = reminder['repeat'] ?? 'None';
          String actionId =
              "cancel"; // Action ID for canceling the notification
          String payload = json.encode(reminder);

          int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          NotificationService.showNotification(
              notificationId, title, notificationBody);

          NotificationService.scheduleNotification(
              reminderDateTime,
              notificationId,
              title,
              notificationBody,
              payload,
              repeatOption,
              actionId);
        }
        return true; // Remove expired reminders from the active list
      }
      return false; // Keep non-expired reminders
    });

    expiredReminders.addAll(newExpiredReminders);

    if (newExpiredReminders.isNotEmpty) {
      print('Expired reminders added: $newExpiredReminders');
    }
  }

  static Future<void> restoreReminder(
    BuildContext context,
    List<Map<String, String>> expiredReminders,
    Function(Map<String, String>) onRestore,
    Map<String, String> reminder,
  ) async {
    await ReminderUtils.editReminder(
      context,
      reminder,
      (updatedReminder) {
        DateTime? updatedDateTime = ReminderUtils.parseDateTime(
          updatedReminder['date']!,
          updatedReminder['time']!,
        );

        if (updatedDateTime != null &&
            updatedDateTime.isAfter(DateTime.now())) {
          expiredReminders.remove(reminder);
          onRestore(updatedReminder);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reminder restored successfully!')),
          );

          if (expiredReminders.isEmpty) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Please set a future date and time for the reminder.')),
          );
        }
      },
    );
  }

  static bool isScheduleActiveNow(
      DateTime now, String startTimeStr, String endTimeStr, List<String> days) {
    TimeOfDay startTime = parseTimeOfDay(startTimeStr);
    TimeOfDay endTime = parseTimeOfDay(endTimeStr);
    String currentDay = getCurrentDayAbbreviation(now);

    if (days.contains('Daily') || days.contains(currentDay)) {
      DateTime scheduleStart = combineDateAndTime(now, startTime);
      DateTime scheduleEnd = combineDateAndTime(now, endTime);

      if (scheduleEnd.isBefore(scheduleStart)) {
        scheduleEnd = scheduleEnd.add(Duration(days: 1));
      }

      return now.isAfter(scheduleStart) && now.isBefore(scheduleEnd);
    }

    return false;
  }

  static TimeOfDay parseTimeOfDay(String timeStr) {
    List<String> parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String getCurrentDayAbbreviation(DateTime date) {
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static Future<bool> shouldShowNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    bool dndModeOn = prefs.getBool('doNotDisturb') ?? false;

    // First, check if notifications are enabled
    if (!notificationsEnabled) {
      return false; // If notifications are disabled, don't show any
    }

    // Then, check DND mode
    if (!dndModeOn) {
      return true; // If DND is off, always show notifications
    } else {
      // If DND is on, only suppress notifications if there's an active schedule
      bool activeSchedule = await isAnyScheduleActive();
      return !activeSchedule; // Show notification if no active schedule
    }
  }

  static Future<bool> isAnyScheduleActive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedSchedules = prefs.getStringList('saved_schedules');
    if (savedSchedules == null || savedSchedules.isEmpty) {
      return false;
    }

    DateTime now = DateTime.now();
    for (String scheduleJson in savedSchedules) {
      Map<String, dynamic> schedule = json.decode(scheduleJson);
      String startTimeStr = schedule['start_time'] ?? '';
      String endTimeStr = schedule['end_time'] ?? '';
      List<String> days = (schedule['days'] as String).split(',');

      if (startTimeStr.isNotEmpty && endTimeStr.isNotEmpty) {
        if (isScheduleActiveNow(now, startTimeStr, endTimeStr, days)) {
          return true;
        }
      }
    }
    return false;
  }

  // ... [Other helper methods remain the same] ...

  // Static method to check if a reminder is a duplicate
  static bool isDuplicateReminder(
    List<Map<String, String>> expiredReminders,
    Map<String, String> reminder,
  ) {
    for (var existingReminder in expiredReminders) {
      if (existingReminder['title'] == reminder['title'] &&
          existingReminder['description'] == reminder['description'] &&
          existingReminder['date'] == reminder['date'] &&
          existingReminder['time'] == reminder['time']) {
        return true;
      }
    }
    return false;
  }

  // Static method to add a reminder to the expired reminders list if it's not a duplicate
  static void addExpiredReminder(
    BuildContext context,
    List<Map<String, String>> expiredReminders,
    Map<String, String> reminder,
  ) {
    if (!isDuplicateReminder(expiredReminders, reminder)) {
      expiredReminders.add(reminder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('This reminder is already in the expired list.')),
      );
    }
  }

  // Assuming you have a parseDateTime function somewhere in your code

  static Future<void> showLoadingIndicator(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    await Future.delayed(Duration(seconds: 1));

    Navigator.of(context).pop(); // Close the loading indicator
  }

  static Map<String, String>? getMostUpcomingReminder(
      List<Map<String, String>> reminders) {
    if (reminders.isEmpty) return null;

    DateTime now = DateTime.now();
    reminders.sort((a, b) {
      DateTime dateTimeA = _parseDateTime(a['date']!, a['time']!);
      DateTime dateTimeB = _parseDateTime(b['date']!, b['time']!);
      return dateTimeA.compareTo(dateTimeB);
    });

    // Find the first reminder that's in the future
    return reminders.firstWhere(
      (reminder) {
        DateTime reminderDateTime =
            _parseDateTime(reminder['date']!, reminder['time']!);
        return reminderDateTime.isAfter(now);
      },
      orElse: () =>
          reminders.first, // If all are in the past, return the first one
    );
  }

  static DateTime _parseDateTime(String date, String time) {
    // Parse date like "7 August 2024"
    List<String> dateParts = date.split(' ');
    int day = int.parse(dateParts[0]);
    int month = _getMonthNumber(dateParts[1]);
    int year = int.parse(dateParts[2]);

    // Parse time like "2:11 AM"
    List<String> timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]);
    bool isPM = timeParts[1].contains('PM');

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }

  static int _getMonthNumber(String monthName) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12
    };
    return months[monthName] ?? 1; // Default to 1 if month name is not found
  }

  static void showConfirmationSnackbar(
      BuildContext context, Function onYesPressed) {
    final SnackBar snackBar = SnackBar(
      content: Text('Are you sure you want to logout?'),
      action: SnackBarAction(
        label: 'Yes',
        onPressed: () {
          onYesPressed();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Show loading indicator with blurred background
  static Future<void> showLoadingIndicatorWithBlur(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );

    await Future.delayed(Duration(seconds: 2));
    Navigator.of(context).pop(); // Close the loading indicator
  }

  // Clear all data (e.g., expired reminders, user session)
  static Future<void> clearAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all data in SharedPreferences
    print('All data cleared');
  }

  // Navigate to Login Page after clearing data
  static Future<void> navigateToLoginPage(BuildContext context) async {
    await clearAllData(); // Clear data before navigating
    Navigator.pushReplacementNamed(context, '/login');
  }

  static List<Map<String, String>> searchReminders(
    String query,
    List<Map<String, String>> activeReminders,
    List<Map<String, String>> expiredReminders,
  ) {
    List<Map<String, String>> results = [];

    void checkAndAddReminder(Map<String, String> reminder, String source) {
      if (reminder['title']?.toLowerCase().contains(query.toLowerCase()) ==
              true ||
          reminder['description']
                  ?.toLowerCase()
                  .contains(query.toLowerCase()) ==
              true) {
        results.add({...reminder, 'source': source});
      }
    }

    for (var reminder in activeReminders) {
      checkAndAddReminder(reminder, 'active');
    }

    for (var reminder in expiredReminders) {
      checkAndAddReminder(reminder, 'expired');
    }

    return results;
  }

  static Future<void> editProfileInfo(
    BuildContext context,
    Map<String, String> currentInfo,
    Function(Map<String, String>) onSave,
  ) async {
    final nameController = TextEditingController(text: currentInfo['name']);
    final statusController = TextEditingController(text: currentInfo['status']);
    final emailController = TextEditingController(text: currentInfo['email']);
    final passwordController =
        TextEditingController(text: currentInfo['password']);

    String? _imagePath = currentInfo['imageUrl'];
    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage(ImageSource source) async {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        _imagePath = pickedFile.path;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Choose Image Source'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    GestureDetector(
                                      child: Text('Camera'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    Padding(padding: EdgeInsets.all(8.0)),
                                    GestureDetector(
                                      child: Text('Gallery'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                    Padding(padding: EdgeInsets.all(8.0)),
                                    GestureDetector(
                                      child: Text('Enter URL'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        // Show dialog to enter URL
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            String tempUrl = '';
                                            return AlertDialog(
                                              title: Text('Enter Image URL'),
                                              content: TextField(
                                                onChanged: (value) {
                                                  tempUrl = value;
                                                },
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text('OK'),
                                                  onPressed: () {
                                                    setState(() {
                                                      _imagePath = tempUrl;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        setState(() {}); // Rebuild to show updated image
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imagePath != null
                            ? (_imagePath!.startsWith('http')
                                ? NetworkImage(_imagePath!)
                                : FileImage(File(_imagePath!))) as ImageProvider
                            : AssetImage('assets/images/pro.jpg'),
                        child: Icon(Icons.camera_alt,
                            size: 30, color: Colors.white),
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: statusController,
                      decoration: InputDecoration(labelText: 'Status'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Map<String, String> updatedInfo = {
                      'name': nameController.text,
                      'status': statusController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                      'imageUrl': _imagePath ?? '',
                    };
                    await _saveProfileInfo(updatedInfo);
                    onSave(updatedInfo);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _saveProfileInfo(Map<String, String> info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', info['name'] ?? '');
    await prefs.setString('status', info['status'] ?? '');
    await prefs.setString('email', info['email'] ?? '');
    await prefs.setString('password', info['password'] ?? '');
    await prefs.setString('imageUrl', info['imageUrl'] ?? '');
  }

  static Future<Map<String, String>> getProfileInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? 'User Name',
      'status': prefs.getString('status') ?? 'Hinge Member',
      'email': prefs.getString('email') ?? 'Email not set',
      'password': prefs.getString('password') ?? 'Password not set',
      'imageUrl': prefs.getString('imageUrl') ?? '',
    };
  }

  static Drawer getDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 150.0, // Set the height of the drawer header here
            color: Colors.orange,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('View Reminders'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/view-reminders');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              // Add logout functionality here
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('profile'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
              // Add logout functionality here
            },
          ),
        ],
      ),
    );
  }

  static TimeOfDay stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static bool isCurrentTimeInDNDPeriod(TimeOfDay start, TimeOfDay end) {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  static List<Reminder> getExpiredReminders() {
    List<Reminder> allReminders =
        getAllReminders(); // Replace with your method to get reminders
    DateTime now = DateTime.now();

    return allReminders
        .where((reminder) => reminder.reminderDate.isBefore(now))
        .toList();
  }

  // Example method to get all reminders (implement according to your setup)
  static List<Reminder> getAllReminders() {
    // Implement logic to retrieve all reminders from storage or state
    return [];
  }

  // Example method to get all reminders (implement this according to your storage mechanism)
}

class Reminder {
  final String title;
  final String description;
  final DateTime reminderDate; // Replace with your actual property name

  final String repeatInterval; // e.g., 'daily', 'weekly', 'monthly'
  final bool isRepeated; // Whether this reminder should repeat

  Reminder({
    required this.title,
    required this.description,
    required this.reminderDate, // E
    this.repeatInterval = 'none',
    this.isRepeated = false,
  });
}
