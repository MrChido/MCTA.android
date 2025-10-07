import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';

String removeBacksLashes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'N/A';
  return raw.replaceAll('\\', '').trim();
}

class EntryReviewList extends StatelessWidget {
  final DateTime selectedDate;
  final Function() onDataChanged;

  const EntryReviewList({
    required this.selectedDate,
    required this.onDataChanged,
  });

  String toReadableTime(int timeInHHMM) {
    if (timeInHHMM == -1) return "No time set";

    final hour = timeInHHMM ~/ 100;
    final minute = timeInHHMM % 100;

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return "Invalid time";
    }

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getEntriesforDate(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text("Error loading entries: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "No entries for ${DateFormat.yMMMM().format(selectedDate)}",
            ),
          );
        }

        final entries = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            bool isExpanded = false;

            return StatefulBuilder(
              builder: (context, setState) {
                final weight =
                    (entry['weight'] as num?)?.toStringAsFixed(1) ?? 'N/A';
                final timestamp = (entry['timestamp'] as String?) ?? '';
                final day = entry['day'] ?? '?';
                final spoonCount = entry['spoonCount'] ?? 0;
                final hHealth = entry['hHealth'] ?? 'N/A';

                final actList =
                    removeBacksLashes(entry['activities'] as String?);
                final conList = removeBacksLashes(entry['mnm'] as String?);
                final fnsList = removeBacksLashes(entry['symptoms'] as String?);
                final fatigue =
                    entry['fatigue'] == 1 ? 'Fatigued' : 'No Fatigue';

                final sleep =
                    int.tryParse(entry['sleep']?.toString() ?? '') ?? -1;
                final wake =
                    int.tryParse(entry['wake']?.toString() ?? '') ?? -1;

                String sleepReport = (sleep != -1 && wake != -1)
                    ? "Slept from ${toReadableTime(sleep)} to ${toReadableTime(wake)}"
                    : "Sleep data Unavailable";

                return GestureDetector(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Day $day • ${timestamp.split('T')[0]}",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "$fatigue • Pain Severity: ${entry['severity']}\n"
                          "Current Number of Spoons: $spoonCount\n"
                          "Weight: $weight lbs • Water Intake: ${entry['water'] ?? 'N/A'} oz\n"
                          "$sleepReport\n"
                          "Consumptions: $conList\n"
                          "Heart Health:(Systolic/Diastolic/Heart Rate/Oxygen Saturation)\n"
                          "$hHealth\n"
                          "Activities: $actList\n"
                          "Feelings and Symptoms: $fnsList",
                          style: TextStyle(fontSize: 14),
                        ),
                        if (isExpanded) ...[
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Entry'),
                                      content: Text(
                                          'Are you sure you want to delete this entry?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true) {
                                    await DatabaseHelper()
                                        .deleteEntriesByTimestamp(timestamp);
                                    onDataChanged();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Entry deleted successfully'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
