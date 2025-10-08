import '../db/database_helper.dart';

class DetalhesService {
  static Future<void> adicionarComentario({
    required int incidenteId,
    required int usuarioId,
    required String comentario,
  }) async {
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
