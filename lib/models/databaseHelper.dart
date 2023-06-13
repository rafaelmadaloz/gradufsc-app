import 'package:gradufsc/models/settings.dart';
import 'package:gradufsc/models/course.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static const String settingsTable = 'settings';
  static const String courseTable = 'course';

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'my_app2.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  static void _createDatabase(Database db, int version) async {
    await db.execute('CREATE TABLE $settingsTable (authCode TEXT)');
    await db.execute(
        'CREATE TABLE $courseTable (id TEXT PRIMARY KEY, name TEXT, professors TEXT, class TEXT, code TEXT, semester TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
  }

  static Future<void> insertSettings(Settings settings) async {
    final db = await open();
    await db.insert(settingsTable, settings.toMap());
  }

  static Future<Settings?> getSettings() async {
    final db = await open();
    final maps = await db.query(settingsTable);

    if (maps.isNotEmpty) {
      return Settings.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<bool> hasAuthCode() async {
    final db = await open();
    final result = await db.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM $settingsTable WHERE authCode IS NOT NULL)');

    final maps = await db.query(settingsTable);

    if (maps.isNotEmpty) {
      Settings setts = Settings.fromMap(maps.first);
    }

    return Sqflite.firstIntValue(result) == 1;
  }

  // - Course

  static Future<void> insertCourse(Course course) async {
    final db = await open();
    await db.insert(courseTable, course.toMap());
  }

  Future<List<Course>> getAllCourses() async {
    final db = await open();
    final result = await db.query(courseTable);
    return result.map((json) => Course.fromJson(json)).toList();
  }
}
