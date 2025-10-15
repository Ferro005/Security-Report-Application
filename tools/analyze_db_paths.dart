import 'dart:io';

void main() {
  print('═══════════════════════════════════════════════════════════');
  print('ANÁLISE DE CAMINHOS DE BASE DE DADOS NOS SCRIPTS');
  print('═══════════════════════════════════════════════════════════\n');
  
  final scripts = {
    'auto_migrate.dart': 'Runtime (migração)',
    'check_passwords.dart': 'Empacotada',
    'compare_dbs.dart': 'Ambas (comparação)',
    'find_password.dart': 'Empacotada',
    'fix_hash.dart': 'Empacotada',
    'inspect_db.dart': 'Empacotada',
    'inspect_target_db.dart': 'Ambas (comparação)',
    'list_users.dart': 'Empacotada',
    'migrate_db.dart': 'Runtime (migração)',
    'sync_db.dart': 'Runtime → Empacotada (sincronização)',
    'test_bcrypt.dart': 'N/A (teste de BCrypt)',
    'verify_admin_password.dart': 'Empacotada',
  };
  
  print('SCRIPTS QUE USAM DB EMPACOTADA (assets/db/):');
  print('────────────────────────────────────────────');
  scripts.forEach((script, db) {
    if (db.contains('Empacotada') && !db.contains('Ambas')) {
      print('✓ $script');
    }
  });
  
  print('\nSCRIPTS QUE USAM DB RUNTIME (Documentos):');
  print('────────────────────────────────────────────');
  scripts.forEach((script, db) {
    if (db.contains('Runtime') && !db.contains('→')) {
      print('⚙️  $script');
    }
  });
  
  print('\nSCRIPTS QUE USAM AMBAS:');
  print('────────────────────────────────────────────');
  scripts.forEach((script, db) {
    if (db.contains('Ambas') || db.contains('→')) {
      print('↔️  $script - $db');
    }
  });
  
  print('\nOUTROS:');
  print('────────────────────────────────────────────');
  scripts.forEach((script, db) {
    if (db == 'N/A (teste de BCrypt)') {
      print('🧪 $script - $db');
    }
  });
  
  print('\n═══════════════════════════════════════════════════════════');
  print('RESUMO:');
  print('═══════════════════════════════════════════════════════════');
  print('📦 DB Empacotada: Para consultar/verificar utilizadores no repo');
  print('🔄 DB Runtime: Para migrações e modificações em uso');
  print('↔️  Ambas: Para comparar ou sincronizar entre as duas');
  print('═══════════════════════════════════════════════════════════\n');
}
