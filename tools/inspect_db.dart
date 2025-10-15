import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void main() {
  final path = 'assets/db/gestao_incidentes.db';
  if (!File(path).existsSync()) {
    print('DB file not found at: $path');
    return;
  }
  final db = sqlite3.open(path);
  try {
    // Print table schema
    final schema = db.select("PRAGMA table_info('usuarios')");
    print('Schema for usuarios:');
    for (final col in schema) {
      print('  ${col['name']} (type=${col['type']})');
    }

    // Select a safe concatenated projection to print values without relying on
    // the Row API methods.
    final rows = db.select("SELECT id || ' | ' || email || ' | hash=' || COALESCE(hash,'<null>') || ' | tipo=' || COALESCE(tipo,'') AS txt FROM usuarios");
    print('\nRows: ${rows.length}');
    for (final row in rows) {
      print(row['txt']);
    }
  } catch (e) {
    print('Error querying DB: $e');
  } finally {
    db.dispose();
  }
}
