
import '../db/database_helper.dart';

class TecnicosService {
  /// 📜 Lista todos os técnicos
  static Future<List<Map<String, dynamic>>> listar() async {
    final db = await DatabaseHelper.instance.database;
  // Garantir tabela base
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tecnicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL UNIQUE
      );
    ''');
    return await db.query('tecnicos', orderBy: 'id ASC');
  }

  /// 🔍 Pesquisa técnicos por nome
  static Future<List<Map<String, dynamic>>> pesquisar(String termo) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'tecnicos',
      where: 'nome LIKE ?',
      whereArgs: ['%$termo%'],
      orderBy: 'nome ASC',
    );
  }

  /// ➕ Adiciona um novo técnico
  static Future<void> adicionar(String nome) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('tecnicos', {'nome': nome});
  }

  /// ✏️ Atualiza um técnico existente
  static Future<void> atualizar(int id, String nome) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tecnicos', {'nome': nome}, where: 'id = ?', whereArgs: [id]);
  }

  /// ❌ Apaga um técnico
  static Future<void> apagar(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tecnicos', where: 'id = ?', whereArgs: [id]);
  }
}
