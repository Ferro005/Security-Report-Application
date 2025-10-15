import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:argon2/argon2.dart';

/// Script para popular a base de dados com 6 usuários específicos
/// ATENÇÃO: Este script apaga TODOS os usuários existentes!
void main() async {
  print('🔄 Iniciando população da base de dados...\n');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Caminho para a base de dados
  // Tentar múltiplos caminhos possíveis
  final possiblePaths = [
    join(Platform.environment['USERPROFILE'] ?? '', 'OneDrive', 'Documentos', 'gestao_incidentes.db'),
    join(Platform.environment['USERPROFILE'] ?? '', 'Documents', 'gestao_incidentes.db'),
    join(Platform.environment['HOME'] ?? '', 'Documents', 'gestao_incidentes.db'),
  ];

  String? dbPath;
  for (var path in possiblePaths) {
    if (File(path).existsSync()) {
      dbPath = path;
      break;
    }
  }

  if (dbPath == null) {
    print('❌ Base de dados não encontrada!');
    print('   Locais verificados:');
    for (var path in possiblePaths) {
      print('   - $path');
    }
    print('\n   Execute a aplicação primeiro para criar a DB.');
    exit(1);
  }

  print('📂 Base de dados: $dbPath');

  final db = await openDatabase(dbPath);

  try {
    // 1. LIMPAR usuários existentes
    print('\n🗑️  Removendo usuários existentes...');
    final deleted = await db.delete('usuarios');
    print('   ✓ $deleted usuário(s) removido(s)');

    // 2. Senha padrão para todos (atende requisitos de segurança)
    const senhaComum = 'Senha@123456'; // 12 chars, maiúscula, minúscula, número, especial

    // 3. Criar hash Argon2id para a senha
    print('\n🔐 Gerando hash Argon2id...');
    
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,  // Argon2id
      utf8.encode('somesalt'),
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      memory: 65536,  // 64 MB
      lanes: 4,
    );
    
    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    
    final passwordBytes = utf8.encode(senhaComum);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    
    final senhaHash = base64.encode(result);
    print('   ✓ Hash gerado');

    // 4. Definir usuários
    final usuarios = [
      {
        'nome': 'Henrique',
        'email': 'henrique@exemplo.com',
        'senha': senhaHash,
        'tipo': 'admin',
      },
      {
        'nome': 'Leonardo',
        'email': 'leonardo@exemplo.com',
        'senha': senhaHash,
        'tipo': 'user',
      },
      {
        'nome': 'Gonçalo',
        'email': 'goncalo@exemplo.com',
        'senha': senhaHash,
        'tipo': 'tecnico',
      },
      {
        'nome': 'Duarte',
        'email': 'duarte@exemplo.com',
        'senha': senhaHash,
        'tipo': 'tecnico',
      },
      {
        'nome': 'Francisco',
        'email': 'francisco@exemplo.com',
        'senha': senhaHash,
        'tipo': 'user',
      },
      {
        'nome': 'Admin',
        'email': 'admin@exemplo.com',
        'senha': senhaHash,
        'tipo': 'admin',
      },
    ];

    // 5. Inserir usuários
    print('\n👥 Criando usuários...\n');
    for (var user in usuarios) {
      await db.insert('usuarios', user);
      print('   ✓ ${user['nome']} (${user['tipo']}) - ${user['email']}');
    }

    // 6. Verificar inserção
    print('\n📊 Verificando usuários criados:\n');
    final queryResult = await db.query('usuarios', orderBy: 'tipo, nome');
    
    print('╔════════════════════════════════════════════════════════════╗');
    print('║  ID │ Nome          │ Email                  │ Tipo      ║');
    print('╠════════════════════════════════════════════════════════════╣');
    
    for (var row in queryResult) {
      final id = row['id'].toString().padRight(3);
      final nome = row['nome'].toString().padRight(13);
      final email = row['email'].toString().padRight(22);
      final tipo = row['tipo'].toString().padRight(9);
      print('║  $id │ $nome │ $email │ $tipo ║');
    }
    
    print('╚════════════════════════════════════════════════════════════╝');

    print('\n✅ População concluída com sucesso!');
    print('\n📝 Detalhes:');
    print('   • Total de usuários: ${queryResult.length}');
    print('   • Administradores: ${queryResult.where((u) => u['tipo'] == 'admin').length}');
    print('   • Técnicos: ${queryResult.where((u) => u['tipo'] == 'tecnico').length}');
    print('   • Usuários normais: ${queryResult.where((u) => u['tipo'] == 'user').length}');
    print('\n🔑 Senha padrão para TODOS os usuários: $senhaComum');
    print('   (Mínimo 12 caracteres, maiúscula, minúscula, número, especial)');
    print('\n⚠️  IMPORTANTE: Altere as senhas após o primeiro login!');

  } catch (e) {
    print('\n❌ Erro ao popular base de dados: $e');
    exit(1);
  } finally {
    await db.close();
  }
}
