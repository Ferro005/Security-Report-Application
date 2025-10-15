import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


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

    final userProfile = Platform.environment['USERPROFILE'];
    final path = join(userProfile!, 'OneDrive', 'Documentos', 'gestao_incidentes.db');

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
      print('Criando tabela auditoria...');
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
    print('Tabelas no banco:');
    for (var table in tables) {
      print(table['name']);
    }
  }

  /// Return a list of column names for [table]. Useful to write defensive
  /// updates that don't reference missing columns on older DB schemas.
  Future<List<String>> tableColumns(String table) async {
    final db = await database;
    final rows = await db.rawQuery("PRAGMA table_info('$table')");
    return rows.map((r) => r['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Sync runtime database back to assets (development only)
  /// Call this after creating/modifying users to update the packaged DB
  Future<void> syncToAssets() async {
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
          print('✓ Base de dados sincronizada com assets/db/');
          
          // Auto commit and push (debug only)
          try {
            final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
            
            // Git add
            final addResult = await Process.run(
              'git',
              ['add', 'assets/db/gestao_incidentes.db'],
              workingDirectory: projectRoot,
            );
            
            if (addResult.exitCode == 0) {
              // Git commit
              final commitResult = await Process.run(
                'git',
                ['commit', '-m', 'auto: update users database [$timestamp]'],
                workingDirectory: projectRoot,
              );
              
              if (commitResult.exitCode == 0) {
                print('✓ Commit automático criado');
                
                // Git push
                final pushResult = await Process.run(
                  'git',
                  ['push', 'origin', 'main'],
                  workingDirectory: projectRoot,
                );
                
                if (pushResult.exitCode == 0) {
                  print('✓ Push automático para GitHub concluído');
                  print('  📦 DB atualizada no repositório!');
                } else {
                  print('⚠️  Push falhou: ${pushResult.stderr}');
                  print('  Execute manualmente: git push origin main');
                }
              } else {
                final stderr = commitResult.stderr.toString();
                if (stderr.contains('nothing to commit')) {
                  print('ℹ️  Nenhuma alteração para commit (DB já sincronizada)');
                } else {
                  print('⚠️  Commit falhou: $stderr');
                }
              }
            }
          } catch (e) {
            print('⚠️  Git automation falhou: $e');
            print('  Lembrete: Faça commit e push manualmente!');
          }
        }
      }
    } catch (e) {
      print('Aviso: Não foi possível sincronizar DB com assets: $e');
    }
  }
}
