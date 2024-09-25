import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class CreateReminderPage extends StatefulWidget {
  final VoidCallback onReminderSaved;

  CreateReminderPage({required this.onReminderSaved});

  @override
  _CreateReminderPageState createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRepeatOption;

  String? _titleError;
  String? _descriptionError;
  String? _dateError;
  String? _timeError;

  final List<String> _repeatOptions = [
    'None',
    'Every 5 seconds',
    'Every 5 minutes',
    'Every 10 minutes',
    'Every 30 minutes',
    'Every day',
    'Every week',
    'Every month'
  ];

  @override
  void initState() {
    super.initState();
    _selectedRepeatOption = _repeatOptions[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  bool isPastDateTime(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange, // Orange color for date picker header
              onPrimary: Colors.white, // White text color on the header
              onSurface: Colors.black, // Black color for the body text
            ),
            dialogBackgroundColor: Colors.white, // Background color
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('d MMMM yyyy').format(pickedDate);
        _dateError = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange, // Orange color for time picker header
              onPrimary: Colors.white, // White text color on the header
              onSurface: Colors.black, // Black color for the body text
            ),
            dialogBackgroundColor: Colors.white, // Background color
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = pickedTime.format(context);
        _timeError = null;
      });
    }
  }

  void _validateAndSaveReminder() {
    setState(() {
      _titleError =
          _titleController.text.isEmpty ? 'Please enter a title' : null;
      _descriptionError = _descriptionController.text.isEmpty
          ? 'Please enter a description'
          : null;
      _dateError = _dateController.text.isEmpty ? 'Please select a date' : null;
      _timeError = _timeController.text.isEmpty ? 'Please select a time' : null;
    });

    if (_titleError == null &&
        _descriptionError == null &&
        _dateError == null &&
        _timeError == null) {
      _saveReminder();
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      final selectedDate = _selectedDate;
      final selectedTime = _selectedTime;

      if (selectedDate == null || selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a valid date and time')),
        );
        return;
      }

      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (isPastDateTime(dateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The date and time cannot be in the past.')),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> reminders = prefs.getStringList('reminders') ?? [];

      Map<String, String> newReminder = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'repeat': _selectedRepeatOption!,
      };

      reminders.add(jsonEncode(newReminder));
      await prefs.setStringList('reminders', reminders);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder saved successfully!'),
          duration: Duration(seconds: 1),
        ),
      );

      widget.onReminderSaved();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Reminder', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.black),
                  errorText: _titleError,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _titleError = null;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black),
                  errorText: _descriptionError,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _descriptionError = null;
                  });
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      labelStyle: TextStyle(color: Colors.black),
                      suffixIcon:
                          Icon(Icons.calendar_today, color: Colors.orange),
                      errorText: _dateError,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Time',
                      labelStyle: TextStyle(color: Colors.black),
                      suffixIcon: Icon(Icons.access_time, color: Colors.orange),
                      errorText: _timeError,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRepeatOption,
                decoration: InputDecoration(
                  labelText: 'Repeat',
                  labelStyle: TextStyle(color: Colors.orange),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                items: _repeatOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRepeatOption = newValue;
                  });
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _validateAndSaveReminder,
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.orange, // Orange background
                  shadowColor: Colors.white, // White text color
                ),
                child: Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
