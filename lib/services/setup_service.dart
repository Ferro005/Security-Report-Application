import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:argon2/argon2.dart';
import '../db/database_helper.dart';
import '../utils/secure_logger.dart';

/// SetupService garante que o schema existe e cria um admin por omissão
class SetupService {
  static const _defaultAdminEmail = 'admin@exemplo.com';
  static const _defaultAdminName = 'Admin';
  static const _defaultPassword = 'Senha@123456';

  /// Executa as tarefas de primeira execução
  static Future<void> initialize() async {
    final db = await DatabaseHelper.instance.database;

    // Criar tabelas principais se não existirem
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        hash TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'user',
        password_changed_at INTEGER,
        password_expires_at INTEGER,
        failed_attempts INTEGER DEFAULT 0,
        last_failed_at INTEGER,
        locked_until INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS incidentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        descricao TEXT,
        categoria TEXT,
        status TEXT,
        grau_risco TEXT,
        data_reportado TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS auditoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT NOT NULL,
        user_id INTEGER,
        acao TEXT NOT NULL,
        detalhe TEXT,
        FOREIGN KEY (user_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS password_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT,
        message TEXT,
        read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    ''');

    // Verificar se existem utilizadores
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM usuarios');
    final count = (res.isNotEmpty ? res.first['c'] as int? : 0) ?? 0;

    if (count == 0) {
      // Criar admin por omissão
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 90));
      final hash = await _hashArgon2(_defaultPassword);

      await db.insert('usuarios', {
        'nome': _defaultAdminName,
        'email': _defaultAdminEmail,
        'hash': hash,
        'tipo': 'admin',
        'password_changed_at': now.millisecondsSinceEpoch,
        'password_expires_at': expiresAt.millisecondsSinceEpoch,
        'failed_attempts': 0,
        'last_failed_at': null,
        'locked_until': null,
      });

      SecureLogger.audit(
        'seed_admin_created',
        'Admin criado na primeira execução: $_defaultAdminEmail',
      );
    }
  }

  static Future<String> _hashArgon2(String senha) async {
    // Salt único de 16 bytes
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < saltBytes.length; i++) {
      saltBytes[i] = random.nextInt(256);
    }

    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      saltBytes,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      memory: 65536,
      lanes: 4,
    );

    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);

    final passwordBytes = utf8.encode(senha);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);

    return '\$argon2id\$${base64.encode(saltBytes)}\$${base64.encode(result)}';
  }
}
