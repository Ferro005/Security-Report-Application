import '../db/database_helper.dart';
import '../utils/secure_logger.dart';

/// Tipos de notificações de segurança
enum NotificationType {
  login,                    // Login bem-sucedido
  failedLogin,             // Tentativa de login falhada
  passwordChanged,         // Senha alterada
  passwordExpired,         // Senha expirou
  accountLocked,           // Conta bloqueada
  permissionChanged,       // Permissões alteradas
  suspiciousActivity,      // Atividade suspeita
  sessionExpired,          // Sessão expirou
}

/// Serviço de Notificações de Segurança
/// Registra eventos de segurança importantes para o usuário
class NotificationsService {
  /// Criar notificação de segurança
  static Future<bool> createNotification(
    int userId,
    NotificationType type,
    String title,
    String message,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('notifications', {
        'user_id': userId,
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'read': 0,
        'created_at': now,
      });

      SecureLogger.audit(
        'notification_created',
        'Notificação criada: $title para usuário $userId',
        userId: userId,
      );

      return true;
    } catch (e) {
      SecureLogger.error('Erro ao criar notificação', e);
      return false;
    }
  }

  /// Marcar notificação como lida
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        'notifications',
        {'read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      return true;
    } catch (e) {
      SecureLogger.error('Erro ao marcar notificação como lida', e);
      return false;
    }
  }

  /// Marcar todas as notificações de um usuário como lidas
  static Future<int> markAllAsRead(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final count = await db.update(
        'notifications',
        {'read': 1},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      SecureLogger.audit(
        'notifications_marked_read',
        'Marcadas $count notificações como lidas para usuário $userId',
        userId: userId,
      );

      return count;
    } catch (e) {
      SecureLogger.error('Erro ao marcar notificações como lidas', e);
      return 0;
    }
  }

  /// Obter notificações não lidas do usuário
  static Future<List<Map<String, dynamic>>> getUnreadNotifications(
    int userId,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final notifications = await db.query(
        'notifications',
        where: 'user_id = ? AND read = ?',
        whereArgs: [userId, 0],
        orderBy: 'created_at DESC',
      );

      return notifications;
    } catch (e) {
      SecureLogger.error('Erro ao obter notificações não lidas', e);
      return [];
    }
  }

  /// Obter todas as notificações do usuário (com limite)
  static Future<List<Map<String, dynamic>>> getNotifications(
    int userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final notifications = await db.query(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return notifications;
    } catch (e) {
      SecureLogger.error('Erro ao obter notificações', e);
      return [];
    }
  }

  /// Contar notificações não lidas
  static Future<int> countUnreadNotifications(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND read = ?',
        [userId, 0],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }

      return 0;
    } catch (e) {
      SecureLogger.error('Erro ao contar notificações não lidas', e);
      return 0;
    }
  }

  /// Deletar notificação
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      return true;
    } catch (e) {
      SecureLogger.error('Erro ao deletar notificação', e);
      return false;
    }
  }

  /// Deletar todas as notificações de um usuário
  static Future<int> deleteAllNotifications(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final count = await db.delete(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      SecureLogger.audit(
        'notifications_deleted_all',
        'Deletadas $count notificações do usuário $userId',
        userId: userId,
      );

      return count;
    } catch (e) {
      SecureLogger.error('Erro ao deletar notificações', e);
      return 0;
    }
  }

  /// Deletar notificações antigas (mais de X dias)
  static Future<int> deleteOldNotifications({
    int olderThanDays = 30,
    int? userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: olderThanDays))
          .millisecondsSinceEpoch;

      String where = 'created_at < ?';
      List<dynamic> whereArgs = [cutoffTime];

      if (userId != null) {
        where += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      final count = await db.delete(
        'notifications',
        where: where,
        whereArgs: whereArgs,
      );

      SecureLogger.audit(
        'old_notifications_deleted',
        'Deletadas $count notificações com mais de $olderThanDays dias',
      );

      return count;
    } catch (e) {
      SecureLogger.error('Erro ao deletar notificações antigas', e);
      return 0;
    }
  }

  /// Notificar evento de login bem-sucedido
  static Future<void> notifyLogin(int userId, String email) async {
    await createNotification(
      userId,
      NotificationType.login,
      'Login bem-sucedido',
      'Você fez login em ${DateTime.now().toString()}',
    );
  }

  /// Notificar tentativa de login falhada
  static Future<void> notifyFailedLogin(int userId, String reason) async {
    await createNotification(
      userId,
      NotificationType.failedLogin,
      'Tentativa de login falhada',
      reason,
    );
  }

  /// Notificar mudança de senha
  static Future<void> notifyPasswordChanged(int userId) async {
    await createNotification(
      userId,
      NotificationType.passwordChanged,
      'Senha alterada',
      'Sua senha foi alterada com sucesso. Próxima expiração em 90 dias.',
    );
  }

  /// Notificar expiração de senha
  static Future<void> notifyPasswordExpired(int userId) async {
    await createNotification(
      userId,
      NotificationType.passwordExpired,
      'Senha expirada',
      'Sua senha expirou. Por favor, altere-a para continuar.',
    );
  }

  /// Notificar senha prestes a expirar
  static Future<void> notifyPasswordExpiringSoon(
    int userId,
    int daysRemaining,
  ) async {
    await createNotification(
      userId,
      NotificationType.passwordExpired,
      'Senha expira em breve',
      'Sua senha expira em $daysRemaining dias. Recomenda-se alterar logo.',
    );
  }

  /// Notificar conta bloqueada
  static Future<void> notifyAccountLocked(int userId) async {
    await createNotification(
      userId,
      NotificationType.accountLocked,
      'Conta bloqueada',
      'Sua conta foi bloqueada após múltiplas tentativas de login falhadas. Tente novamente em 30 segundos.',
    );
  }

  /// Notificar mudança de permissões
  static Future<void> notifyPermissionChanged(
    int userId,
    String permissionType,
    String action,
  ) async {
    await createNotification(
      userId,
      NotificationType.permissionChanged,
      'Permissões alteradas',
      'Suas permissões foram $action: $permissionType',
    );
  }

  /// Notificar atividade suspeita
  static Future<void> notifySuspiciousActivity(
    int userId,
    String description,
  ) async {
    await createNotification(
      userId,
      NotificationType.suspiciousActivity,
      'Atividade suspeita detectada',
      description,
    );
  }

  /// Notificar sessão expirada
  static Future<void> notifySessionExpired(int userId) async {
    await createNotification(
      userId,
      NotificationType.sessionExpired,
      'Sessão expirada',
      'Sua sessão expirou. Por favor, faça login novamente.',
    );
  }
}
