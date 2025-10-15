import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  try {
    // Get all users with full details
    final users = db.select('''
      SELECT id, nome, email, senha, hash, tipo, 
             failed_attempts, last_failed_at, locked_until 
      FROM usuarios 
      ORDER BY id
    ''');

    print('═══════════════════════════════════════════════════════════');
    print('UTILIZADORES NA BASE DE DADOS');
    print('═══════════════════════════════════════════════════════════\n');
    print('Total: ${users.length} utilizadores\n');

    for (final user in users) {
      final id = user['id'];
      final nome = user['nome']?.toString() ?? '<null>';
      final email = user['email']?.toString() ?? '<null>';
      final senha = user['senha']?.toString() ?? '<null>';
      final hash = user['hash']?.toString() ?? '<null>';
      final tipo = user['tipo']?.toString() ?? '<null>';
      final failed = user['failed_attempts'] ?? 0;
      final lastFailed = user['last_failed_at'];
      final locked = user['locked_until'];

      print('─────────────────────────────────────────────────────────');
      print('ID: $id');
      print('Nome: $nome');
      print('Email: $email');
      print('Tipo: $tipo');
      print('Tentativas falhadas: $failed');
      if (lastFailed != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(lastFailed as int);
        print('Última falha: $date');
      }
      if (locked != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(locked as int);
        print('Bloqueado até: $date');
      }
      print('Senha (coluna antiga): ${senha.length > 40 ? senha.substring(0, 40) + "..." : senha}');
      print('Hash (bcrypt): ${hash.length > 40 ? hash.substring(0, 40) + "..." : hash}');
      
      // Test password Admin1234 if hash exists
      if (hash != '<null>' && hash.startsWith(r'$2')) {
        try {
          final matchesAdmin = BCrypt.checkpw('Admin1234', hash);
          print('Senha "Admin1234": ${matchesAdmin ? "✓ VÁLIDA" : "✗ Inválida"}');
        } catch (e) {
          print('Erro ao testar senha: $e');
        }
      }
      print('');
    }

    print('═══════════════════════════════════════════════════════════');
  } finally {
    db.dispose();
  }
}
