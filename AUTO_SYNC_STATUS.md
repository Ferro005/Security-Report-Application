# 🔄 Sincronização Automática de Utilizadores

## ✅ Estado Atual: ATIVADA

A sincronização automática da base de dados empacotada **está ATIVA** e funciona da seguinte forma:

## 🎯 Como Funciona

### Quando é Acionada
Sempre que um novo utilizador é criado via `AuthService.criarUsuario()`, a base de dados runtime é **automaticamente copiada** para `assets/db/gestao_incidentes.db`.

### Condições
- ✅ **Apenas em modo DEBUG** (não funciona em builds de release)
- ✅ Executado após inserção bem-sucedida do utilizador
- ✅ Executado após registo de auditoria

### Mensagem no Console
Quando a sincronização ocorre com sucesso, verás:
```
✓ Base de dados sincronizada com assets/db/
  Lembrete: Faça commit e push das alterações!
```

Se houver erro (ex: permissões), verás:
```
Aviso: Não foi possível sincronizar DB com assets: [erro]
```

## 📋 Workflow Recomendado

### 1. Criar Utilizador na Aplicação
```dart
await AuthService.criarUsuario('Nome', 'email@exemplo.com', 'senha123');
```

### 2. Verificar Console
A mensagem de sincronização deve aparecer automaticamente.

### 3. Commit e Push
```bash
git add assets/db/gestao_incidentes.db
git commit -m "update: add new user [nome]"
git push origin main
```

## 🔧 Código Implementado

### AuthService.criarUsuario()
```dart
// ... criar utilizador ...

await AuditoriaService.registar(
  acao: 'criar_usuario',
  detalhe: 'Novo usuário criado: $email'
);

// Sincronizar com assets DB (apenas em modo debug)
await DatabaseHelper.instance.syncToAssets();

return true;
```

### DatabaseHelper.syncToAssets()
```dart
Future<void> syncToAssets() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final runtimePath = join(dir.path, 'gestao_incidentes.db');
    
    // Only sync in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      final projectRoot = Directory.current.path;
      final assetsPath = join(projectRoot, 'assets', 'db', 'gestao_incidentes.db');
      
      if (File(runtimePath).existsSync()) {
        await File(runtimePath).copy(assetsPath);
        print('✓ Base de dados sincronizada com assets/db/');
        print('  Lembrete: Faça commit e push das alterações!');
      }
    }
  } catch (e) {
    print('Aviso: Não foi possível sincronizar DB com assets: $e');
  }
}
```

## ⚠️ Notas Importantes

1. **Modo Debug Apenas**: A sincronização só funciona quando a app está em modo debug
2. **Não Bloqueia**: Se a sincronização falhar, não impede a criação do utilizador
3. **Commit Manual**: Após criar utilizador, ainda precisas fazer commit/push manualmente
4. **Segurança**: Em builds de release, a sincronização nunca ocorre

## 🛠️ Alternativa Manual

Se preferires sincronizar manualmente:
```bash
dart run tools/sync_db.dart
```

## ✅ Verificar Utilizadores

Antes de fazer commit, verifica os utilizadores:
```bash
dart run tools/list_users.dart
```

---

**Estado**: ✅ ATIVADA  
**Última atualização**: 15 de Outubro de 2025
