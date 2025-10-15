import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void inspect(String path) {
  print('\nInspecting DB: $path');
  if (!File(path).existsSync()) {
    print('  Not found.');
    return;
  }
  final db = sqlite3.open(path);
  try {
    final schema = db.select("PRAGMA table_info('usuarios')");
    print('  Schema for usuarios:');
    for (final col in schema) {
      print('    ${col['name']} (type=${col['type']})');
    }
  } catch (e) {
    print('  Error: $e');
  } finally {
    db.dispose();
  }
}

void main() {
  final packaged = 'assets/db/gestao_incidentes.db';
  final runtime = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  inspect(packaged);
  inspect(runtime);
}
