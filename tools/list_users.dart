import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as path;

void main() {
  // Usar caminho relativo para a base de dados
  final dbPath = path.join(Directory.current.path, 'assets', 'db', 'gestao_incidentes.db');
  
  if (!File(dbPath).existsSync()) {
    print('Base de dados não encontrada em: $dbPath');
    return;
  }

  final db = sqlite3.open(dbPath);
  try {
    // Check which columns exist in the usuarios table
    final schema = db.select("PRAGMA table_info('usuarios')");
    final columns = schema.map((r) => r['name']?.toString() ?? '').toSet();
    final hasSenha = columns.contains('senha');
    
    // Build query based on available columns
    final selectCols = [
      'id', 'nome', 'email',
      if (hasSenha) 'senha',
      'hash', 'tipo',
      if (columns.contains('failed_attempts')) 'failed_attempts',
      if (columns.contains('last_failed_at')) 'last_failed_at',
      if (columns.contains('locked_until')) 'locked_until',
    ];
    
    // Get all users with full details
    final users = db.select('''
      SELECT ${selectCols.join(', ')}
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
      final senha = hasSenha ? (user['senha']?.toString() ?? '<null>') : '<não existe>';
      final hash = user['hash']?.toString() ?? '<null>';
      final tipo = user['tipo']?.toString() ?? '<null>';
      final failed = columns.contains('failed_attempts') ? (user['failed_attempts'] ?? 0) : 0;
      final lastFailed = columns.contains('last_failed_at') ? user['last_failed_at'] : null;
      final locked = columns.contains('locked_until') ? user['locked_until'] : null;

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
      if (hasSenha) {
        print('Senha (coluna antiga): ${senha.length > 40 ? senha.substring(0, 40) + "..." : senha}');
      }
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
