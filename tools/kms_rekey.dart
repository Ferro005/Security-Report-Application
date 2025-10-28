import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

/// Ferramenta de rotação de chave (rekey) para a base de dados SQLCipher.
/// - Abre a base de dados runtime usando a chave atual (lida pelo app)
/// - Executa PRAGMA rekey = '<nova_chave>'
/// - Gera backup antes de aplicar
///
/// OBS: Este script não lê a chave do app/secure storage. Você deve informar
/// explicitamente a chave atual e a nova via variáveis de ambiente ou flags.
/// Uso (exemplo):
///   dart run tools/kms_rekey.dart --current <chave_atual> --next <nova_chave>
///   # ou usando envs: KMS_CURRENT=... KMS_NEXT=... dart run tools/kms_rekey.dart
void main(List<String> args) async {
  String? current = _readArg(args, '--current') ?? Platform.environment['KMS_CURRENT'];
  String? next = _readArg(args, '--next') ?? Platform.environment['KMS_NEXT'];
  final force = args.contains('--force');

  if (current == null || current.isEmpty || next == null || next.isEmpty) {
    stderr.writeln('Erro: informe --current <chave_atual> e --next <nova_chave>');
    exit(2);
  }

  // Resolve caminho da DB runtime alinhado com o app (Windows: %USERPROFILE%/Documents)
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  final runtimePath = p.join(userProfile, 'Documents', 'gestao_incidentes.db');

  if (!File(runtimePath).existsSync()) {
    stderr.writeln('DB não encontrada em: $runtimePath');
    exit(1);
  }

  if (!force) {
    stdout.writeln('Esta operação irá recriptografar a DB com nova chave. Continuar? (s/N)');
    final r = stdin.readLineSync()?.toLowerCase();
    if (r != 's' && r != 'sim') {
      stdout.writeln('Operação cancelada.');
      exit(0);
    }
  }

  try {
    // Backup
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '$runtimePath.backup.$timestamp';
    File(runtimePath).copySync(backupPath);
    stdout.writeln('Backup criado: $backupPath');

    // Inicializa FFI
    sqfliteFfiInit();
    final databaseFactoryWithCipher = createDatabaseFactoryFfi(ffiInit: sqfliteFfiInit);
    databaseFactory = databaseFactoryWithCipher;

    // Abre com a chave atual, aplica rekey e fecha
    final db = await databaseFactory.openDatabase(
      runtimePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute("PRAGMA key = '$current';");
        },
      ),
    );

    await db.execute("PRAGMA rekey = '$next';");
    await db.close();

    stdout.writeln('Rekey aplicado com sucesso. Guarde a nova chave com segurança.');
  } catch (e, st) {
    stderr.writeln('Falha ao aplicar rekey: $e');
    stderr.writeln(st);
    exit(1);
  }
}

String? _readArg(List<String> args, String key) {
  final i = args.indexOf(key);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}
