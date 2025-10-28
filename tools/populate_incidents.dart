// DEPRECATED: Dev-only population script (not used by the application at runtime).
// This script assumes a legacy OneDrive path. Prefer using the app with
// DatabaseHelper which resolves a safe path under %USERPROFILE%\Documents.
// Kept for reference and local development only.

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

  print('📊 Criando incidentes de teste...\n');

  final db = sqlite3.open(dbPath);

  try {
    // Get technician IDs
    final tecnicos = db.select("SELECT id FROM usuarios WHERE tipo = 'tecnico'");
    final adminId = db.select("SELECT id FROM usuarios WHERE tipo = 'admin'").first['id'];

    if (tecnicos.isEmpty) {
      print('❌ Nenhum técnico encontrado na base de dados');
      exit(1);
    }

    final incidentesData = [
      {
        'numero': 'INC-001',
        'descricao': 'Sistema de autenticação lento durante picos de acesso',
        'categoria': 'TI',
        'status': 'Em andamento',
        'risco': 'Médio',
      },
      {
        'numero': 'INC-002',
        'descricao': 'Falha na sincronização de dados entre servidores',
        'categoria': 'Infraestrutura',
        'status': 'Em Análise',
        'risco': 'Alto',
      },
      {
        'numero': 'INC-003',
        'descricao': 'Problema de compatibilidade com novos drivers de impressora',
        'categoria': 'TI',
        'status': 'Resolvido',
        'risco': 'Baixo',
      },
      {
        'numero': 'INC-004',
        'descricao': 'Queda de energia afetou o data center principal',
        'categoria': 'Infraestrutura',
        'status': 'Resolvido',
        'risco': 'Crítico',
      },
      {
        'numero': 'INC-005',
        'descricao': 'Reclamação de funcionário sobre acesso a benefícios',
        'categoria': 'RH',
        'status': 'Pendente',
        'risco': 'Baixo',
      },
      {
        'numero': 'INC-006',
        'descricao': 'Vazamento de dados sensíveis em servidor compartilhado',
        'categoria': 'TI',
        'status': 'Em Análise',
        'risco': 'Crítico',
      },
      {
        'numero': 'INC-007',
        'descricao': 'Atraso na entrega de equipamentos para novo departamento',
        'categoria': 'Infraestrutura',
        'status': 'Em andamento',
        'risco': 'Médio',
      },
      {
        'numero': 'INC-008',
        'descricao': 'Problema de conectividade WiFi em zona de reuniões',
        'categoria': 'TI',
        'status': 'Cancelado',
        'risco': 'Baixo',
      },
      {
        'numero': 'INC-009',
        'descricao': 'Falha no backup automático de arquivos críticos',
        'categoria': 'Infraestrutura',
        'status': 'Em andamento',
        'risco': 'Alto',
      },
      {
        'numero': 'INC-010',
        'descricao': 'Requisição de nova licença de software educacional',
        'categoria': 'RH',
        'status': 'Pendente',
        'risco': 'Baixo',
      },
    ];

    print('📝 Inserindo ${incidentesData.length} incidentes de teste:\n');

    for (var i = 0; i < incidentesData.length; i++) {
      final incident = incidentesData[i];
      final tecnicoId = tecnicos[i % tecnicos.length]['id'];

      db.execute(
        '''INSERT INTO incidentes 
           (numero, descricao, categoria, status, grau_risco, user_id, tecnico_id, data_ocorrencia)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          incident['numero'],
          incident['descricao'],
          incident['categoria'],
          incident['status'],
          incident['risco'],
          adminId,
          tecnicoId,
          DateTime.now().toIso8601String(),
        ],
      );

      print('✅ ${incident['numero']}: ${incident['descricao']}');
      print('   Status: ${incident['status']} | Risco: ${incident['risco']} | Categoria: ${incident['categoria']}\n');
    }

    print('='*60);

    // Verify insertion
    final count = db.select('SELECT COUNT(*) as count FROM incidentes');
    final total = count.isNotEmpty ? count.first['count'] : 0;

    print('\n✨ Sucesso!');
    print('   Total de incidentes: $total');
    print('\n📊 Agora você pode:');
    print('   1. Abrir a aplicação');
    print('   2. Ver os incidentes no dashboard');
    print('   3. Clicar em "📊 Ver Estatísticas" para ver os gráficos');

  } catch (e) {
    print('❌ Erro ao criar incidentes: $e');
  } finally {
    db.dispose();
  }

  exit(0);
}
