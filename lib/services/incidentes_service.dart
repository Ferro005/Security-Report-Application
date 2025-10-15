
import '../db/database_helper.dart';
import '../models/incidente.dart';

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
        data_reportado TEXT
      );
    ''');

    final rows = await db.query('incidentes', orderBy: 'datetime(data_reportado) DESC');

    print('🔍 ${rows.length} incidentes encontrados'); // debug
    return rows.map((e) => Incidente.fromMap(e)).toList();
  }

  /// ➕ Cria novo incidente
  static Future<bool> criar(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('incidentes', data);
    return id > 0;
  }

  /// ✏️ Atualiza incidente existente
  static Future<bool> atualizar(int id, Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.update('incidentes', data, where: 'id = ?', whereArgs: [id]);
    return res > 0;
  }

  /// ❌ Apaga incidente
  static Future<bool> apagar(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.delete('incidentes', where: 'id = ?', whereArgs: [id]);
    return res > 0;
  }
}
