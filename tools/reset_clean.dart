import 'dart:io';

void main() async {
  print('🗑️  Limpando banco de dados...\n');

  // Diretório de documentos do Windows
  final dir = Directory('${Platform.environment['USERPROFILE']}/Documents');
  final dbPath = '${dir.path}/gestao_incidentes.db';

  print('📂 Banco de dados: $dbPath');

  // Backup
  try {
    if (File(dbPath).existsSync()) {
      final backupPath = '$dbPath.bak.${DateTime.now().toIso8601String().replaceAll(':', '-')}';
      await File(dbPath).copy(backupPath);
      print('✅ Backup criado: $backupPath');
    }
  } catch (e) {
    print('⚠️  Erro ao fazer backup: $e');
  }

  try {
    // Deletar banco existente
    if (File(dbPath).existsSync()) {
      await File(dbPath).delete();
      print('✅ Banco antigo deletado');
    }

    print('\n✅ Banco resetado com sucesso!');
    print('📝 Ao abrir, a aplicação criará novo banco vazio');
    print('📝 Com apenas admin@exemplo.com / Senha@123456\n');

  } catch (e) {
    print('❌ Erro: $e');
    exit(1);
  }
}
