import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('🔄 Iniciando migração de Password Expiration...\n');

  // Auto-detect database location
  final possiblePaths = [
    path.join(Platform.environment['USERPROFILE']!, 'OneDrive', 'Documentos', 'gestao_incidentes.db'),
    path.join(Platform.environment['USERPROFILE']!, 'Documents', 'gestao_incidentes.db'),
    path.join(Platform.environment['HOME'] ?? '', 'Documents', 'gestao_incidentes.db'),
  ];

  String? dbPath;
  for (final p in possiblePaths) {
    if (File(p).existsSync()) {
      dbPath = p;
      break;
    }
  }

  if (dbPath == null) {
    print('❌ Base de dados não encontrada!');
    exit(1);
  }

  print('📂 Base de dados: $dbPath\n');

  final db = await databaseFactory.openDatabase(dbPath);

  try {
    print('🔐 Adicionando colunas de expiração de password...');
    
    // Adicionar colunas de password expiration se não existirem
    final columns = await db.rawQuery("PRAGMA table_info('usuarios')");
    final columnNames = columns.map((col) => col['name'] as String).toList();

    if (!columnNames.contains('password_changed_at')) {
      await db.execute(
        'ALTER TABLE usuarios ADD COLUMN password_changed_at INTEGER DEFAULT 0'
      );
      print('   ✓ Coluna password_changed_at adicionada');
    } else {
      print('   ⏭️  Coluna password_changed_at já existe');
    }

    if (!columnNames.contains('password_expires_at')) {
      await db.execute(
        'ALTER TABLE usuarios ADD COLUMN password_expires_at INTEGER DEFAULT 0'
      );
      print('   ✓ Coluna password_expires_at adicionada');
    } else {
      print('   ⏭️  Coluna password_expires_at já existe');
    }

    print('\n📋 Criando tabela password_history...');
    
    // Criar tabela de histórico de senhas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS password_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');
    print('   ✓ Tabela password_history criada com sucesso\n');

    // Criar índice para melhor performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_password_history_user_id 
      ON password_history(user_id)
    ''');
    print('   ✓ Índice idx_password_history_user_id criado\n');

    print('📋 Criando tabela notifications...');
    
    // Criar tabela de notificações de segurança
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');
    print('   ✓ Tabela notifications criada com sucesso\n');

    // Criar índices para notificações
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
      ON notifications(user_id)
    ''');
    print('   ✓ Índice idx_notifications_user_id criado\n');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_user_unread 
      ON notifications(user_id, read)
    ''');
    print('   ✓ Índice idx_notifications_user_unread criado\n');

    // Atualizar senha_changed_at para todos os usuários existentes
    print('📝 Atualizando timestamps de usuários existentes...');
    
    final users = await db.query('usuarios');
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = DateTime.now().add(Duration(days: 90)).millisecondsSinceEpoch;

    for (final user in users) {
      await db.update(
        'usuarios',
        {
          'password_changed_at': now,
          'password_expires_at': expiresAt,
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );
    }
    print('   ✓ ${users.length} usuário(s) atualizado(s)\n');

    print('✅ Migração concluída com sucesso!');
    print('\n📊 Resumo das mudanças:');
    print('   • Coluna: password_changed_at (INTEGER)');
    print('   • Coluna: password_expires_at (INTEGER)');
    print('   • Tabela: password_history');
    print('   • Tabela: notifications');
    print('   • Índices: 3 criados para performance');
    print('\n⚙️  Configuração de expiração:');
    print('   • Duração: 90 dias');
    print('   • Verificação: A cada login');
    print('   • Aviso: Antes de expirar');

  } catch (e) {
    print('❌ Erro durante a migração: $e');
    exit(1);
  } finally {
    await db.close();
  }
}

