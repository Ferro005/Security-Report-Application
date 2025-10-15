import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }

  // Common test passwords to check
  final testPasswords = [
    'Admin1234',
    'admin1234',
    '123456',
    'password',
    'admin',
    'Admin123',
    '12345678',
    'senha123',
    'Senha123',
  ];

  final db = sqlite3.open(dbPath);
  try {
    final admin = db.select("SELECT id, email, hash FROM usuarios WHERE email = 'admin@exemplo.com' LIMIT 1");
    if (admin.isEmpty) {
      print('Admin user not found');
      return;
    }

    final hash = admin.first['hash']?.toString() ?? '';
    print('Testing passwords for admin@exemplo.com...\n');
    
    for (final pwd in testPasswords) {
      try {
        final matches = BCrypt.checkpw(pwd, hash);
        if (matches) {
          print('✓ FOUND! Password is: "$pwd"');
          return;
        } else {
          print('✗ Not: $pwd');
        }
      } catch (e) {
        print('✗ Error testing $pwd: $e');
      }
    }
    
    print('\nNone of the common passwords matched.');
    print('Hash: $hash');
  } finally {
    db.dispose();
  }
}
