import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'entry_screen.dart';
import 'package:intl/intl.dart';
import 'Utilities/date_util.dart';
//While color_util.dart doesnt affect this file directly, it is piggybacking off of
//the one below affecting this file.
import 'Widgs/calendar_widg.dart';
//This allows main.dart to access information found in the data_review document to
//display the pertnent information in the correct spot
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp((SymptomTrackerApp()));
}

typedef DayTapCallback = void Function(int day);

class SymptomTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symptom Tracker',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

//ensuring any jason markers do not get displayed
List<dynamic> safeDecodeList(String? source) {
  if (source == null || source.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(source);
    return decoded is List ? decoded : [];
  } catch (e) {
    return [];
  }
}

String removeBacksLashes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'N/A';

  return raw.replaceAll('\\', '').trim();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  DateTime currentMonth = DateTime.now(); //asking the device the year and month
  Map<int, int> entriesPerDay = {};
  bool isReviewMode = false;
  List<int> reviewedDays = [];
  DateTime? selectedDate;
  Set<int> periodDays = {};
  //medications card
  List<String> medications = [];
  bool isExpanded = false;
  bool isEditing = false; // Track if the user is editing the medication field
  late TextEditingController medicationController;
  final String medicationKey = 'medications';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadEntries();
    loadReviewedDays();
    _syncToCurrentMonthIfNeeded();
    loadPeriodDays();
    medicationController = TextEditingController();
    _loadMedications(); // Load saved medications on startup
  }

//saving daily medication so that we can observe it later
  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(medicationKey);
    setState(() {
      medications = savedList ?? [""]; //starts with an empty option
    });
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(medicationKey, medications);
  }

  void loadPeriodDays() async {
    print("Loading period days for ${currentMonth.year}-${currentMonth.month}");
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final String yearStr = currentMonth.year.toString();
    final String monthStr = currentMonth.month.toString().padLeft(2, '0');

    // First clear the existing period days
    setState(() {
      periodDays = {};
    });

    final result = await db.rawQuery(
      '''SELECT day, timestamp FROM entries WHERE strftime('%Y', timestamp) = ? AND strftime('%m', timestamp) = ? AND mperiod = 1''',
      [yearStr, monthStr],
    );

    print(
      "Found ${result.length} period days for ${currentMonth.year}-${currentMonth.month}",
    );

    final newPeriodDays = result.map((row) => row['day'] as int).toSet();
    print(
      "Period days for ${currentMonth.year}-${currentMonth.month}: $newPeriodDays",
    );

    setState(() {
      periodDays = newPeriodDays;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncToCurrentMonthIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    medicationController.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  //setting up automatic advance of the calendar.
  void _syncToCurrentMonthIfNeeded() {
    final now = DateUtilHelper.getCurrentMonth();
    if (!DateUtilHelper.isSameMonth(currentMonth, now)) {
      setState(() {
        currentMonth = DateTime(now.year, now.month);
        entriesPerDay.clear();
        loadEntries();
        if (isReviewMode) loadReviewedDays();
        loadPeriodDays(); // Refresh period days when month changes
      });
    }
  }

  void loadReviewedDays() async {
    final dbHelper = DatabaseHelper();
    final int selectedYear = currentMonth.year;
    final int selectedMonth = currentMonth.month;

    final entryDays = await dbHelper.getDaysWithEntries(
      selectedYear,
      selectedMonth,
    );
    setState(() {
      reviewedDays = entryDays;
    });
  }

  void loadEntries() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final String yearStr = currentMonth.year.toString();
    final String monthStr = currentMonth.month.toString().padLeft(2, '0');

    final result = await db.rawQuery(
      '''SELECT timestamp FROM entries WHERE strftime('%Y', timestamp) = ? AND strftime('%m', timestamp) = ?''',
      [yearStr, monthStr],
    );

    final Map<int, int> tempMap = {};
    for (final row in result) {
      final ts = DateTime.parse(
        row['timestamp'] as String,
      ); //defining the 'timestamp' as a string
      final day = ts.day;
      tempMap[day] = (tempMap[day] ?? 0) + 1;
    }
    setState(() {
      entriesPerDay = tempMap;
    });
  }

  Future<void> _onDayTapped(int day) async {
    if (isReviewMode) {
      setState(() {
        selectedDate = DateTime(currentMonth.year, currentMonth.month, day);
      });
      return;
    }
    final didAddEntry = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EntryScreen(day: day, updateEntryCount: (d) => _onDayTapped(d)),
      ),
    );
    if (didAddEntry == true) {
      setState(() {
        entriesPerDay[day] = (entriesPerDay[day] ?? 0) + 1;
      });
      loadPeriodDays(); // Refresh period days after new entry
    }
  }

  Future<void> saveMedications(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medications', value);
  }

  Future<void> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    medicationController.text =
        prefs.getString('medications') ?? "Daily Medications:";
  }

  @override // this is what the user opens up to
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Journal')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () async {
                    setState(() {
                      currentMonth = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                      entriesPerDay.clear();
                      reviewedDays.clear();
                      isReviewMode = false;
                    });
                    loadEntries();
                    loadPeriodDays(); // Add this to match right arrow behavior

                    if (isReviewMode) {
                      loadReviewedDays();
                    }
                  },
                ),

                //this is the halfway point of document
                //changed the Month and Year declaration to a clickable, this way the user can jump between months and years
                //at a greater distance than one month at a time.
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: currentMonth,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                      initialDatePickerMode: DatePickerMode.year,
                    );

                    if (picked != null) {
                      setState(() {
                        currentMonth = DateTime(picked.year, picked.month);
                        entriesPerDay.clear();
                        reviewedDays.clear();
                        isReviewMode = false;
                      });
                      loadEntries();
                      loadPeriodDays();
                    }
                  },
                  child: Text(
                    DateFormat.yMMMM().format(currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () async {
                    setState(() {
                      currentMonth = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                      entriesPerDay.clear();
                      reviewedDays.clear();
                      isReviewMode = false;
                    });
                    loadEntries();
                    loadPeriodDays();
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            CalendarWidget(
              currentMonth: currentMonth,
              firstWeekday: DateTime(
                currentMonth.year,
                currentMonth.month,
                1,
              ).weekday,
              daysInMonth: DateTime(
                currentMonth.year,
                currentMonth.month + 1,
                0,
              ).day,
              entriesPerDay: entriesPerDay,
              reviewedDays: reviewedDays,
              isReviewMode: isReviewMode,
              onDayTapped: _onDayTapped,
              periodDays: periodDays,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Tap a day to log symptoms',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            // Medications Card
            InkWell(
              autofocus: true,
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Information",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      isEditing
                          ? Column(
                              children:
                                  List.generate(medications.length, (index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: TextFormField(
                                    initialValue: medications[index],
                                    onChanged: (value) {
                                      medications[index] = value;
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Item ${index + 1}",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                );
                              }),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: medications
                                  .map((med) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Text(med),
                                      ))
                                  .toList(),
                            ),
                      if (isExpanded) ...[
                        Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isEditing)
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    medications.add("");
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(isEditing ? Icons.check : Icons.edit,
                                  color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  isEditing = !isEditing;
                                  if (!isEditing) _saveMedications();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isReviewMode = !isReviewMode;
                  if (isReviewMode) {
                    loadReviewedDays();
                  } else {
                    reviewedDays.clear();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isReviewMode ? Color(0xFF4B0082) : Colors.grey[300],
                foregroundColor: isReviewMode ? Colors.white : Colors.black,
                elevation: isReviewMode ? 6 : 2,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isReviewMode ? "Exit Review Mode" : "Review Entries"),
            ),
            if (isReviewMode && selectedDate != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper().getEntriesforDate(selectedDate!),
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
                        "No entries for ${DateFormat.yMMMM().format(currentMonth)}",
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
                              (entry['weight'] as num?)?.toStringAsFixed(1) ??
                                  'N/A';
                          final timestamp =
                              (entry['timestamp'] as String?) ?? '';
                          final day = entry['day'] ?? '?';

                          final actList = removeBacksLashes(
                            entry['activities'] as String?,
                          );
                          final conList = removeBacksLashes(
                            entry['mnm'] as String?,
                          );
                          final fnsList = removeBacksLashes(
                            entry['symptoms'] as String?,
                          );
                          final fatuige =
                              entry['fatigue'] == 1 ? 'Fatigued' : 'No Fatigue';

                          String toReadableTime(int timeInHHMM) {
                            if (timeInHHMM == -1) return "No time set";

                            // Convert HHMM format to hours and minutes
                            final hour = timeInHHMM ~/ 100; // For 2200 -> 22
                            final minute = timeInHHMM %
                                100; // For 2200 -> 00                        // Validate the time
                            if (hour < 0 ||
                                hour > 23 ||
                                minute < 0 ||
                                minute > 59) {
                              return "Invalid time";
                            }

                            // Determine AM/PM
                            final suffix = hour >= 12 ? 'PM' : 'AM';

                            // Convert to 12-hour format
                            final hour12 = hour > 12
                                ? hour - 12 // After 12 PM
                                : (hour == 0
                                    ? 12 // Midnight (00:00)
                                    : hour); // Morning hours or noon

                            return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
                          }

                          final sleep =
                              int.tryParse(entry['sleep']?.toString() ?? '') ??
                                  -1;
                          final wake =
                              int.tryParse(entry['wake']?.toString() ?? '') ??
                                  -1;

                          String sleepReport = (sleep != -1 && wake != -1)
                              ? "Slept from ${toReadableTime(sleep)} to ${toReadableTime(wake)}"
                              : "Sleep data Unavailable";

                          return GestureDetector(
                            onTap: () =>
                                setState(() => isExpanded = !isExpanded),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Day $day • ${timestamp.split('T')[0]}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => isExpanded = !isExpanded),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Day $day • ${timestamp.split('T')[0]}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "$fatuige • Severity: ${entry['severity']}\n"
                                            "Weight: $weight lbs • Water Intake: ${entry['water'] ?? 'N/A'} oz\n"
                                            "$sleepReport\n"
                                            "Consumptions: $conList\n"
                                            "Activities: $actList\n"
                                            "Feelings and Symptoms: $fnsList",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          if (isExpanded) ...[
                                            Divider(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed: () {
                                                    // Handle edit action
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    final timestamp =
                                                        entry['timestamp']
                                                            as String;

                                                    // Show confirmation dialog
                                                    final shouldDelete =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: Text(
                                                            'Delete Entry'),
                                                        content: Text(
                                                            'Are you sure you want to delete this entry?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child:
                                                                Text('Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            child:
                                                                Text('Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (shouldDelete == true) {
                                                      // Delete from database
                                                      await DatabaseHelper()
                                                          .deleteEntriesByTimestamp(
                                                              timestamp);

                                                      // Call setState on the main screen state to trigger a rebuild
                                                      context
                                                          .findAncestorStateOfType<
                                                              _CalendarScreenState>()
                                                          ?.setState(() {
                                                        // Refresh all the data
                                                        loadEntries();
                                                        loadPeriodDays();
                                                        if (isReviewMode) {
                                                          loadReviewedDays();
                                                        }
                                                        // Force the entry list to refresh
                                                        selectedDate = DateTime(
                                                          selectedDate!.year,
                                                          selectedDate!.month,
                                                          selectedDate!.day,
                                                        );
                                                      });

                                                      print(
                                                          'Deleted entry with timestamp: $timestamp');

                                                      // Show success message
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Entry deleted successfully'),
                                                          duration: Duration(
                                                              seconds: 2),
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
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
