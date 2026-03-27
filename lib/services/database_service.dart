import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  final _tableUpdates = StreamController<String>.broadcast();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'atlas_fitness.db');
    debugPrint('📂 Opening SQLite database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        displayName TEXT NOT NULL,
        photoUrl TEXT,
        bio TEXT,
        currentStreak INTEGER DEFAULT 0,
        longestStreak INTEGER DEFAULT 0,
        badges TEXT DEFAULT '[]',
        createdAt INTEGER NOT NULL,
        lastWorkoutDate INTEGER,
        isAdmin INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        workoutName TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        exercises TEXT NOT NULL,
        durationMinutes INTEGER,
        completedAt INTEGER,
        intensityRating INTEGER,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        exerciseName TEXT NOT NULL,
        category TEXT,
        sets TEXT NOT NULL,
        notes TEXT,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE body_metrics (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        metricType TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        userId TEXT PRIMARY KEY,
        totalWorkouts INTEGER DEFAULT 0,
        totalMinutes INTEGER DEFAULT 0,
        totalExercises INTEGER DEFAULT 0,
        currentStreak INTEGER DEFAULT 0,
        longestStreak INTEGER DEFAULT 0,
        weeklyGoal INTEGER DEFAULT 3,
        favoriteExercise TEXT DEFAULT 'Not set yet',
        lastUpdated INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userPhotoUrl TEXT,
        content TEXT NOT NULL,
        imageUrl TEXT,
        likes TEXT DEFAULT '[]',
        commentCount INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE friends (
        id TEXT PRIMARY KEY,
        fromUserId TEXT NOT NULL,
        toUserId TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        targetValue INTEGER NOT NULL,
        badgeId TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        participants TEXT DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE user_challenge_progress (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        challengeId TEXT NOT NULL,
        currentValue INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        completedAt INTEGER,
        UNIQUE(userId, challengeId)
      )
    ''');

    await db.execute('''
      CREATE TABLE bug_reports (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT DEFAULT 'Medium',
        status TEXT DEFAULT 'Submitted',
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_rooms (
        id TEXT PRIMARY KEY,
        participants TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageTime INTEGER,
        lastMessageSenderId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isRead INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        userId TEXT PRIMARY KEY,
        notificationsEnabled INTEGER DEFAULT 1,
        workoutReminders INTEGER DEFAULT 1,
        reminderTime TEXT DEFAULT '09:00',
        preferredUnits TEXT DEFAULT 'metric',
        privateProfile INTEGER DEFAULT 0,
        theme TEXT DEFAULT 'system',
        createdAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        exerciseName TEXT NOT NULL,
        duration INTEGER NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
  }

  // Notify all stream listeners that the given table has changed.
  void notify(String table) => _tableUpdates.add(table);

  // Returns a stream that emits once immediately (null) and then again
  // whenever [table] is notified. Consumers should respond by re-querying.
  Stream<void> watchTable(String table) async* {
    yield null;
    await for (final t in _tableUpdates.stream) {
      if (t == table) yield null;
    }
  }

  // Encode a list of strings to a JSON string for storage.
  static String encodeList(List<dynamic> list) => jsonEncode(list);

  // Decode a JSON string back to a list.
  static List<dynamic> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  // Encode any object to JSON.
  static String encodeJson(dynamic obj) => jsonEncode(obj);

  // Decode a JSON string to a dynamic object.
  static dynamic decodeJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json);
    } catch (_) {
      return null;
    }
  }
}
