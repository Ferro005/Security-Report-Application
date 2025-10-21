import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import '../db/database_helper.dart';
import '../utils/secure_logger.dart';
import '../utils/input_sanitizer.dart';
import 'auditoria_service.dart';

/// Serviço de política de senhas com:
/// - Expiração de senha (90 dias)
/// - Histórico de senhas (previne reutilização das últimas 5)
/// - Validação de força de senha
class PasswordPolicyService {
  static const _passwordExpirationDays = 90;
  static const _passwordHistoryLimit = 5;

  /// Verificar se a senha do usuário expirou
  static Future<bool> isPasswordExpired(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'usuarios',
        columns: ['password_expires_at'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return false;

      final expiresAt = result.first['password_expires_at'] as int?;
      if (expiresAt == null || expiresAt == 0) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now > expiresAt;

      if (isExpired) {
        SecureLogger.warning('Senha expirada para usuário $userId');
        await AuditoriaService.registar(
          acao: 'password_expired',
          userId: userId,
          detalhe: 'Senha expirada - requer renovação',
        );
      }

      return isExpired;
    } catch (e) {
      SecureLogger.error('Erro ao verificar expiração de senha', e);
      return false;
    }
  }

  /// Obter dias restantes até a expiração da senha
  static Future<int> getDaysUntilExpiration(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'usuarios',
        columns: ['password_expires_at'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return 0;

      final expiresAt = result.first['password_expires_at'] as int?;
      if (expiresAt == null || expiresAt == 0) return 0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = expiresAt - now;

      if (diff < 0) return 0;

      return (diff / (1000 * 60 * 60 * 24)).ceil();
    } catch (e) {
      SecureLogger.error('Erro ao calcular dias até expiração', e);
      return 0;
    }
  }

  /// Verificar se a senha foi utilizada recentemente
  /// Previne reutilização das últimas 5 senhas
  static Future<bool> isPasswordReused(int userId, String newPassword) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Obter histórico de senhas (últimas 5)
      final history = await db.query(
        'password_history',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: _passwordHistoryLimit,
      );

      // Verificar se a nova senha corresponde a alguma do histórico
      for (final entry in history) {
        final oldHash = entry['password_hash'] as String;
        
        // Verificar se a nova senha gera o mesmo hash (compatibilidade)
        if (await _verifyPasswordAgainstHash(newPassword, oldHash)) {
          SecureLogger.warning(
            'Tentativa de reutilizar senha anterior para usuário $userId'
          );
          await AuditoriaService.registar(
            acao: 'password_reuse_attempted',
            userId: userId,
            detalhe: 'Tentativa de reutilizar uma senha anterior',
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      SecureLogger.error('Erro ao verificar reutilização de senha', e);
      return false;
    }
  }

  /// Mudar senha com histórico
  /// Registra a senha antiga no histórico e atualiza as datas de expiração
  static Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
    String oldHash,
  ) async {
    try {
      // Validar força da nova senha
      if (!InputSanitizer.isStrongPassword(newPassword)) {
        throw Exception(
          'Senha fraca. Deve ter no mínimo 8 caracteres com maiúsculas, minúsculas e números.'
        );
      }

      // Verificar se é reutilização
      if (await isPasswordReused(userId, newPassword)) {
        throw Exception(
          'Não pode reutilizar uma das últimas $_passwordHistoryLimit senhas.'
        );
      }

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now()
          .add(Duration(days: _passwordExpirationDays))
          .millisecondsSinceEpoch;

      // Adicionar senha atual ao histórico ANTES de mudar
      await db.insert('password_history', {
        'user_id': userId,
        'password_hash': oldHash,
        'created_at': now,
      });

      // Gerar novo hash
      final newHash = await _hashPassword(newPassword);

      // Atualizar senha e datas
      await db.update(
        'usuarios',
        {
          'hash': newHash,
          'password_changed_at': now,
          'password_expires_at': expiresAt,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      SecureLogger.audit(
        'password_changed',
        'Senha alterada para usuário $userId',
        userId: userId,
      );

      await AuditoriaService.registar(
        acao: 'password_changed',
        userId: userId,
        detalhe: 'Senha alterada com sucesso (expiração em $_passwordExpirationDays dias)',
      );

      // Limpar histórico antigo (manter apenas as últimas _passwordHistoryLimit)
      final allHistory = await db.query(
        'password_history',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      if (allHistory.length > _passwordHistoryLimit) {
        final toDelete = allHistory
            .skip(_passwordHistoryLimit)
            .map((row) => row['id'] as int)
            .toList();

        for (final id in toDelete) {
          await db.delete(
            'password_history',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      return true;
    } catch (e) {
      SecureLogger.error('Erro ao mudar senha', e);
      throw Exception('Erro ao mudar senha: $e');
    }
  }

  /// Forçar expiração de senha (após login bem-sucedido)
  static Future<void> renewPasswordExpiration(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now()
          .add(Duration(days: _passwordExpirationDays))
          .millisecondsSinceEpoch;

      await db.update(
        'usuarios',
        {
          'password_changed_at': now,
          'password_expires_at': expiresAt,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      SecureLogger.audit(
        'password_expiration_renewed',
        'Expiração de senha renovada para usuário $userId',
        userId: userId,
      );
    } catch (e) {
      SecureLogger.error('Erro ao renovar expiração de senha', e);
    }
  }

  /// Gerar hash Argon2id com salt único
  static Future<String> _hashPassword(String senha) async {
    try {
      final random = Random.secure();
      final saltBytes = Uint8List(16);
      for (int i = 0; i < saltBytes.length; i++) {
        saltBytes[i] = random.nextInt(256);
      }

      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        saltBytes,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3,
        memory: 65536,
        lanes: 4,
      );

      final argon2 = Argon2BytesGenerator();
      argon2.init(parameters);

      final passwordBytes = utf8.encode(senha);
      final result = Uint8List(32);
      argon2.generateBytes(passwordBytes, result, 0, result.length);

      return '\$argon2id\$${base64.encode(saltBytes)}\$${base64.encode(result)}';
    } catch (e) {
      SecureLogger.error('Erro ao gerar hash de senha', e);
      throw Exception('Erro ao processar senha');
    }
  }

  /// Verificar senha contra hash (internal)
  static Future<bool> _verifyPasswordAgainstHash(
    String senha,
    String hash,
  ) async {
    try {
      if (hash.startsWith(r'$argon2')) {
        final parts = hash.split('\$');

        if (parts.length == 4) {
          final saltBytes = base64.decode(parts[2]);
          final storedHash = base64.decode(parts[3]);

          final parameters = Argon2Parameters(
            Argon2Parameters.ARGON2_id,
            saltBytes,
            version: Argon2Parameters.ARGON2_VERSION_13,
            iterations: 3,
            memory: 65536,
            lanes: 4,
          );

          final argon2 = Argon2BytesGenerator();
          argon2.init(parameters);

          final passwordBytes = utf8.encode(senha);
          final result = Uint8List(32);
          argon2.generateBytes(passwordBytes, result, 0, result.length);

          return _constantTimeCompare(result, storedHash);
        }
      }

      return false;
    } catch (e) {
      SecureLogger.error('Erro ao verificar hash de senha', e);
      return false;
    }
  }

  /// Comparação constant-time
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;

    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }

    return diff == 0;
  }

  /// Obter informações de expiração de senha
  static Future<Map<String, dynamic>?> getPasswordInfo(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'usuarios',
        columns: ['password_changed_at', 'password_expires_at'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final changedAt = result.first['password_changed_at'] as int? ?? 0;
      final expiresAt = result.first['password_expires_at'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final daysUntilExpiration = ((expiresAt - now) / (1000 * 60 * 60 * 24)).ceil();
      final isExpired = now > expiresAt;

      return {
        'password_changed_at': DateTime.fromMillisecondsSinceEpoch(changedAt),
        'password_expires_at': DateTime.fromMillisecondsSinceEpoch(expiresAt),
        'days_until_expiration': daysUntilExpiration,
        'is_expired': isExpired,
        'warning': daysUntilExpiration <= 7 && daysUntilExpiration > 0,
      };
    } catch (e) {
      SecureLogger.error('Erro ao obter informações de senha', e);
      return null;
    }
  }
}
