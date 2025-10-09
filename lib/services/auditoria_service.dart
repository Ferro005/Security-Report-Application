import '../db/database_helper.dart';

class AuditoriaService {
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
}
