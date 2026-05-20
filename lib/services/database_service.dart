import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diabetes_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_description TEXT NOT NULL,
        calories REAL,
        carbs REAL,
        glucose_before REAL,
        glucose_after REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vitals_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        weight REAL,
        height REAL,
        systolic INTEGER,
        diastolic INTEGER,
        heart_rate INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        sleep_time TEXT,
        wake_time TEXT,
        walking_minutes INTEGER,
        exercise_minutes INTEGER,
        screen_time_hours REAL,
        driving_hours REAL,
        activity_notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        time TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        days TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Seed default notifications
    await db.insert('notification_settings', {
      'type': 'bedtime',
      'title': '🌙 Bedtime Reminder',
      'body': 'Time to wind down! Good sleep helps control blood sugar.',
      'time': '22:00',
      'is_enabled': 1,
      'days': '',
    });
    await db.insert('notification_settings', {
      'type': 'medicine',
      'title': '💊 Medicine Reminder',
      'body': 'Don\'t forget to take your daily medication.',
      'time': '08:00',
      'is_enabled': 1,
      'days': '',
    });
    await db.insert('notification_settings', {
      'type': 'insulin',
      'title': '💉 Insulin Reminder',
      'body': 'Time for your insulin dosage. Stay on schedule!',
      'time': '13:00',
      'is_enabled': 0,
      'days': '',
    });
    await db.insert('notification_settings', {
      'type': 'log',
      'title': '📋 Log Your Day',
      'body': 'Did you log your meals and vitals today?',
      'time': '20:00',
      'is_enabled': 1,
      'days': '',
    });
  }

  // ─── FOOD ENTRIES ────────────────────────────────────────

  Future<int> insertFoodEntry(FoodEntry entry) async {
    final db = await database;
    return await db.insert('food_entries', entry.toMap());
  }

  Future<List<FoodEntry>> getFoodEntriesForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'food_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<List<FoodEntry>> getFoodEntriesForMonth(int year, int month) async {
    final db = await database;
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'food_entries',
      where: "date LIKE ?",
      whereArgs: ['$prefix%'],
      orderBy: 'date ASC, created_at ASC',
    );
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<List<FoodEntry>> getAllFoodEntries() async {
    final db = await database;
    final maps = await db.query('food_entries', orderBy: 'date DESC, created_at DESC');
    return maps.map(FoodEntry.fromMap).toList();
  }

  Future<int> updateFoodEntry(FoodEntry entry) async {
    final db = await database;
    return await db.update('food_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteFoodEntry(int id) async {
    final db = await database;
    return await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ─── VITALS ──────────────────────────────────────────────

  Future<int> upsertVitals(VitalsEntry entry) async {
    final db = await database;
    final existing = await db.query('vitals_entries', where: 'date = ?', whereArgs: [entry.date]);
    if (existing.isEmpty) {
      return await db.insert('vitals_entries', entry.toMap());
    } else {
      final id = existing.first['id'] as int;
      await db.update('vitals_entries', entry.toMap(), where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  Future<VitalsEntry?> getVitalsForDate(String date) async {
    final db = await database;
    final maps = await db.query('vitals_entries', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return VitalsEntry.fromMap(maps.first);
  }

  Future<List<VitalsEntry>> getVitalsForMonth(int year, int month) async {
    final db = await database;
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query('vitals_entries', where: "date LIKE ?", whereArgs: ['$prefix%'], orderBy: 'date ASC');
    return maps.map(VitalsEntry.fromMap).toList();
  }

  Future<List<VitalsEntry>> getAllVitals() async {
    final db = await database;
    final maps = await db.query('vitals_entries', orderBy: 'date DESC');
    return maps.map(VitalsEntry.fromMap).toList();
  }

  Future<VitalsEntry?> getLatestVitals() async {
    final db = await database;
    final maps = await db.query('vitals_entries', orderBy: 'date DESC', limit: 1);
    if (maps.isEmpty) return null;
    return VitalsEntry.fromMap(maps.first);
  }

  // ─── ACTIVITY ────────────────────────────────────────────

  Future<int> upsertActivity(ActivityEntry entry) async {
    final db = await database;
    final existing = await db.query('activity_entries', where: 'date = ?', whereArgs: [entry.date]);
    if (existing.isEmpty) {
      return await db.insert('activity_entries', entry.toMap());
    } else {
      final id = existing.first['id'] as int;
      await db.update('activity_entries', entry.toMap(), where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  Future<ActivityEntry?> getActivityForDate(String date) async {
    final db = await database;
    final maps = await db.query('activity_entries', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return ActivityEntry.fromMap(maps.first);
  }

  Future<List<ActivityEntry>> getActivityForMonth(int year, int month) async {
    final db = await database;
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query('activity_entries', where: "date LIKE ?", whereArgs: ['$prefix%'], orderBy: 'date ASC');
    return maps.map(ActivityEntry.fromMap).toList();
  }

  Future<List<ActivityEntry>> getAllActivities() async {
    final db = await database;
    final maps = await db.query('activity_entries', orderBy: 'date DESC');
    return maps.map(ActivityEntry.fromMap).toList();
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────

  Future<List<NotificationSetting>> getAllNotifications() async {
    final db = await database;
    final maps = await db.query('notification_settings', orderBy: 'id ASC');
    return maps.map(NotificationSetting.fromMap).toList();
  }

  Future<int> insertNotification(NotificationSetting setting) async {
    final db = await database;
    return await db.insert('notification_settings', setting.toMap());
  }

  Future<void> updateNotification(NotificationSetting setting) async {
    final db = await database;
    await db.update('notification_settings', setting.toMap(), where: 'id = ?', whereArgs: [setting.id]);
  }

  Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete('notification_settings', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ANALYTICS HELPERS ───────────────────────────────────

  Future<List<DailySummary>> getDailySummariesForMonth(int year, int month) async {
    final foods = await getFoodEntriesForMonth(year, month);
    final vitals = await getVitalsForMonth(year, month);
    final activities = await getActivityForMonth(year, month);

    final foodsByDate = <String, List<FoodEntry>>{};
    for (final f in foods) {
      foodsByDate.putIfAbsent(f.date, () => []).add(f);
    }

    final vitalsByDate = {for (final v in vitals) v.date: v};
    final activitiesByDate = {for (final a in activities) a.date: a};

    final allDates = {
      ...foodsByDate.keys,
      ...vitalsByDate.keys,
      ...activitiesByDate.keys,
    }.toList()..sort();

    return allDates.map((date) => DailySummary(
      date: date,
      foodEntries: foodsByDate[date] ?? [],
      vitals: vitalsByDate[date],
      activity: activitiesByDate[date],
    )).toList();
  }

  Future<Map<String, dynamic>> getAnalyticsSummary(int year, int month) async {
    final summaries = await getDailySummariesForMonth(year, month);
    if (summaries.isEmpty) return {};

    final glucoseReadings = summaries
        .where((s) => s.avgGlucoseBefore > 0)
        .map((s) => s.avgGlucoseBefore)
        .toList();

    final controlledDays = summaries.where((s) => s.isGlucoseControlled).toList();

    double avgGlucose = 0;
    double minGlucose = 0;
    double maxGlucose = 0;
    if (glucoseReadings.isNotEmpty) {
      avgGlucose = glucoseReadings.reduce((a, b) => a + b) / glucoseReadings.length;
      minGlucose = glucoseReadings.reduce((a, b) => a < b ? a : b);
      maxGlucose = glucoseReadings.reduce((a, b) => a > b ? a : b);
    }

    final avgWalking = summaries
        .where((s) => s.activity?.walkingMinutes != null)
        .map((s) => s.activity!.walkingMinutes!.toDouble())
        .fold<double>(0, (a, b) => a + b);
    final walkingDays = summaries.where((s) => s.activity?.walkingMinutes != null).length;

    return {
      'totalDaysLogged': summaries.length,
      'controlledDays': controlledDays.length,
      'avgGlucose': avgGlucose,
      'minGlucose': minGlucose,
      'maxGlucose': maxGlucose,
      'avgWalkingMinutes': walkingDays > 0 ? avgWalking / walkingDays : 0,
      'summaries': summaries,
      'controlledDaySummaries': controlledDays,
    };
  }
}
