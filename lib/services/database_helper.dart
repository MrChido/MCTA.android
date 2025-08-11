import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper(); // this will ensure all dart ducments are reading the same database at that moment
  //it avoids mulitple instances from spawning accidentaly
  static Database? _database;

  // Log file handling
  Future<void> _logError(String error) async {
    try {
      final directory = Directory('/storage/emulated/0/Documents');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(join(directory.path, 'MelsSymptomTracker_log.txt'));
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString(
        '$timestamp: $error\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // If logging fails, we can't do much in release mode
      print("Failed to log error: $e");
    }
  }

  Future<Database> get database async {
    try {
      if (_database != null) {
        print("Returning existing database instance");
        return _database!;
      }
      print("No existing database, initializing new one");
      _database = await _initDatabase();
      return _database!;
    } catch (e, stackTrace) {
      print("Error getting database: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<Set<int>> getPeriodDays(DateTime month) async {
    final db = await database;
    final String yearStr = month.year.toString();
    final String monthStr = month.month.toString().padLeft(2, '0');

    // Query using the timestamp for entries, ensuring we only get entries from the exact month and year
    final List<Map<String, dynamic>> result = await db.rawQuery(
        '''SELECT DISTINCT CAST(strftime('%d', timestamp) AS INTEGER) as day
           FROM entries 
           WHERE strftime('%Y', timestamp) = ? 
           AND strftime('%m', timestamp) = ?
           AND mperiod = 1''', [yearStr, monthStr]);

    return result.map((row) => row['day'] as int).toSet();
  }

  Future<List<int>> getDaysWithEntries(int year, month) async {
    final db = await database;
    //formating month to two digits for SQLite compatability
    final String paddedMonth = month.toString().padLeft(2, '0');

    final List<Map<String, dynamic>> result = await db.rawQuery(
        '''SELECT DISTINCT CAST(strftime('%d', timestamp) AS INTEGER) as day FROM entries WHERE strftime('%Y', timestamp) = ? AND strftime('%m', timestamp)=?''',
        [year.toString(), paddedMonth]);

    return result.map((row) => row['day'] as int).toList();
  }
  //this querries month and year as well as day now making reports more refined

  Future<Database> _initDatabase() async {
    try {
      print("Starting database initialization...");

      final directory = await getApplicationDocumentsDirectory();
      print("Got documents directory: ${directory.path}");
      print("Directory exists before creation: ${await directory.exists()}");

      // Try to create directory with error handling
      try {
        await directory.create(recursive: true);
        print("Directory created/verified successfully");
      } catch (e) {
        print("Error creating directory: $e");
        // Continue anyway as the directory might exist
      }

      String path = join(directory.path, "symptoms.db");
      print("Full database path: $path");
      print("Directory exists after creation: ${await directory.exists()}");
      print("Directory path permissions: ${directory.statSync().modeString()}");

      // Only attempt recovery if database exists but can't be opened
      if (await databaseExists(path)) {
        try {
          final testDb = await openDatabase(path, readOnly: true);
          await testDb.close(); // Properly close the test connection
        } catch (e) {
          print("Database exists but cannot be opened: $e");
          // Only delete if we can't even read the file
          if (e.toString().contains('unable to open database file')) {
            print("Database file is corrupted, attempting recovery...");
            try {
              await deleteDatabase(path);
              print("Corrupted database file deleted successfully");
            } catch (delError) {
              print("Failed to delete corrupted database: $delError");
              // If we can't delete it, let's try to continue anyway
            }
          }
        }
      }

      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          print("Creating new database at version $version");
          await db.execute('''
            CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day INTEGER,
            severity INTEGER,
            fatigue INTEGER,
            timestamp TEXT,
            BSugars TEXT,
            mnm TEXT,
            activities TEXT,
            symptoms TEXT,
            wake INTEGER,
            sleep INTEGER,
            water INTEGER,
            hHealth TEXT,
            weight REAL,
            mperiod INTEGER DEFAULT 0
          )
        ''');
          print("Database created successfully");
        },
        onOpen: (db) async {
          print("Database opened successfully");
          final tables = await db
              .rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
          print("Available tables: ${tables.map((t) => t['name']).toList()}");
        },
      );
    } catch (e, stackTrace) {
      print("Error initializing database: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<void> checkDEntries() async {
    final db = await DatabaseHelper().database;
    var result = await db.rawQuery("PRAGMA table_info(entries)");
    print(result);
  }

  Future<void> insertEntry(
    int day,
    int severity,
    bool fatigue,
    String sugars,
    String mnm,
    String activities,
    String symptoms,
    int wake,
    int sleep,
    int water,
    String hHealth,
    double weight,
    bool mperiod,
  ) async {
    try {
      await _logError("Starting insert operation");

      // Get database instance with detailed error logging
      Database? dbInstance;
      try {
        dbInstance = await database;
        await _logError("Database connection obtained successfully");
      } catch (e) {
        await _logError("Failed to get database instance: $e");
        rethrow;
      }
      final db = dbInstance;

      // Verify database is writable
      try {
        await db.rawQuery('PRAGMA quick_check');
        print("Database is readable and writable");
      } catch (e) {
        print("Database write check failed: $e");
        rethrow;
      }

      // Create all the data
      String mnmInput = mnm.isNotEmpty ? jsonEncode(mnm) : '[]';
      final currentTime = DateTime.now();
      final timestamp = DateTime(currentTime.year, currentTime.month, day,
              currentTime.hour, currentTime.minute, currentTime.second)
          .toIso8601String();
      String activitiesInput =
          activities.isNotEmpty ? jsonEncode(activities) : '[]';
      String symptomsInput = symptoms.isNotEmpty ? jsonEncode(symptoms) : '[]';

      // Create the entry map
      final entry = {
        'day': day,
        'severity': severity,
        'fatigue': fatigue ? 1 : 0,
        'wake': wake,
        'sleep': sleep,
        'timestamp': timestamp,
        'BSugars': sugars,
        'mnm': mnmInput,
        'activities': activitiesInput,
        'symptoms': symptomsInput,
        'water': water,
        'hHealth': hHealth,
        'weight': weight,
        'mperiod': mperiod ? 1 : 0, // Convert boolean to integer
      };

      print("Attempting to insert entry with data: $entry");

      // Verify table exists before insert
      final tables = await db.rawQuery(
          'SELECT name FROM sqlite_master WHERE type="table" AND name="entries"');
      if (tables.isEmpty) {
        throw Exception("Table 'entries' does not exist!");
      }

      // Perform the insert within a transaction
      int id = -1;
      await db.transaction((txn) async {
        try {
          id = await txn.insert('entries', entry);
          print("Entry inserted successfully with id: $id");

          // Immediately verify within the same transaction
          final check = await txn.query('entries',
              where: 'id = ?', whereArgs: [id], limit: 1);
          if (check.isEmpty) {
            throw Exception(
                "Insert verification failed - entry not found immediately after insert");
          }
          print("Insert verified within transaction");
        } catch (e) {
          print("Transaction failed: $e");
          rethrow;
        }
      });

      // Verify the insert after transaction
      final inserted =
          await db.query('entries', where: 'id = ?', whereArgs: [id], limit: 1);
      if (inserted.isEmpty) {
        throw Exception(
            "Entry verification failed - couldn't find inserted row");
      }
      print("Verified inserted entry: ${inserted.first}");

      // Get all entries for verification (within try-catch block)
      final allEntries = await db.query('entries');
      print("All entries after insert: $allEntries");
    } catch (e, stackTrace) {
      final errorMsg = "Error inserting entry: $e\nStack trace: $stackTrace";
      await _logError(errorMsg);
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<int> getEntryCountForDay(int day) async {
    final db = await database;
    List<Map<String, dynamic>> result =
        await db.query('entries', where: 'day = ?', whereArgs: [day]);
    return result.length;
  }

  Future<List<Map<String, dynamic>>> getAllEntriesForMonth(
      DateTime month) async {
    final db = await database;
    final String yearStr = month.year.toString();
    final String monthStr = month.month.toString().padLeft(2, '0');

    return await db.rawQuery(
      '''SELECT * FROM entries WHERE strftime('%Y', timestamp) =? AND strftime('%m',timestamp) = ? ORDER BY timestamp DESC''',
      [yearStr, monthStr],
    );
  }

  Future<List<Map<String, dynamic>>> getEntriesforDate(DateTime date) async {
    try {
      final db = await database;
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // First check if the table exists
      final tables = await db.rawQuery(
          'SELECT name FROM sqlite_master WHERE type="table" AND name="entries"');
      if (tables.isEmpty) {
        print(
            "Warning: entries table does not exist when querying for date $formattedDate");
        return [];
      }

      final entries = await db.query(
        'entries',
        where: "timestamp LIKE ?",
        whereArgs: ["$formattedDate%"],
      );

      print("Found ${entries.length} entries for date $formattedDate");
      return entries;
    } catch (e, stackTrace) {
      print("Error getting entries for date: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<void> deleteEntriesByTimestamp(String timestamp) async {
    try {
      final db = await database;

      // First verify the entries exist
      final entriesToDelete = await db.query(
        'entries',
        where: "timestamp LIKE ?",
        whereArgs: [timestamp],
      );
      print(
          "Found ${entriesToDelete.length} entries to delete for timestamp: $timestamp");

      // Use a transaction to ensure database consistency
      await db.transaction((txn) async {
        final result = await txn.delete(
          'entries',
          where: "timestamp LIKE ?",
          whereArgs: [timestamp],
        );

        if (result == 0) {
          print("No entries were deleted for timestamp: $timestamp");
        } else {
          print("Successfully deleted $result entries");
        }

        // Verify deletion
        final remainingEntries = await txn.query(
          'entries',
          where: "timestamp LIKE ?",
          whereArgs: [timestamp],
        );

        if (remainingEntries.isNotEmpty) {
          throw Exception("Deletion verification failed - entries still exist");
        }
      });
    } catch (e, stackTrace) {
      print("Error deleting entries: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEntriesForDay(int day) async {
    final db = await database;
    List<Map<String, dynamic>> result =
        await db.query('entries', where: 'day = ?', whereArgs: [day]);

    return result.map((entry) {
      entry['mnm'] = entry['mnm'] != null ? jsonDecode(entry['mnm']) : [];
      entry['activities'] =
          entry['activities'] != null ? jsonDecode(entry['activities']) : [];
      entry['symptoms'] =
          entry['symptoms'] != null ? jsonDecode(entry['symptoms']) : [];
      return entry;
    }).toList();
  }
}
