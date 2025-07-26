import 'package:spoonie/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

int monthNameToNumber(String monthName) {
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
  return months[monthName] ?? 0; //fallback in case month is invalid
}

Future<List<Map<String, dynamic>>> getEntriesForDate(
    {required int day, required int year, required String monthName}) async {
  final db = await DatabaseHelper.instance.database;

  final int month = monthNameToNumber(monthName);
  final String formattedDate =
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  final results = await db.query(
    'entries',
    where: "strftime('%Y-%m-%d' , timestamp) =?",
    whereArgs: [formattedDate],
  );
  return results;
}

//sleep hour tracker
int toMinutes(int time) {
  final hour =
      time ~/ 100; //recieving the whole hours of a 24-hour based time stamp
  final minute = time % 100; //recieving the minutes left over
  return hour * 60 +
      minute; //estbilishing the whole timestmp as minutes exclusively
}

Future<int> sleepMinder(Database db, Map<String, dynamic> entry) async {
  print('sleepMinder invoked');
  final rawTimestamp = entry['timestamp'];
  final date = rawTimestamp.split('T')[0];
  final result = await db.query(
    'entries',
    columns: [
      'sleep',
      'wake',
    ],
    where: 'timestamp LIKE ?',
    whereArgs: [date + '%'],
  );
  print('query result: $result');
  if (result.isEmpty) {
    print('No sleep data found for $date');
    return 0;
  }
  //extract values from dtabase
  int sleep = result[0]['sleep'] as int;
  int wake = result[0]['wake'] as int;
  print(' sleep $sleep | wake: $wake');
  int sleepMinutes = toMinutes(sleep);
  int wakeMinutes = toMinutes(wake);
  //caluculate the pure and distilled time
  int pureTime = (wakeMinutes >= sleepMinutes)
      ? wakeMinutes - sleepMinutes
      : (1440 - sleepMinutes) + wakeMinutes;

  int distilledTime = pureTime ~/ 60;
  print('pureTime :$pureTime | distilledTime: $distilledTime');
  return distilledTime;
}
