import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }

  // Backup first
  final backupPath = '$dbPath.bak.fix-hash-${DateTime.now().millisecondsSinceEpoch}';
  File(dbPath).copySync(backupPath);
  print('Backup created: $backupPath');

  final db = sqlite3.open(dbPath);
  try {
    db.execute('BEGIN TRANSACTION');
    
    // Copy the original bcrypt hash from 'senha' to 'hash' (senha already contains valid bcrypt)
    final users = db.select("SELECT id, email, senha FROM usuarios");
    for (final user in users) {
      final id = user['id'];
      final email = user['email'];
      final senha = user['senha']?.toString() ?? '';
      
      // If senha looks like a bcrypt hash (starts with $2), copy it directly to hash
      if (senha.startsWith(r'$2')) {
        print('Fixing hash for $email (copying senha -> hash)');
        db.execute('UPDATE usuarios SET hash = ? WHERE id = ?', [senha, id]);
      } else {
        print('Skipping $email (senha is not a bcrypt hash)');
      }
    }
    
    db.execute('COMMIT');
    print('\nFix applied successfully.');
    
    // Verify
    final verify = db.select("SELECT id, email, senha = hash AS is_same FROM usuarios");
    print('\nVerification:');
    for (final row in verify) {
      print('${row['email']}: senha == hash? ${row['is_same'] == 1}');
    }
  } catch (e) {
    print('Error: $e');
    try { db.execute('ROLLBACK'); } catch (_) {}
  } finally {
    db.dispose();
  }
}
