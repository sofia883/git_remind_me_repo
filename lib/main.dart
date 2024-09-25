import 'package:flutter/material.dart';

import 'package:remind_me/screens/home_page.dart';
import 'package:remind_me/screens/welcome_page.dart';
import 'package:remind_me/screens/settings_page.dart';

import 'package:remind_me/screens/login_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:remind_me/screens/added_reminders.dart';
import 'package:remind_me/services/reminder_utils.dart';
import 'package:remind_me/services/notifi_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.createNotificationChannel(); // This ensures that Flutter's binding is ready
  await AndroidAlarmManager.initialize(); // This is crucial for scheduling

  // Schedule period
  print('Starting the app...');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
        GlobalKey<ScaffoldMessengerState>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remind Me',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      initialRoute: isLoggedIn ? '/welcome' : '/login',
      routes: {
        '/home': (context) => MainScreen(),
        '/login': (context) => LoginPage(),
        '/welcome': (context) => WelcomePage(),
      },
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: isLoggedIn ? WelcomePage() : LoginPage(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  List<Map<String, String>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders(); // Load reminders when the screen is initialized
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  Future<void> _loadReminders() async {
    print('Starting to load reminders...');
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading

    try {
      List<List<Map<String, String>>> loadedReminders =
          await ReminderUtils.loadReminders();

      setState(() {
        reminders = loadedReminders[0]; // Use the correct list here
      });

      print('Reminders loaded: $reminders');
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageView(),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.orange,
        buttonBackgroundColor: Colors.black,
        height: 60,
        index: _selectedIndex,
        onTap: _onItemTapped,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.list, size: 30, color: Colors.white),
          Icon(Icons.settings, size: 30, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        HomePage(),
        AddedRemindersPage(
          // reminders: reminders,
          onEdit: (reminder) {
            // Implement edit functionality
          },
          onDelete: (reminder) {
            // Implement delete functionality
          },
        ),
        SettingsPage(),
      ],
    );
  }
}
