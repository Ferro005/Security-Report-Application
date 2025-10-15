import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:argon2/argon2.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('🔄 Iniciando população da base de dados...\n');

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
    // Use first path and create parent directory
    dbPath = possiblePaths.first;
    await Directory(path.dirname(dbPath)).create(recursive: true);
  }

  print('📂 Base de dados: $dbPath\n');

  final db = await databaseFactory.openDatabase(dbPath);

  // Remove existing users
  print('🗑️  Removendo usuários existentes...');
  final deleted = await db.delete('usuarios');
  print('   ✓ $deleted usuário(s) removido(s)\n');

  // Generate Argon2id hash for default password
  print('🔐 Gerando hash Argon2id...');
  final password = 'Senha@123456';
  
  final parameters = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    utf8.encode('somesalt'),
    version: Argon2Parameters.ARGON2_VERSION_13,
    iterations: 3,
    memory: 65536,
    lanes: 4,
  );

  final argon2 = Argon2BytesGenerator();
  argon2.init(parameters);

  final passwordBytes = utf8.encode(password);
  final result = Uint8List(32);
  argon2.generateBytes(passwordBytes, result, 0, result.length);

  final hash = '\$argon2id\$${base64.encode(result)}';
  
  print('   ✓ Hash gerado\n');

  // Create users
  print('👥 Criando usuários...');
  
  final users = [
    {'nome': 'Henrique', 'email': 'henrique@exemplo.com', 'tipo': 'admin'},
    {'nome': 'Leonardo', 'email': 'leonardo@exemplo.com', 'tipo': 'user'},
    {'nome': 'Gonçalo', 'email': 'goncalo@exemplo.com', 'tipo': 'tecnico'},
    {'nome': 'Duarte', 'email': 'duarte@exemplo.com', 'tipo': 'tecnico'},
    {'nome': 'Francisco', 'email': 'francisco@exemplo.com', 'tipo': 'user'},
    {'nome': 'Admin', 'email': 'admin@exemplo.com', 'tipo': 'admin'},
  ];

  for (final user in users) {
    await db.insert('usuarios', {
      'nome': user['nome'],
      'email': user['email'],
      'senha': hash,
      'tipo': user['tipo'],
    });
    print('   ✓ ${user['nome']} (${user['tipo']}) - ${user['email']}');
  }

  // Display created users
  print('\n📊 Utilizadores criados:\n');
  final allUsers = await db.query('usuarios', orderBy: 'id ASC');
  
  print('╔════╤═══════════════╤════════════════════════╤═══════════╗');
  print('║ ID │ Nome          │ Email                  │ Tipo      ║');
  print('╠════╪═══════════════╪════════════════════════╪═══════════╣');
  
  for (final user in allUsers) {
    final id = user['id'].toString().padLeft(3);
    final nome = (user['nome'] as String).padRight(13);
    final email = (user['email'] as String).padRight(22);
    final tipo = (user['tipo'] as String).padRight(9);
    print('║ $id │ $nome │ $email │ $tipo ║');
  }
  
  print('╚════╧═══════════════╧════════════════════════╧═══════════╝');

  // Statistics
  final stats = <String, int>{};
  for (final user in allUsers) {
    final tipo = user['tipo'] as String;
    stats[tipo] = (stats[tipo] ?? 0) + 1;
  }

  print('\n✅ População concluída com sucesso!');
  print('\n📝 Detalhes:');
  print('   • Total de usuários: ${allUsers.length}');
  print('   • Administradores: ${stats['admin'] ?? 0}');
  print('   • Técnicos: ${stats['tecnico'] ?? 0}');
  print('   • Usuários normais: ${stats['user'] ?? 0}');
  print('\n🔐 Password padrão: $password');
  print('\n⚠️  Lembre-se de copiar esta DB para assets/db/ se necessário!');

  await db.close();
}
