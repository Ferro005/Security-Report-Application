import 'dart:async';
import '../db/database_helper.dart';
import '../utils/secure_logger.dart';

class AuditoriaService {
  static const _defaultRetentionDays = 90;

  static Future<void> registar({
    int? userId,
    required String acao,
    String? detalhe,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('auditoria', {
      'ts': DateTime.now().toIso8601String(),
      'user_id': userId,
      'acao': acao,
      'detalhe': detalhe,
    });
  }

  /// Limpar registos de auditoria antigos (mais de X dias)
  /// Configuração padrão: 90 dias
  /// SECURITY: Preserva integridade do histórico de auditoria
  static Future<int> cleanOldAudits({
    int retentionDays = _defaultRetentionDays,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Calcular data limite (90 dias atrás)
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .toIso8601String();

      // Contar registos que serão deletados (para log)
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM auditoria WHERE ts < ?',
        [cutoffDate],
      );
      
      final deletedCount = (countResult.isNotEmpty 
          ? countResult.first['count'] as int? ?? 0 
          : 0);

      if (deletedCount == 0) {
        SecureLogger.info('Nenhum registo de auditoria antigo para limpar');
        return 0;
      }

      // Registar a limpeza ANTES de deletar
      await registar(
        acao: 'auditoria_cleanup',
        detalhe: 'Limpeza automática: $deletedCount registos deletados (com mais de $retentionDays dias)',
      );

      // Deletar registos antigos
      await db.delete(
        'auditoria',
        where: 'ts < ?',
        whereArgs: [cutoffDate],
      );

      SecureLogger.audit(
        'auditoria_cleanup_completed',
        'Limpeza de auditoria concluída: $deletedCount registos deletados',
      );

      return deletedCount;
    } catch (e) {
      SecureLogger.error('Erro ao limpar auditoria', e);
      return 0;
    }
  }

  /// Obter registos de auditoria com filtros
  static Future<List<Map<String, dynamic>>> getAudits({
    int? userId,
    String? acao,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      String where = '';
      final whereArgs = <dynamic>[];

      if (userId != null) {
        where += 'user_id = ?';
        whereArgs.add(userId);
      }

      if (acao != null) {
        if (where.isNotEmpty) where += ' AND ';
        where += 'acao = ?';
        whereArgs.add(acao);
      }

      final audits = await db.query(
        'auditoria',
        where: where.isEmpty ? null : where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'ts DESC',
        limit: limit,
        offset: offset,
      );

      return audits;
    } catch (e) {
      SecureLogger.error('Erro ao obter registos de auditoria', e);
      return [];
    }
  }

  /// Obter estatísticas de auditoria
  static Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Total de registos
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM auditoria'
      );
      final totalCount = (totalResult.isNotEmpty 
          ? totalResult.first['count'] as int? ?? 0 
          : 0);

      // Últimos 24 horas
      final last24hResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM auditoria WHERE ts > datetime("now", "-1 day")'
      );
      final last24hCount = (last24hResult.isNotEmpty 
          ? last24hResult.first['count'] as int? ?? 0 
          : 0);

      // Ações mais comuns
      final topActionsResult = await db.rawQuery(
        'SELECT acao, COUNT(*) as count FROM auditoria GROUP BY acao ORDER BY count DESC LIMIT 5'
      );

      return {
        'total_records': totalCount,
        'last_24h_records': last24hCount,
        'top_actions': topActionsResult,
      };
    } catch (e) {
      SecureLogger.error('Erro ao obter estatísticas de auditoria', e);
      return {
        'total_records': 0,
        'last_24h_records': 0,
        'top_actions': [],
      };
    }
  }

  /// Iniciar limpeza automática periódica (executar uma vez no startup)
  /// Agenda limpeza para executar semanalmente
  static Future<void> startAutoCleanup({
    int cleanupIntervalHours = 168, // 1 semana
  }) async {
    try {
      // Primeira limpeza imediata
      await cleanOldAudits();

      // Agendar limpeza periódica usando Timer
      // Nota: Em ambiente de produção, usar um job scheduler mais robusto
      SecureLogger.info(
        'Limpeza automática de auditoria agendada a cada $cleanupIntervalHours horas (${(cleanupIntervalHours / 24).toStringAsFixed(1)} dias)'
      );

      Timer.periodic(Duration(hours: cleanupIntervalHours), (_) async {
        try {
          await cleanOldAudits();
        } catch (e) {
          SecureLogger.error('Erro na limpeza periódica de auditoria', e);
        }
      });
    } catch (e) {
      SecureLogger.error('Erro ao iniciar limpeza automática', e);
    }
  }
}

