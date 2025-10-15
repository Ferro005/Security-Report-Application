# Sincronização da Base de Dados

Este projeto mantém uma base de dados empacotada em `assets/db/gestao_incidentes.db` que é usada como template inicial quando a aplicação é executada pela primeira vez.

## 🔄 Sincronização Automática (Modo Debug)

Quando a aplicação está em modo **debug**, a base de dados é automaticamente sincronizada com `assets/db/` sempre que:

- ✅ Um novo utilizador é criado via `AuthService.criarUsuario()`

A sincronização automática **NÃO** funciona em builds de release (por segurança).

### Mensagem no Console

Quando a sincronização ocorre, verá:
```
✓ Base de dados sincronizada com assets/db/
  Lembrete: Faça commit e push das alterações!
```

## 🛠️ Sincronização Manual

Para sincronizar manualmente a base de dados runtime com assets:

### Opção 1: Script Interativo
```bash
dart run tools/sync_db.dart
```

O script irá:
1. ✅ Criar um backup da DB atual em assets
2. ✅ Copiar a DB runtime para assets
3. ✅ Verificar alterações no Git
4. ✅ Sugerir os próximos comandos Git

### Opção 2: Script Forçado (sem confirmação)
```bash
dart run tools/sync_db.dart --force
```

## 📋 Workflow Recomendado

### Quando criar novos utilizadores:

1. **Criar utilizador** na aplicação (modo debug)
2. **Verificar sincronização** no console
3. **Commit e push**:
   ```bash
   git add assets/db/gestao_incidentes.db
   git commit -m "update: add new user to database"
   git push origin main
   ```

### Quando fazer alterações manuais na DB:

1. **Fazer alterações** na DB runtime (em `C:\Users\...\OneDrive\Documentos\gestao_incidentes.db`)
2. **Sincronizar**:
   ```bash
   dart run tools/sync_db.dart
   ```
3. **Seguir instruções** exibidas pelo script

## 🔍 Verificar Utilizadores

### Listar utilizadores na DB empacotada:
```bash
dart run tools/list_users.dart
```

### Comparar DB empacotada vs runtime:
```bash
dart run tools/compare_dbs.dart
```

## ⚠️ Avisos Importantes

- ⚠️ A sincronização **sobrescreve** a DB empacotada
- ⚠️ Sempre faça **backup** antes de sincronizar manualmente
- ⚠️ A sincronização automática **só funciona em modo debug**
- ⚠️ Não esqueça de fazer **commit e push** após sincronizar

## 📂 Localizações

| Base de Dados | Caminho |
|---------------|---------|
| **Empacotada** (template) | `assets/db/gestao_incidentes.db` |
| **Runtime** (em uso) | `C:\Users\[user]\OneDrive\Documentos\gestao_incidentes.db` |

## 🧰 Ferramentas Disponíveis

- `sync_db.dart` - Sincroniza runtime → assets
- `list_users.dart` - Lista utilizadores na DB empacotada
- `compare_dbs.dart` - Compara empacotada vs runtime
- `auto_migrate.dart` - Migra schema automaticamente
- `check_passwords.dart` - Verifica passwords dos utilizadores

---

**Nota:** A base de dados empacotada é versionada no Git e deve ser mantida atualizada para que novas instalações tenham os utilizadores corretos.
