import 'dart:io';
import 'package:path/path.dart' as path;

/// Script para sincronizar a base de dados runtime de volta para assets
/// Use este script quando fizer alterações manuais na DB e quiser atualizar o repo
void main(List<String> args) {
  final projectRoot = Directory.current.path;
  
  // Caminho da DB runtime
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  // Alinha com o app: preferir %USERPROFILE%\Documents no Windows
  final runtimePath = path.join(userProfile, 'Documents', 'gestao_incidentes.db');
  
  // Caminho da DB empacotada
  final assetsPath = path.join(projectRoot, 'assets', 'db', 'gestao_incidentes.db');
  
  print('═══════════════════════════════════════════════════════════');
  print('SINCRONIZAR BASE DE DADOS RUNTIME → ASSETS');
  print('═══════════════════════════════════════════════════════════\n');
  
  print('Runtime DB: $runtimePath');
  print('Assets DB:  $assetsPath\n');
  
  // Verificar se runtime DB existe
  if (!File(runtimePath).existsSync()) {
    print('❌ ERRO: Base de dados runtime não encontrada!');
    print('   Caminho: $runtimePath');
    exit(1);
  }
  
  // Verificar se assets DB existe
  if (!File(assetsPath).existsSync()) {
    print('⚠️  AVISO: Base de dados assets não existe ainda.');
  }
  
  // Confirmar ação se não houver flag --force
  if (!args.contains('--force')) {
    print('⚠️  Esta ação irá SOBRESCREVER a base de dados empacotada!');
    print('   Tem certeza? (s/N): ');
    final response = stdin.readLineSync()?.toLowerCase();
    if (response != 's' && response != 'sim') {
      print('\n❌ Operação cancelada.');
      exit(0);
    }
  }
  
  try {
    // Criar backup da DB assets se ela existir
    if (File(assetsPath).existsSync()) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = '$assetsPath.backup.$timestamp';
      File(assetsPath).copySync(backupPath);
      print('\n✓ Backup criado: ${path.basename(backupPath)}');
    }
    
    // Copiar runtime → assets
    File(runtimePath).copySync(assetsPath);
    
    print('✓ Base de dados sincronizada com sucesso!\n');
    
    // Verificar diferenças com Git
    final gitStatus = Process.runSync('git', ['status', '--short', 'assets/db/gestao_incidentes.db']);
    if (gitStatus.exitCode == 0) {
      final output = gitStatus.stdout.toString().trim();
      if (output.isNotEmpty) {
        print('📝 Alterações detectadas no Git:');
        print('   $output\n');
        print('💡 Próximos passos:');
        print('   1. git add assets/db/gestao_incidentes.db');
        print('   2. git commit -m "update: sync users database"');
        print('   3. git push origin main');
      } else {
        print('ℹ️  Nenhuma alteração detectada (DB já está sincronizada)');
      }
    }
    
    print('\n═══════════════════════════════════════════════════════════');
    
  } catch (e) {
    print('\n❌ ERRO ao sincronizar: $e');
    exit(1);
  }
}
