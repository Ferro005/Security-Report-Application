
import '../db/database_helper.dart';
import '../models/incidente.dart';
import '../utils/secure_logger.dart';

class IncidentesService {
  /// 📋 Lista todos os incidentes ordenados por data
  static Future<List<Incidente>> listar() async {
    final db = await DatabaseHelper.instance.database;

    // Garante que a tabela existe
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incidentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        descricao TEXT,
        categoria TEXT,
        status TEXT,
        grau_risco TEXT,
        data_reportado TEXT,
        tecnico_responsavel INTEGER,
        usuario_id INTEGER
      );
    ''');

    // Nota: lógica de migração removida. Utilizar apenas o esquema atual.

    final rows = await db.query('incidentes', orderBy: 'datetime(data_reportado) DESC');

    SecureLogger.debug('incidentes_list_count: ${rows.length}');
    return rows.map((e) => Incidente.fromMap(e)).toList();
  }

  /// ➕ Cria novo incidente
  static Future<bool> criar(Map<String, dynamic> data) async {
    try {
      final db = await DatabaseHelper.instance.database;
      // Garantir que a tabela existe (caso o utilizador salte o dashboard)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS incidentes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          descricao TEXT,
          categoria TEXT,
          status TEXT,
          grau_risco TEXT,
          data_reportado TEXT,
          tecnico_responsavel INTEGER,
          usuario_id INTEGER
        );
      ''');
      final id = await db.insert('incidentes', data);
      SecureLogger.database('insert', table: 'incidentes', affectedRows: 1);
      return id > 0;
    } catch (e, st) {
      SecureLogger.error('Failed to create incidente', e, st);
      return false;
    }
  }

  /// ✏️ Atualiza incidente existente
  static Future<bool> atualizar(int id, Map<String, dynamic> data) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.update('incidentes', data, where: 'id = ?', whereArgs: [id]);
      SecureLogger.database('update', table: 'incidentes', affectedRows: res);
      return res > 0;
    } catch (e, st) {
      SecureLogger.error('Failed to update incidente', e, st);
      return false;
    }
  }

  /// ❌ Apaga incidente
  static Future<bool> apagar(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.delete('incidentes', where: 'id = ?', whereArgs: [id]);
      SecureLogger.database('delete', table: 'incidentes', affectedRows: res);
      return res > 0;
    } catch (e, st) {
      SecureLogger.error('Failed to delete incidente', e, st);
      return false;
    }
  }
}
