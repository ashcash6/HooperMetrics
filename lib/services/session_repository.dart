import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/session.dart';

class SessionRepository {
  SessionRepository._();
  static final SessionRepository instance = SessionRepository._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final dbPath = join(dir, 'hooper_metrics.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date INTEGER NOT NULL,
          overall_score REAL NOT NULL,
          detailed_scores TEXT NOT NULL,
          tips TEXT NOT NULL,
          shot_count INTEGER NOT NULL
        )
      '''),
    );
  }

  Future<int> save(Session session) async {
    final db = await _database;
    return db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getAll() async {
    final db = await _database;
    final rows = await db.query('sessions', orderBy: 'date DESC');
    return rows.map(Session.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
