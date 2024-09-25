import 'package:flutter/material.dart';
import 'package:remind_me/services/reminder_utils.dart';

class ExpiredRemindersPage extends StatefulWidget {
  final List<Map<String, String>> expiredReminders;
  final Function(Map<String, String>) onRestore;
  final Map<String, String>? highlightedReminder;

  ExpiredRemindersPage({
    required this.expiredReminders,
    required this.onRestore,
    this.highlightedReminder,
  });

  @override
  _ExpiredRemindersPageState createState() => _ExpiredRemindersPageState();
}

class _ExpiredRemindersPageState extends State<ExpiredRemindersPage> {
  @override
  Widget build(BuildContext context) {
    // Sort expired reminders by date descending
    List<Map<String, String>> sortedExpiredReminders = List.from(widget.expiredReminders);
    sortedExpiredReminders.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date'] ?? DateTime.now().toIso8601String());
      DateTime dateB = DateTime.parse(b['date'] ?? DateTime.now().toIso8601String());
      return dateB.compareTo(dateA); // Sort in descending order
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Expired Reminders'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sharp,
              color: Colors.red,
            ),
            onPressed: _showClearAllConfirmationDialog,
          ),
        ],
      ),
      body: sortedExpiredReminders.isEmpty
          ? Center(
              child: Text(
                'No history',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedExpiredReminders.length,
              itemBuilder: (context, index) {
                final reminder = sortedExpiredReminders[index];
                final isHighlighted = _isHighlighted(reminder);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    shadowColor: Colors.orange,
                    elevation: 14,
                    margin: EdgeInsets.all(1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Rounded corners
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(4.0),
                      tileColor: isHighlighted ? Colors.blue[100] : null,
                      title: Text(
                        reminder['title'] ?? 'No Title',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder['description'] ?? 'No Description',
                            style: TextStyle(fontSize: 14.0),
                          ),
                          Text(
                            'Date: ${reminder['date'] ?? 'Not set'}',
                            style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                          ),
                          Text(
                            'Time: ${reminder['time'] ?? 'Not set'}',
                            style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.restore),
                        onPressed: () => _restoreReminder(context, reminder),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool _isHighlighted(Map<String, String> reminder) {
    return widget.highlightedReminder != null &&
        widget.highlightedReminder!['id'] == reminder['id'];
  }

  void _restoreReminder(BuildContext context, Map<String, String> reminder) {
    ReminderUtils.restoreReminder(
      context,
      widget.expiredReminders,
      widget.onRestore,
      reminder,
    ).then((_) {
      setState(() {});
    });
  }

  void _showClearAllConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Expired Reminders'),
          content: Text('Are you sure you want to delete all expired reminders? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllReminders();
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No reminders were deleted.')),
                );
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _clearAllReminders() {
    setState(() {
      widget.expiredReminders.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All expired reminders have been cleared.')),
    );
  }
}
