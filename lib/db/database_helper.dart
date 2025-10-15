import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'gestao_incidentes.db');

    if (!File(path).existsSync()) {
      final data = await rootBundle.load('assets/db/gestao_incidentes.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await databaseFactory.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
    ));
  }

  /// Return a list of column names for [table]. Useful to write defensive
  /// updates that don't reference missing columns on older DB schemas.
  Future<List<String>> tableColumns(String table) async {
    final db = await database;
    final rows = await db.rawQuery("PRAGMA table_info('$table')");
    return rows.map((r) => r['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
}
