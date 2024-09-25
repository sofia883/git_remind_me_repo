import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remind_me/services/reminder_utils.dart';

import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _name = '';
  String _status = '';
  String _imageUrl = '';
  String _email = '';
  String _password = '';
  bool _doNotDisturb = false;
  bool _notificationsEnabled = true;
  bool _isLoading = true; // Add a loading flag
  bool _showSchedules = false; // Track if schedule list is visible

  Timer? _updateTimer;

  List<Map<String, String>> _schedules = [];

  @override
  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUserData();
    _loadSchedules();

    // Add a periodic timer to check and update DND status
    Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        // This will trigger a rebuild and update the UI
      });
      _updateDNDStatus();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _doNotDisturb = prefs.getBool('doNotDisturb') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      _isLoading = false; // Update loading flag
    });
  }

  void _toggleDND(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('doNotDisturb', value);
    setState(() {
      _doNotDisturb = value;
    });
  }

  void _updateDNDStatus() {
    bool anyActiveSchedules = _schedules.any((schedule) => isActive(schedule));
    if (!anyActiveSchedules && _doNotDisturb) {
      _toggleDND(false);
    } else {
      _toggleDND(true);
    }
  }

  int _countActiveSchedules() {
    return _schedules.where((schedule) => isActive(schedule)).length;
  }

  static bool canShowNotifications(
      bool notificationsEnabled, bool isAnyScheduleActive) {
    return notificationsEnabled && !isAnyScheduleActive;
  }

  void _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name);
    await prefs.setString('status', _status);
    await prefs.setString('email', _email);
    await prefs.setString('password', _password);
    await prefs.setString('imageUrl', _imageUrl);

    // Debugging output
    print('Saved Name: $_name');
    print('Saved Status: $_status');
    print('Saved Email: $_email');
    print('Saved Password: $_password');
  }

  void _toggleNotifications(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  void _logout() {
    ReminderUtils.showConfirmationSnackbar(context, () async {
      await ReminderUtils.showLoadingIndicatorWithBlur(context);
      ReminderUtils.navigateToLoginPage(context);
    });
  }

  void _saveDNDPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('doNotDisturb', value);
    setState(() {
      _doNotDisturb = value;
    });
  }

  void _loadSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedSchedules = prefs.getStringList('saved_schedules');
    if (savedSchedules != null) {
      setState(() {
        _schedules = savedSchedules.map((schedule) {
          Map<String, dynamic> decodedSchedule = jsonDecode(schedule);
          return decodedSchedule
              .map((key, value) => MapEntry(key, value.toString()));
        }).toList();
      });
      print('Loaded ${_schedules.length} schedules'); // Debug print
    } else {
      print('No saved schedules found'); // Debug print
    }
    print('Reminders loaded: $_schedules');
  }

  Future<void> _saveSchedules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> schedulesToSave =
        _schedules.map((schedule) => jsonEncode(schedule)).toList();
    await prefs.setStringList('saved_schedules', schedulesToSave);
    print('Saved ${schedulesToSave.length} schedules'); // Debug print
  }

  void _deleteSchedule(int index) async {
    setState(() {
      _schedules.removeAt(index);
    });
    await _saveSchedules(); // Save schedules after deleting one
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule deleted')),
    );
  }

  bool _isActive(Map<String, String> schedule) {
    String startTimeStr = schedule['start_time'] ?? '';
    String endTimeStr = schedule['end_time'] ?? '';
    final now = DateTime.now();

    // Convert start and end times to DateTime objects
    DateTime startTime = _convertToDateTime(startTimeStr);
    DateTime endTime = _convertToDateTime(endTimeStr);

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  DateTime _convertToDateTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();
    // Assuming timeStr format is 'HH:mm', modify as needed
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  bool isAnyScheduleActive() {
    final now = DateTime.now();
    for (var schedule in _schedules) {
      if (_isActive(schedule)) {
        return true;
      }
    }
    return false;
  }

  // ... [Previous methods remain the same] ...

  Future<void> _loadUserData() async {
    Map<String, String> profileInfo = await ReminderUtils.getProfileInfo();
    setState(() {
      _name = profileInfo['name']!;
      _status = profileInfo['status']!;
      _email = profileInfo['email']!;
      _password = profileInfo['password']!;
      _imageUrl = profileInfo['imageUrl']!;
    });
  }

  void _editProfileInfo() {
    ReminderUtils.editProfileInfo(
      context,
      {
        'name': _name,
        'status': _status,
        'email': _email,
        'password': _password,
        'imageUrl': _imageUrl,
      },
      (updatedInfo) {
        setState(() {
          _name = updatedInfo['name']!;
          _status = updatedInfo['status']!;
          _email = updatedInfo['email']!;
          _password = updatedInfo['password']!;
          _imageUrl = updatedInfo['imageUrl']!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageUrl.isNotEmpty
                        ? (_imageUrl.startsWith('http')
                            ? NetworkImage(_imageUrl)
                            : FileImage(File(_imageUrl))) as ImageProvider
                        : AssetImage('assets/images/pro.jpg'),
                  ),
                ),
                Positioned(
                  bottom: -9,
                  right: 4,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: _editProfileInfo,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            Text(_name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text(_status, style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text(_password, style: TextStyle(fontSize: 16, color: Colors.grey)),
            // Use loaded user data
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                _toggleNotifications(value);
              },
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Notification Tone', style: TextStyle(fontSize: 15)),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to tone selection page or show a dialog to select a notification tone
              },
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('Do Not Disturb'),
              value: _doNotDisturb,
              onChanged: (bool value) {
                _toggleDND(value);
              },
            ),
            if (_doNotDisturb) ...[
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedules', style: TextStyle(fontSize: 15)),
                    SizedBox(height: 5),
                    Text(
                      '${_countActiveSchedules()} active schedules',
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                    ),
                  ],
                ),
                trailing: Icon(
                  _showSchedules ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
                onTap: _showSchedulesBottomSheet,
              ),
            ],
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool isActive(Map<String, String> schedule) {
    DateTime now = DateTime.now();
    String startTimeStr = schedule['start_time'] ?? '';
    String endTimeStr = schedule['end_time'] ?? '';
    List<String> scheduleDays = (schedule['days'] ?? '').split(',');

    // Parse start and end times
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(startTimeStr.split(':')[0]),
      minute: int.parse(startTimeStr.split(':')[1]),
    );
    TimeOfDay endTime = TimeOfDay(
      hour: int.parse(endTimeStr.split(':')[0]),
      minute: int.parse(endTimeStr.split(':')[1]),
    );

    // Convert TimeOfDay to DateTime for easier comparison
    DateTime scheduleStart = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    DateTime scheduleEnd =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    // If end time is before start time, it means the schedule spans midnight
    if (scheduleEnd.isBefore(scheduleStart)) {
      scheduleEnd = scheduleEnd.add(Duration(days: 1));
    }

    // Check if current time is within the schedule time range
    bool isTimeInRange =
        now.isAfter(scheduleStart) && now.isBefore(scheduleEnd);

    // Get current day abbreviation (e.g., 'Mon', 'Tue', etc.)
    String currentDay = DateFormat('E').format(now).substring(0, 3);

    // Check if the schedule is set for every day or if the current day is in the schedule
    bool isDayMatched =
        scheduleDays.contains('Daily') || scheduleDays.contains(currentDay);

    // The schedule is active only if both time is in range and day matches
    return isTimeInRange && isDayMatched;
  }

  void _showSchedulesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Schedules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ..._schedules.map((schedule) {
                    String title = schedule['title']?.isNotEmpty == true
                        ? schedule['title']!
                        : 'Untitled';
                    String startTime =
                        _convertTo12HourFormat(schedule['start_time'] ?? '');
                    String endTime =
                        _convertTo12HourFormat(schedule['end_time'] ?? '');
                    String days = schedule['days'] ?? '';
                    bool isActivve = isActive(schedule);

                    return Dismissible(
                      key: Key(schedule['id'] ?? DateTime.now().toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        int index = _schedules.indexOf(schedule);
                        if (index != -1) {
                          _deleteSchedule(index);
                          setState(() {});
                        }
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(schedule['title'] ?? 'Untitled'),
                            Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                color: isActive(schedule)
                                    ? Colors.blue
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$startTime - $endTime'),
                            Text(schedule['days'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Add New Schedule'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddScheduleBottomSheet(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSchedule(
      String title, TimeOfDay startTime, TimeOfDay endTime, List<String> days) {
    setState(() {
      _schedules.add({
        'title': title,
        'start_time':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        'days': days.contains('Daily') ? 'Daily' : days.join(','),
      });
    });
    _saveSchedules();
    _updateDNDStatus();
  }

// Convert a time string in 24-hour format to 12-hour format with AM/PM
  String _convertTo12HourFormat(String time) {
    if (time.isEmpty) return '';

    DateTime parsedTime = DateTime.parse('1970-01-01 $time:00');
    String formattedTime = DateFormat.jm()
        .format(parsedTime); // 'jm' gives 12-hour format with AM/PM
    return formattedTime;
  }

  bool isCurrentTimeBetween(String startTimeStr, String endTimeStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startTime;
    DateTime endTime;

    try {
      // Parse the start and end times using DateFormat with 12-hour format
      DateFormat format =
          DateFormat.jm(); // 'jm' gives 12-hour format with AM/PM
      startTime = format.parse(startTimeStr);
      endTime = format.parse(endTimeStr);

      // Adjust startTime and endTime to today’s date
      startTime = DateTime(
          today.year, today.month, today.day, startTime.hour, startTime.minute);
      endTime = DateTime(
          today.year, today.month, today.day, endTime.hour, endTime.minute);
    } catch (e) {
      print('Invalid time format: $e');
      return false; // Or handle the error appropriately
    }

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

// Show Bottom Sheet with Schedule Form

  void _showAddScheduleBottomSheet(BuildContext context) {
    String title = '';
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime =
        TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
    List<String> selectedDays = ['Daily'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Start Time: ${startTime.format(context)}'),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            TimeOfDay? newTime = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (newTime != null) {
                              setState(() {
                                startTime = newTime;
                              });
                            }
                          },
                          child: Text('Pick Time'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('End Time: ${endTime.format(context)}'),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            TimeOfDay? newTime = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (newTime != null) {
                              setState(() {
                                endTime = newTime;
                              });
                            }
                          },
                          child: Text('Pick Time'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('Select Days',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        'Daily',
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat'
                      ].map((day) {
                        return FilterChip(
                          label: Text(day),
                          selected: selectedDays.contains(day),
                          onSelected: (bool selected) {
                            setState(() {
                              if (day == 'Daily') {
                                selectedDays = selected ? ['Daily'] : [];
                              } else {
                                if (selected) {
                                  selectedDays.remove('Daily');
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                  if (selectedDays.isEmpty) {
                                    selectedDays.add('Daily');
                                  }
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _addSchedule(
                          title,
                          startTime,
                          endTime,
                          selectedDays,
                        );
                        Navigator.pop(context);
                        _showSchedulesBottomSheet();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// void _addSchedule(String title, TimeOfDay startTime, TimeOfDay endTime, List<String> days) {
//   setState(() {
//     _schedules.add({
//       'title': title,
//       'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
//       'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
//       'days': days.join(','),
//     });
//   });
//   _saveSchedules();
//   _updateDNDStatus();
// }

// bool isScheduleActive(Map<String, String> schedule) {
//   DateTime now = DateTime.now();
//   String startTimeStr = schedule['start_time'] ?? '';
//   String endTimeStr = schedule['end_time'] ?? '';
//   List<String> days = (schedule['days'] ?? '').split(',');

//   if (days.contains('Daily') || days.contains(DateFormat('E').format(now).substring(0, 3))) {
//     TimeOfDay startTime = TimeOfDay(
//       hour: int.parse(startTimeStr.split(':')[0]),
//       minute: int.parse(startTimeStr.split(':')[1]),
//     );
//     TimeOfDay endTime = TimeOfDay(
//       hour: int.parse(endTimeStr.split(':')[0]),
//       minute: int.parse(endTimeStr.split(':')[1]),
//     );

//     DateTime scheduleStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
//     DateTime scheduleEnd = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

//     if (scheduleEnd.isBefore(scheduleStart)) {
//       scheduleEnd = scheduleEnd.add(Duration(days: 1));
//     }

//     return now.isAfter(scheduleStart) && now.isBefore(scheduleEnd);
//   }

//   return false;
// }

class Schedule {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> days;

  Schedule({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  // Convert Schedule to a map for storage or serialization
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'days': days,
    };
  }

  // Create Schedule from a map
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      title: map['title'],
      startTime: TimeOfDay(
        hour: int.parse(map['startTime'].split(':')[0]),
        minute: int.parse(map['startTime'].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(map['endTime'].split(':')[0]),
        minute: int.parse(map['endTime'].split(':')[1]),
      ),
      days: List<String>.from(map['days']),
    );
  }
}
