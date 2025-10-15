import 'package:bcrypt/bcrypt.dart';
import '../db/database_helper.dart';
import '../models/user.dart';

class AuthService {
  /// Cria hash seguro para nova password
  static String hashPassword(String senha, {int rounds = 12}) {
    try {
        // BCrypt.gensalt() não aceita parâmetros na versão atual
        final salt = BCrypt.gensalt();
        return BCrypt.hashpw(senha, salt);
    } catch (e) {
        throw Exception('Erro ao gerar hash da senha: $e');
    }
}

  /// Verifica login com proteção de lockout
  static Future<User?> login(String email, String senha) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final user = User.fromMap(rows.first);

    final now = DateTime.now().millisecondsSinceEpoch;

    // bloqueio: se locked_until ainda está no futuro
    if (user.lockedUntil != null && user.lockedUntil! > now) {
      throw Exception(
          'A conta está temporariamente bloqueada. Tente mais tarde.');
    }

    final ok = BCrypt.checkpw(senha, user.hash);
    if (!ok) {
      // incrementa tentativas falhadas
      final fails = (user.failedAttempts ?? 0) + 1;

      int? lockedUntil;
      if (fails >= 5) {
        // bloqueia por 30 segundos
        lockedUntil = DateTime.now()
            .add(const Duration(seconds: 30))
            .millisecondsSinceEpoch;
      }

      await db.update(
        'usuarios',
        {
          'failed_attempts': fails,
          'last_failed_at': now,
          'locked_until': lockedUntil,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return null;
    }

    // login OK → reset contadores
    await db.update(
      'usuarios',
      {
        'failed_attempts': 0,
        'last_failed_at': null,
        'locked_until': null,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );

    return user;
  }
}
