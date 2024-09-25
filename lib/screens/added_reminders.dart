import 'package:flutter/material.dart';
import 'package:remind_me/services/reminder_utils.dart';

class AddedRemindersPage extends StatefulWidget {
  final Map<String, String>? highlightedReminder;
  final Function(Map<String, String>) onEdit;
  final Function(Map<String, String>) onDelete;

  AddedRemindersPage({
    this.highlightedReminder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AddedRemindersPage> createState() => _AddedRemindersPageState();
}

class _AddedRemindersPageState extends State<AddedRemindersPage> {
  List<Map<String, String>> _allReminders = [];
  List<Map<String, String>> reminders = [];
  List<Map<String, String>> expiredReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading
    try {
      List<List<Map<String, String>>> loadedReminders =
          await ReminderUtils.loadReminders();
      setState(() {
        _allReminders = loadedReminders[0];
        expiredReminders = loadedReminders[1];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reminders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleDismissed(Map<String, String> reminder, int index) {
    // Remove the item from the list immediately
    setState(() {
      _allReminders.removeAt(index);
    });

    // Call the onDelete callback
    widget.onDelete(reminder);

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder deleted"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _saveReminders();
            // _loadReminders();
            // Reinsert the item if the user wants to undo
            setState(() {
              _allReminders.insert(index, reminder);
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveReminders() async {
    await ReminderUtils.saveReminders(_allReminders, expiredReminders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Added Reminders'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _allReminders.isEmpty
              ? Center(child: Text('No reminders added yet.'))
              : ListView.builder(
                  itemCount: _allReminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _allReminders[index];
                    final isHighlighted =
                        reminder == widget.highlightedReminder;

                    return Dismissible(
                      key: UniqueKey(), // Use UniqueKey for each item
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _saveReminders();
                        _handleDismissed(reminder, index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ReminderListTile(
                        reminder: reminder,
                        isHighlighted: isHighlighted,
                        onEdit: widget.onEdit,
                        onDelete: (reminder) {
                          _handleDismissed(reminder, index);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class ReminderListTile extends StatelessWidget {
  final Map<String, String> reminder;
  final bool isHighlighted;
  final Function(Map<String, String>) onEdit;
  final Function(Map<String, String>) onDelete;

  ReminderListTile({
    required this.reminder,
    required this.isHighlighted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? Colors.blue[100] : null,
      child: ListTile(
        title: Text(reminder['title'] ?? 'No Title'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder['description'] ?? 'No description'),
            Text('Date: ${reminder['date'] ?? 'Not set'}'),
            Text('Time: ${reminder['time'] ?? 'Not set'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => onEdit(reminder),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => onDelete(reminder),
            ),
          ],
        ),
      ),
    );
  }
}
