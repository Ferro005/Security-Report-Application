import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  final dbPath = path.join(userProfile, 'OneDrive', 'Documentos', 'gestao_incidentes.db');

  if (!File(dbPath).existsSync()) {
    print('❌ Database não encontrado em: $dbPath');
    exit(1);
  }

  print('📊 Analisando base de dados...\n');
  print('📂 Localização: $dbPath\n');

  final db = sqlite3.open(dbPath);

  try {
    // List all tables
    print('📋 Tabelas na base de dados:');
    final tables = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    for (var table in tables) {
      final tableName = table['name']?.toString() ?? '';
      print('  • $tableName');
    }

    print('\n' + '='*60);

    // Count rows in each table
    print('\n📈 Dados por tabela:\n');

    // Check usuarios
    final usuariosCount = db.select('SELECT COUNT(*) as count FROM usuarios');
    final usuariosNum = usuariosCount.isNotEmpty ? usuariosCount.first['count'] : 0;
    print('👥 USUARIOS: $usuariosNum registros');
    if (usuariosNum > 0) {
      final usuarios = db.select('SELECT id, nome, email, tipo FROM usuarios ORDER BY id');
      for (var user in usuarios) {
        print('   - ${user['nome']} (${user['email']}) [${user['tipo']}]');
      }
    }

    // Check incidentes
    final incidentesCount = db.select('SELECT COUNT(*) as count FROM incidentes');
    final incidentesNum = incidentesCount.isNotEmpty ? incidentesCount.first['count'] : 0;
    print('\n📋 INCIDENTES: $incidentesNum registros');
    if (incidentesNum > 0) {
      final incidentes = db.select('SELECT id, numero, descricao, status, grau_risco FROM incidentes ORDER BY id');
      for (var incident in incidentes) {
        print('   - #${incident['numero']}: ${incident['descricao']} [${incident['status']}] - Risco: ${incident['grau_risco']}');
      }
    }

    // Check auditoria
    final auditoriaCount = db.select('SELECT COUNT(*) as count FROM auditoria');
    final auditoriaNum = auditoriaCount.isNotEmpty ? auditoriaCount.first['count'] : 0;
    print('\n🔍 AUDITORIA: $auditoriaNum registros');

    print('\n' + '='*60);
    print('\n✨ Resumo:');
    print('  Usuários: $usuariosNum');
    print('  Incidentes: $incidentesNum');
    print('  Logs de auditoria: $auditoriaNum');

    if (incidentesNum == 0) {
      print('\n⚠️  Nenhum relatório/incidente encontrado na base de dados.');
      print('    Use a aplicação para criar novos incidentes.');
    }

  } catch (e) {
    print('❌ Erro ao consultar database: $e');
  } finally {
    db.dispose();
  }

  exit(0);
}
