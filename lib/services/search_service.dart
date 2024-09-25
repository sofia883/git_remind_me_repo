import 'package:flutter/material.dart';
import 'package:remind_me/services/reminder_utils.dart';

class SearchResultsOverlay extends StatefulWidget {
  final List<Map<String, String>> searchResults;
  final String searchQuery;
  final Function(BuildContext, Map<String, String>, bool, bool) onTap;
  final List<Map<String, String>> allReminders;

  SearchResultsOverlay({
    required this.searchResults,
    required this.searchQuery,
    required this.onTap,
    required this.allReminders,
  });

  @override
  _SearchResultsOverlayState createState() => _SearchResultsOverlayState();
}

class _SearchResultsOverlayState extends State<SearchResultsOverlay> {
  Map<String, String>? highlightedReminder;

  @override
  Widget build(BuildContext context) {
    Map<String, String>? mostUpcomingReminder =
        ReminderUtils.getMostUpcomingReminder(widget.searchResults);

    return Container(
      color: Colors.white.withOpacity(0.9),
      child: ListView.builder(
        itemCount: widget.searchResults.length,
        itemBuilder: (context, index) {
          final reminder = widget.searchResults[index];
          bool isExpired = reminder['source'] == 'expired';
          bool isMostUpcoming = reminder == mostUpcomingReminder;
          bool isHighlighted = reminder == highlightedReminder;

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isHighlighted 
                ? Colors.blue.shade100 
                : (isExpired ? Colors.orange[50] : Colors.white),
            child: ListTile(
              title: RichText(
                text: TextSpan(
                  children: _highlightSearchQuery(
                    reminder['title'] ?? 'No Title',
                    widget.searchQuery,
                  ),
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: RichText(
                text: TextSpan(
                  children: _highlightSearchQuery(
                    reminder['description'] ?? 'No description',
                    widget.searchQuery,
                  ),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${reminder['date']} ${reminder['time']}'),
                  if (isExpired)
                    Text('Expired', style: TextStyle(color: Colors.red))
                  else if (isMostUpcoming)
                    Text('Upcoming Reminder',
                        style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                setState(() {
                  highlightedReminder = reminder;
                });
                widget.onTap(context, reminder, isExpired, isMostUpcoming);
              },
            ),
          );
        },
      ),
    );
  }

  List<TextSpan> _highlightSearchQuery(String text, String query) {
    if (query.isEmpty) return [TextSpan(text: text)];

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while (true) {
      indexOfMatch = text.toLowerCase().indexOf(query.toLowerCase(), start);
      if (indexOfMatch < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        return spans;
      }

      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ));

      start = indexOfMatch + query.length;
    }
  }
}
