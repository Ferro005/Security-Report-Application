import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:bcrypt/bcrypt.dart';

void main(List<String> args) {
  // Runtime DB path used by the app as observed in logs
  final dbPath = r'C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db';
  if (!File(dbPath).existsSync()) {
    print('Runtime DB not found at: $dbPath');
    return;
  }

  // Optional admin password passed as first arg, otherwise we'll not overwrite unknowns
  final adminPassword = args.isNotEmpty ? args[0] : null;

  final db = sqlite3.open(dbPath);
  try {
    // get columns
    final cols = db.select("PRAGMA table_info('usuarios')").map((r) => r['name']?.toString() ?? '').toList();
    print('Existing columns: ${cols.join(', ')}');

    final hasHash = cols.contains('hash');

    final hasFailed = cols.contains('failed_attempts');
    final hasLastFailed = cols.contains('last_failed_at');
    final hasLocked = cols.contains('locked_until');

    db.execute('BEGIN TRANSACTION');

    if (!hasHash) {
      print('Adding column: hash');
      db.execute("ALTER TABLE usuarios ADD COLUMN hash TEXT; ");
    }
    if (!hasFailed) {
      print('Adding column: failed_attempts');
      db.execute("ALTER TABLE usuarios ADD COLUMN failed_attempts INTEGER DEFAULT 0;");
    }
    if (!hasLastFailed) {
      print('Adding column: last_failed_at');
      db.execute("ALTER TABLE usuarios ADD COLUMN last_failed_at INTEGER;");
    }
    if (!hasLocked) {
      print('Adding column: locked_until');
      db.execute("ALTER TABLE usuarios ADD COLUMN locked_until INTEGER;");
    }

    // For rows where hash is null/empty, try to populate from senha (if present) or use adminPassword for admin@exemplo.com
    final users = db.select('SELECT id, email, senha, hash FROM usuarios');
    for (final row in users) {
      final id = row['id'];
      final email = row['email']?.toString() ?? '';
      final senha = row['senha']?.toString();
      final hash = row['hash']?.toString();

      if ((hash == null || hash.isEmpty)) {
        if (senha != null && senha.isNotEmpty) {
          print('Hashing existing senha for user $email (id=$id)');
          final h = BCrypt.hashpw(senha, BCrypt.gensalt());
          db.execute('UPDATE usuarios SET hash = ? WHERE id = ?', [h, id]);
        } else if (email == 'admin@exemplo.com' && adminPassword != null) {
          print('Setting admin password for $email');
          final h = BCrypt.hashpw(adminPassword, BCrypt.gensalt());
          db.execute('UPDATE usuarios SET hash = ? WHERE id = ?', [h, id]);
        } else {
          print('No senha available for $email (id=$id) — leaving hash empty; consider resetting password manually');
        }
      }
    }

    db.execute('COMMIT');
    print('Migration completed.');

    // Print final schema and a couple of users
    final finalCols = db.select("PRAGMA table_info('usuarios')").map((r) => r['name']?.toString() ?? '').toList();
    print('Final columns: ${finalCols.join(', ')}');
    final sample = db.select("SELECT id, email, hash IS NOT NULL AS has_hash, failed_attempts FROM usuarios");
    for (final r in sample) {
      print('${r['id']} | ${r['email']} | has_hash=${r['has_hash']} | failed=${r['failed_attempts']}');
    }
  } catch (e) {
    print('Migration failed: $e');
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
  } finally {
    db.dispose();
  }
}
