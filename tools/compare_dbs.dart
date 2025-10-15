import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as path;

void compareDBs() {
  // DB empacotada (assets)
  final packagedPath = path.join(Directory.current.path, 'assets', 'db', 'gestao_incidentes.db');
  
  // DB runtime (documentos)
  final runtimePath = path.join(
    Platform.environment['USERPROFILE'] ?? '',
    'OneDrive',
    'Documentos',
    'gestao_incidentes.db'
  );

  print('═══════════════════════════════════════════════════════════');
  print('COMPARAÇÃO DE BASES DE DADOS');
  print('═══════════════════════════════════════════════════════════\n');

  void showUsers(String label, String dbPath) {
    if (!File(dbPath).existsSync()) {
      print('$label: Não encontrada em $dbPath\n');
      return;
    }

    final db = sqlite3.open(dbPath);
    try {
      final users = db.select('SELECT id, nome, email, hash FROM usuarios ORDER BY id');
      print('$label ($dbPath)');
      print('Total: ${users.length} utilizadores\n');
      
      for (final user in users) {
        final id = user['id'];
        final nome = user['nome']?.toString() ?? '';
        final email = user['email']?.toString() ?? '';
        final hash = user['hash']?.toString() ?? '';
        
        var passwordStatus = '?';
        if (hash.startsWith(r'$2')) {
          try {
            passwordStatus = BCrypt.checkpw('Admin1234', hash) ? '✓ Admin1234' : '✗';
          } catch (e) {
            passwordStatus = '✗ erro';
          }
        }
        
        print('  [$id] $nome ($email) - $passwordStatus');
      }
      print('');
    } finally {
      db.dispose();
    }
  }

  showUsers('DB EMPACOTADA (assets)', packagedPath);
  showUsers('DB RUNTIME (documentos)', runtimePath);
  
  print('═══════════════════════════════════════════════════════════');
}

void main() {
  compareDBs();
}
