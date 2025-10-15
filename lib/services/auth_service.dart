import 'dart:async';
import 'package:bcrypt/bcrypt.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import 'auditoria_service.dart';

class AuthService {
  /// Gera hash seguro para nova password (com sal e custo configurável)
  static String hashPassword(String senha, {int rounds = 12}) {
    final salt = BCrypt.gensalt(rounds);
    return BCrypt.hashpw(senha, salt);
  }

  /// Tenta login com bloqueio temporário e logs de auditoria
  static Future<User?> login(String email, String senha) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (rows.isEmpty) {
      await AuditoriaService.registar(
        acao: 'login_erro',
        detalhe: 'Email não existente: $email',
      );
      await Future.delayed(const Duration(milliseconds: 200)); // anti-timing
      return null;
    }

    final user = User.fromMap(rows.first);

    // bloqueado?
    if (user.lockedUntil != null && user.lockedUntil! > now) {
      throw Exception('Conta bloqueada. Tente novamente dentro de 30 segundos.');
    }

    final ok = BCrypt.checkpw(senha, user.hash);

    if (!ok) {
      final fails = (user.failedAttempts ?? 0) + 1;

      int? lockedUntil;
      if (fails >= 5) {
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

      await AuditoriaService.registar(
        acao: 'login_erro',
        userId: user.id,
        detalhe: 'Senha incorreta (tentativa $fails)',
      );

      await Future.delayed(const Duration(milliseconds: 200));
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

    await AuditoriaService.registar(
      acao: 'login_sucesso',
      userId: user.id,
    );

    return user;
  }
}
