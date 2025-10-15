import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

String nowStamp() => DateTime.now().toIso8601String().replaceAll(':', '-');

void main(List<String> args) {
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  final runtimePath = path.join(userProfile, 'OneDrive', 'Documentos', 'gestao_incidentes.db');
  final packagedPath = 'assets/db/gestao_incidentes.db';

  if (!File(runtimePath).existsSync()) {
    print('Runtime DB not found at: $runtimePath');
    return;
  }
  if (!File(packagedPath).existsSync()) {
    print('Packaged DB not found at: $packagedPath');
    return;
  }

  // Backup runtime DB
  final backupPath = '$runtimePath.bak.${nowStamp()}';
  File(runtimePath).copySync(backupPath);
  print('Backup created at: $backupPath');

  final packaged = sqlite3.open(packagedPath);
  final runtime = sqlite3.open(runtimePath);

  final createdTables = <String>[];
  final addedColumns = <String>[];

  try {
    final tables = packaged.select("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    for (final t in tables) {
      final name = t['name']?.toString() ?? '';
      final createSql = t['sql']?.toString() ?? '';
      if (name.isEmpty) continue;

      final existing = runtime.select("SELECT name FROM sqlite_master WHERE type='table' AND name = ?", [name]);
      if (existing.isEmpty) {
        print('Creating missing table: $name');
        runtime.execute(createSql);
        createdTables.add(name);
        continue;
      }

      // Table exists → check missing columns
      final packagedCols = packaged.select("PRAGMA table_info('$name')");
      final runtimeCols = runtime.select("PRAGMA table_info('$name')");
      final runtimeColNames = runtimeCols.map((r) => r['name']?.toString() ?? '').toSet();
      for (final pc in packagedCols) {
        final colName = pc['name']?.toString() ?? '';
        final colType = pc['type']?.toString() ?? '';
        final dflt = pc['dflt_value'];
        if (colName.isEmpty) continue;
        if (!runtimeColNames.contains(colName)) {
          // Add column with type and default if possible
          final defaultSql = dflt != null ? ' DEFAULT ${dflt.toString()}' : '';
          final alter = "ALTER TABLE $name ADD COLUMN $colName $colType$defaultSql;";
          print('Adding missing column $colName to $name');
          runtime.execute(alter);
          addedColumns.add('$name.$colName');
        }
      }
    }

    print('\nMigration summary:');
    if (createdTables.isNotEmpty) print('  Created tables: ${createdTables.join(', ')}');
    if (addedColumns.isNotEmpty) print('  Added columns: ${addedColumns.join(', ')}');
    if (createdTables.isEmpty && addedColumns.isEmpty) print('  Nothing to do - schemas already match');
  } catch (e) {
    print('Migration failed: $e');
    print('Restoring from backup...');
    try {
      runtime.dispose();
      packaged.dispose();
      File(backupPath).copySync(runtimePath);
      print('Restored backup to runtime DB');
    } catch (ex) {
      print('Failed to restore backup: $ex');
    }
    return;
  } finally {
    runtime.dispose();
    packaged.dispose();
  }
}
