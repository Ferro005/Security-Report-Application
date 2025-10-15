import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }
  
  final db = sqlite3.open(dbPath);
  try {
    final users = db.select("SELECT id, email, senha, hash FROM usuarios");
    print('Usuários encontrados: ${users.length}\n');
    for (final user in users) {
      final id = user['id'];
      final email = user['email'];
      final senha = user['senha']?.toString() ?? '<null>';
      final hash = user['hash']?.toString() ?? '<null>';
      final hashPreview = hash.length > 30 ? '${hash.substring(0, 30)}...' : hash;
      print('ID: $id');
      print('Email: $email');
      print('Senha (plaintext/original): $senha');
      print('Hash: $hashPreview');
      print('---');
    }
  } finally {
    db.dispose();
  }
}
