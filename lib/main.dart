import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_helper.dart';
import 'entry_screen.dart';
import 'package:intl/intl.dart';
import 'Utilities/date_util.dart';
import 'Widgs/calendar_widg.dart' show CalendarWidget;
import 'Widgs/medications_card.dart';
import 'Widgs/entry_review_list.dart';
import 'dart:convert';
import 'dart:async';

//push notifications setup
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> scheduleAppCheckIn() async {
  try {
    // Request notification permissions
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'spoonie_channel',
      'App Check-In',
      channelDescription: 'Suggests you check in with the app',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      ticker: 'Daily Journal Check-In',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // Schedule a periodic notification
    await flutterLocalNotificationsPlugin.periodicallyShow(
      0, // notification id
      'Spoonie Check-In',
      'How are you feeling today? Care to log your symptoms?',
      RepeatInterval.daily,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Notification scheduled successfully');
  } catch (e) {
    print('Error scheduling notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();

  // Schedule initial check-in
  await scheduleAppCheckIn();

  // Schedule recurring check-ins every 3 days
  Timer.periodic(const Duration(days: 1), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotification = prefs.getInt('lastNotification') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if 3 days have passed since last notification
    if (now - lastNotification >= const Duration(days: 3).inMilliseconds) {
      await scheduleAppCheckIn();
      await prefs.setInt('lastNotification', now);
    }
  });

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

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  DateTime currentMonth = DateTime.now();
  Map<int, int> entriesPerDay = {};
  bool isReviewMode = false;
  List<int> reviewedDays = [];
  DateTime? selectedDate;
  Set<int> periodDays = {};
  int spoonCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadEntries();
    loadReviewedDays();
    _syncToCurrentMonthIfNeeded();
    loadPeriodDays();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void loadPeriodDays() async {
    print("Loading period days for ${currentMonth.year}-${currentMonth.month}");
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final String yearStr = currentMonth.year.toString();
    final String monthStr = currentMonth.month.toString().padLeft(2, '0');

    setState(() {
      periodDays = {};
    });

    final result = await db.rawQuery(
      '''SELECT day, timestamp FROM entries WHERE strftime('%Y', timestamp) = ? AND strftime('%m', timestamp) = ? AND mperiod = 1''',
      [yearStr, monthStr],
    );

    final newPeriodDays = result.map((row) => row['day'] as int).toSet();
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

  void _syncToCurrentMonthIfNeeded() {
    final now = DateUtilHelper.getCurrentMonth();
    if (!DateUtilHelper.isSameMonth(currentMonth, now)) {
      setState(() {
        currentMonth = DateTime(now.year, now.month);
        entriesPerDay.clear();
        loadEntries();
        if (isReviewMode) loadReviewedDays();
        loadPeriodDays();
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
      final ts = DateTime.parse(row['timestamp'] as String);
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
      loadPeriodDays();
    }
  }

  @override
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
                    loadPeriodDays();
                    if (isReviewMode) {
                      loadReviewedDays();
                    }
                  },
                ),
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
                'Please select the day you want to make an entry for',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            // Medications Card
            MedicationsCard(),
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
            // Entry Review List
            if (isReviewMode && selectedDate != null)
              EntryReviewList(
                selectedDate: selectedDate!,
                onDataChanged: () {
                  setState(() {
                    loadEntries();
                    loadPeriodDays();
                    if (isReviewMode) {
                      loadReviewedDays();
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
