import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/secure_logger.dart';


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

    // Security: Use path_provider instead of environment variable
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'gestao_incidentes.db');
    
    // Security: Validate canonical path
    final canonicalPath = File(path).absolute.path;
    if (!canonicalPath.startsWith(dir.path)) {
      throw Exception('SECURITY: Invalid database path detected');
    }

    if (!File(path).existsSync()) {
      final data = await rootBundle.load('assets/db/gestao_incidentes.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onOpen: _onOpen,
      ),
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auditoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT NOT NULL,
        user_id INTEGER,
        acao TEXT NOT NULL,
        detalhe TEXT,
        FOREIGN KEY (user_id) REFERENCES usuarios (id)
      )
    ''');
  }

  Future _onOpen(Database db) async {
    // Verificar se a tabela existe
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'auditoria'],
    );

    if (tables.isEmpty) {
      SecureLogger.database('Creating auditoria table');
      await _onCreate(db, 1);
    }
  }

  // Método para debug
  Future<void> checkTables() async {
    final db = await database;
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );
    SecureLogger.database('Tables in database:');
    for (var table in tables) {
      SecureLogger.debug('Table: ${table['name']}');
    }
  }

  /// Return a list of column names for [table]. Useful to write defensive
  /// updates that don't reference missing columns on older DB schemas.
  Future<List<String>> tableColumns(String table) async {
    // Security: Whitelist of allowed tables to prevent SQL injection
    const allowedTables = ['usuarios', 'incidentes', 'auditoria'];
    if (!allowedTables.contains(table.toLowerCase())) {
      throw ArgumentError('Invalid table name: $table');
    }
    
    final db = await database;
    // Use parameterized query for safety
    final rows = await db.rawQuery("PRAGMA table_info(?)", [table]);
    return rows.map((r) => r['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Sync runtime database back to assets (development only)
  /// Call this after creating/modifying users to update the packaged DB
  /// Note: Auto-push disabled for security - manual commit required
  Future<void> syncToAssets({bool enableAutoPush = false}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final runtimePath = join(dir.path, 'gestao_incidentes.db');
      
      // Only sync in debug mode
      if (!const bool.fromEnvironment('dart.vm.product')) {
        // Get project root (assuming we're in build output)
        // This won't work in release builds, which is intentional
        final projectRoot = Directory.current.path;
        final assetsPath = join(projectRoot, 'assets', 'db', 'gestao_incidentes.db');
        
        if (File(runtimePath).existsSync()) {
          await File(runtimePath).copy(assetsPath);
          SecureLogger.database('Database synced to assets/db/');
          
          // Auto commit (opt-in only for security)
          if (enableAutoPush) {
            SecureLogger.warning('SECURITY WARNING: Auto-push is enabled. This should only be used in development.');
            try {
              final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
              
              // Git add with timeout
              final addResult = await Process.run(
                'git',
                ['add', 'assets/db/gestao_incidentes.db'],
                workingDirectory: projectRoot,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException('Git add timeout'),
              );
              
              if (addResult.exitCode == 0) {
                // Git commit with timeout
                final commitResult = await Process.run(
                  'git',
                  ['commit', '-m', 'auto: update users database [$timestamp]'],
                  workingDirectory: projectRoot,
                ).timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => throw TimeoutException('Git commit timeout'),
                );
                
                if (commitResult.exitCode == 0) {
                  SecureLogger.info('Auto-commit created');
                  
                  // Git push with timeout
                  final pushResult = await Process.run(
                    'git',
                    ['push', 'origin', 'main'],
                    workingDirectory: projectRoot,
                  ).timeout(
                    const Duration(seconds: 30),
                    onTimeout: () => throw TimeoutException('Git push timeout'),
                  );
                  
                  if (pushResult.exitCode == 0) {
                    SecureLogger.info('Auto-push to GitHub completed');
                    SecureLogger.database('DB updated in repository');
                  } else {
                    SecureLogger.warning('Push failed - execute manually: git push origin main');
                  }
                } else {
                  final stderr = commitResult.stderr.toString();
                  if (stderr.contains('nothing to commit')) {
                    SecureLogger.info('No changes to commit (DB already synced)');
                  } else {
                    SecureLogger.warning('Commit failed');
                  }
                }
              }
            } catch (e, stackTrace) {
              SecureLogger.error('Git automation failed', e, stackTrace);
              SecureLogger.info('Reminder: Commit and push manually!');
            }
          } else {
            SecureLogger.info('Auto-push disabled for security.');
            SecureLogger.info('To enable, use: syncToAssets(enableAutoPush: true)');
            SecureLogger.info('Reminder: Commit manually if needed.');
          }
        }
      }
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to sync DB to assets', e, stackTrace);
    }
  }
}
