/// Script de migração de hashes BCrypt para Argon2
/// 
/// ATENÇÃO: Este script requer que você saiba as senhas dos usuários
/// ou force um reset de senha para todos.
/// 
/// Opção 1: Migração automática no próximo login (RECOMENDADO)
/// - O AuthService já faz isso automaticamente
/// - Usuários com BCrypt serão migrados ao fazer login
/// 
/// Opção 2: Força reset de senha para todos
/// - Use este script para marcar todos usuários para reset

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  print('=== Migração de Hashes BCrypt para Argon2 ===\n');
  
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;
  
  // Localizar database
  final dir = await path_provider.getApplicationDocumentsDirectory();
  final dbPath = join(dir.path, 'gestao_incidentes.db');
  
  if (!File(dbPath).existsSync()) {
    print('❌ Database não encontrada em: $dbPath');
    print('Execute a aplicação primeiro para criar a database.');
    exit(1);
  }
  
  print('📂 Database: $dbPath\n');
  
  final db = await databaseFactory.openDatabase(dbPath);
  
  // Contar usuários com BCrypt
  final bcryptUsers = await db.rawQuery(
    "SELECT COUNT(*) as count FROM usuarios WHERE hash LIKE '\$2%'"
  );
  final bcryptCount = bcryptUsers.first['count'] as int;
  
  // Contar usuários com Argon2
  final argon2Users = await db.rawQuery(
    "SELECT COUNT(*) as count FROM usuarios WHERE hash LIKE '\$argon2%'"
  );
  final argon2Count = argon2Users.first['count'] as int;
  
  print('📊 Status Atual:');
  print('   - Usuários com BCrypt: $bcryptCount');
  print('   - Usuários com Argon2: $argon2Count');
  print('');
  
  if (bcryptCount == 0) {
    print('✅ Todos os usuários já usam Argon2!');
    await db.close();
    exit(0);
  }
  
  print('ℹ️  OPÇÕES DE MIGRAÇÃO:\n');
  print('1. Migração Automática (RECOMENDADO)');
  print('   - Os usuários serão migrados automaticamente no próximo login');
  print('   - Não requer ação adicional');
  print('   - Já está implementado no AuthService\n');
  
  print('2. Forçar Reset de Senha');
  print('   - Adiciona flag require_password_reset para todos usuários BCrypt');
  print('   - Usuários terão que redefinir senha no próximo login');
  print('   - Mais seguro se há suspeita de comprometimento\n');
  
  stdout.write('Escolha uma opção (1 ou 2, Enter para cancelar): ');
  final choice = stdin.readLineSync();
  
  if (choice == '1') {
    print('\n✅ Migração automática já está ativa!');
    print('   Quando os usuários fizerem login, seus hashes serão atualizados.');
  } else if (choice == '2') {
    print('\n⚠️  Forçando reset de senha para $bcryptCount usuários...');
    
    // Verificar se coluna existe
    final columns = await db.rawQuery("PRAGMA table_info('usuarios')");
    final hasResetColumn = columns.any((col) => col['name'] == 'require_password_reset');
    
    if (!hasResetColumn) {
      print('   Adicionando coluna require_password_reset...');
      await db.execute(
        'ALTER TABLE usuarios ADD COLUMN require_password_reset INTEGER DEFAULT 0'
      );
    }
    
    // Marcar usuários BCrypt para reset
    final updated = await db.rawUpdate(
      "UPDATE usuarios SET require_password_reset = 1 WHERE hash LIKE '\$2%'"
    );
    
    print('   ✅ $updated usuários marcados para reset de senha');
    print('   ℹ️  Implemente verificação de require_password_reset na tela de login');
  } else {
    print('\n❌ Operação cancelada.');
  }
  
  await db.close();
  
  print('\n📝 PRÓXIMOS PASSOS:');
  print('   1. Teste o login de um usuário BCrypt');
  print('   2. Verifique logs para confirmar migração');
  print('   3. Monitore progresso da migração gradual');
  print('   4. Após 100% Argon2, considere remover suporte a BCrypt\n');
}
