import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main(List<String> args) {
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }
  final passwordToCheck = args.isNotEmpty ? args[0] : 'Admin1234';
  final db = sqlite3.open(dbPath);
  try {
    final rows = db.select("SELECT id, email, hash FROM usuarios WHERE email = 'admin@exemplo.com' LIMIT 1");
    if (rows.isEmpty) {
      print('Admin user not found');
      return;
    }
    final row = rows.first;
    final hash = row['hash']?.toString() ?? '';
    print('Found admin id=${row['id']}, hash_length=${hash.length}');
    if (hash.isEmpty) {
      print('No hash set for admin.');
      return;
    }
    try {
      final ok = BCrypt.checkpw(passwordToCheck, hash);
      print('BCrypt.checkpw for password "$passwordToCheck": $ok');
    } catch (e) {
      print('Error checking bcrypt: $e');
    }
  } finally {
    db.dispose();
  }
}
