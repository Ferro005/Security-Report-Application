import '../db/database_helper.dart';
import '../utils/secure_logger.dart';

class DetalhesService {
  static Future<void> _ensureTables() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comentarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          incidente_id INTEGER NOT NULL,
          usuario_id INTEGER NOT NULL,
          comentario TEXT NOT NULL,
          data_comentario TEXT NOT NULL,
          FOREIGN KEY (incidente_id) REFERENCES incidentes(id) ON DELETE CASCADE,
          FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historico_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          incidente_id INTEGER NOT NULL,
          status TEXT NOT NULL,
          alterado_por INTEGER,
          data_alteracao TEXT NOT NULL,
          FOREIGN KEY (incidente_id) REFERENCES incidentes(id) ON DELETE CASCADE,
          FOREIGN KEY (alterado_por) REFERENCES usuarios(id) ON DELETE SET NULL
        );
      ''');
    } catch (e, st) {
      SecureLogger.error('Failed ensuring detalhes tables', e, st);
      rethrow;
    }
  }
  static Future<void> adicionarComentario({
    required int incidenteId,
    required int usuarioId,
    required String comentario,
  }) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    await db.insert('comentarios', {
      'incidente_id': incidenteId,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'data_comentario': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> atualizarStatus({
    required int incidenteId,
    required String novoStatus,
    required int alteradoPor,
  }) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'incidentes',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [incidenteId],
    );

    await db.insert('historico_status', {
      'incidente_id': incidenteId,
      'status': novoStatus,
      'alterado_por': alteradoPor,
      'data_alteracao': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> atualizarRisco({
    required int incidenteId,
    required String novoRisco,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'incidentes',
      {'grau_risco': novoRisco},
      where: 'id = ?',
      whereArgs: [incidenteId],
    );
  }

  static Future<List<Map<String, dynamic>>> listarComentarios(int incidenteId) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT c.*, u.nome AS autor
      FROM comentarios c
      JOIN usuarios u ON c.usuario_id = u.id
      WHERE c.incidente_id = ?
      ORDER BY datetime(c.data_comentario) DESC
    ''', [incidenteId]);
  }

  static Future<List<Map<String, dynamic>>> listarHistorico(int incidenteId) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT h.*, u.nome AS alterado_por_nome
      FROM historico_status h
      LEFT JOIN usuarios u ON h.alterado_por = u.id
      WHERE h.incidente_id = ?
      ORDER BY datetime(h.data_alteracao) DESC
    ''', [incidenteId]);
  }
}
