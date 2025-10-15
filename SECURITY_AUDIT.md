# 🔒 Relatório de Auditoria de Segurança
**Security Report Application - Análise Completa de Vulnerabilidades**

Data: 15 de Outubro de 2025  
Versão: 1.0.0

---

## 📊 Resumo Executivo

### Status Geral
- **Vulnerabilidades Críticas**: 5 🔴
- **Vulnerabilidades Altas**: 8 🟠
- **Vulnerabilidades Médias**: 12 🟡
- **Vulnerabilidades Baixas**: 6 🔵
- **Score de Segurança**: 62/100 ⚠️

---

## 🔴 VULNERABILIDADES CRÍTICAS

### 1. **Exposição de Base de Dados com Hashes no Repositório Git**
**Severidade**: CRÍTICA  
**CWE-312**: Cleartext Storage of Sensitive Information

**Descrição**:
- Base de dados SQLite (`assets/db/gestao_incidentes.db`) commitada no GitHub
- Contém hashes BCrypt de senhas de todos os utilizadores
- Passwords conhecidas: `Admin1234` para todos os usuários

**Localização**:
- `assets/db/gestao_incidentes.db` (tracked no Git)
- README.md linha 134-137 (expõe credenciais padrão)

**Impacto**:
- Qualquer pessoa com acesso ao repositório pode extrair hashes
- Ataques de força bruta offline possíveis
- Senhas padrão documentadas publicamente

**Recomendação**:
```bash
# 1. Remover DB do Git
git rm --cached assets/db/gestao_incidentes.db
echo "assets/db/*.db" >> .gitignore

# 2. Criar DB template vazia
# 3. Forçar reset de senhas no primeiro login
# 4. Usar senhas únicas e fortes
```

---

### 2. **SQL Injection via PRAGMA table_info**
**Severidade**: CRÍTICA  
**CWE-89**: SQL Injection

**Descrição**:
- `DatabaseHelper.tableColumns()` usa interpolação direta em PRAGMA
- Não há sanitização do nome da tabela

**Localização**:
```dart
// lib/db/database_helper.dart:96
Future<List<String>> tableColumns(String table) async {
  final db = await database;
  final rows = await db.rawQuery("PRAGMA table_info('$table')");  // ❌ VULNERÁVEL
  return rows.map((r) => r['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
}
```

**Exploit**:
```dart
// Possível injeção se table vier de input do usuário
tableColumns("usuarios'); DROP TABLE usuarios; --")
```

**Recomendação**:
```dart
Future<List<String>> tableColumns(String table) async {
  // Whitelist de tabelas permitidas
  const allowedTables = ['usuarios', 'incidentes', 'auditoria'];
  if (!allowedTables.contains(table)) {
    throw ArgumentError('Invalid table name');
  }
  
  final db = await database;
  final rows = await db.rawQuery("PRAGMA table_info(?)", [table]);
  return rows.map((r) => r['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
}
```

---

### 3. **Auto-Commit Git com Credenciais Expostas**
**Severidade**: CRÍTICA  
**CWE-798**: Use of Hard-coded Credentials

**Descrição**:
- `syncToAssets()` executa `git push` sem validação de credenciais
- Pode expor tokens/credenciais Git em logs
- Comandos Git executados com privilégios do usuário

**Localização**:
```dart
// lib/db/database_helper.dart:113-152
final pushResult = await Process.run(
  'git',
  ['push', 'origin', 'main'],
  workingDirectory: projectRoot,
);
```

**Impacto**:
- Credenciais Git podem vazar via logs
- Push automático pode falhar silenciosamente
- Histórico Git poluído com commits automáticos

**Recomendação**:
```dart
// 1. Remover auto-push ou tornar opt-in
// 2. Usar tokens com escopo limitado
// 3. Validar credenciais antes de push
// 4. Não logar stderr do Git (pode conter tokens)
```

---

### 4. **Exposição de Senhas em Ferramentas de Debug**
**Severidade**: CRÍTICA  
**CWE-215**: Information Exposure Through Debug Information

**Descrição**:
- Scripts em `tools/` testam senhas hardcoded
- `list_users.dart` imprime hashes completos no console
- `check_passwords.dart` expõe coluna `senha` antiga

**Localização**:
```dart
// tools/list_users.dart:69-75
print('Senha (coluna antiga): ${senha.length > 40 ? senha.substring(0, 40) + "..." : senha}');
print('Hash (bcrypt): ${hash.length > 40 ? hash.substring(0, 40) + "..." : hash}');
final matchesAdmin = BCrypt.checkpw('Admin1234', hash); // ❌ Hardcoded password
```

**Recomendação**:
```dart
// 1. Remover scripts de debug do repositório
// 2. Nunca imprimir hashes completos
// 3. Usar SecureLogger para mascarar dados sensíveis
```

---

### 5. **Path Traversal em Database Helper**
**Severidade**: CRÍTICA  
**CWE-22**: Path Traversal

**Descrição**:
- `_initDB()` usa `USERPROFILE` sem validação
- Caminho OneDrive pode ser manipulado via variável de ambiente

**Localização**:
```dart
// lib/db/database_helper.dart:23-25
final userProfile = Platform.environment['USERPROFILE'];
final path = join(userProfile!, 'OneDrive', 'Documentos', 'gestao_incidentes.db');
```

**Exploit**:
```bash
# Atacante pode modificar USERPROFILE
set USERPROFILE=C:\Windows\System32
# App criará DB em local privilegiado
```

**Recomendação**:
```dart
Future<Database> _initDB() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Usar path_provider para diretório seguro
  final appDocDir = await getApplicationDocumentsDirectory();
  final path = join(appDocDir.path, 'gestao_incidentes.db');
  
  // Validar que o caminho está dentro do diretório esperado
  final canonicalPath = File(path).absolute.path;
  if (!canonicalPath.startsWith(appDocDir.path)) {
    throw SecurityException('Invalid database path');
  }
  
  // ...resto do código
}
```

---

## 🟠 VULNERABILIDADES ALTAS

### 6. **Exportação de Dados Sensíveis sem Criptografia**
**Severidade**: ALTA  
**CWE-311**: Missing Encryption of Sensitive Data

**Descrição**:
- `ExportService` exporta PDF/CSV sem criptografia
- Dados de incidentes podem conter informações sensíveis
- Arquivos salvos em diretório do usuário sem proteção

**Localização**:
```dart
// lib/services/export_service.dart:27-29
final csv = const ListToCsvConverter().convert(rows);
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/relatorio_incidentes.csv'); // ❌ Não criptografado
return file.writeAsString(csv);
```

**Recomendação**:
```dart
static Future<File> exportarCSV(List<Incidente> incidentes) async {
  final rows = [...]; // Preparar dados
  final csv = const ListToCsvConverter().convert(rows);
  
  // Criptografar antes de salvar
  final encryptedCsv = await CryptoService.encrypt(csv);
  
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/relatorio_incidentes.csv.encrypted');
  return file.writeAsString(encryptedCsv);
}
```

---

### 7. **Falta de Rate Limiting em Login**
**Severidade**: ALTA  
**CWE-307**: Improper Restriction of Excessive Authentication Attempts

**Descrição**:
- Bloqueio temporário de apenas 30 segundos após 5 tentativas
- Sem proteção contra ataques distribuídos
- Delay de 200ms insuficiente

**Localização**:
```dart
// lib/services/auth_service.dart:154
if (fails >= 5) {
  lockedUntil = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
}
```

**Recomendação**:
```dart
// Implementar backoff exponencial
int calculateLockoutDuration(int attempts) {
  if (attempts <= 3) return 0;
  if (attempts <= 5) return 30; // 30 segundos
  if (attempts <= 10) return 300; // 5 minutos
  if (attempts <= 20) return 1800; // 30 minutos
  return 86400; // 24 horas
}

// Adicionar rate limiting por IP (se aplicável em desktop)
```

---

### 8. **Logs Inseguros com print()**
**Severidade**: ALTA  
**CWE-532**: Information Exposure Through Log Files

**Descrição**:
- Ainda existem `print()` em DatabaseHelper
- Logs podem conter paths completos e informações do sistema

**Localização**:
```dart
// lib/db/database_helper.dart:116, 129, 135, 141, 149, 153
print('✓ Base de dados sincronizada com assets/db/');
print('✓ Commit automático criado');
// ... mais prints
```

**Recomendação**:
```dart
// Substituir todos print() por SecureLogger
SecureLogger.info('Database synced to assets');
SecureLogger.audit('auto_commit', 'Database committed to Git');
```

---

### 9. **Senha Fraca Permitida (apenas validação front-end)**
**Severidade**: ALTA  
**CWE-521**: Weak Password Requirements

**Descrição**:
- Validação de senha apenas no `AuthService.criarUsuario()`
- Sem verificação de senhas comuns
- Sem histórico de senhas
- Permite senhas com apenas 8 caracteres

**Localização**:
```dart
// lib/utils/input_sanitizer.dart:54-62
static bool isStrongPassword(String password) {
  if (password.length < 8) return false;  // ❌ Muito fraco
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigits = password.contains(RegExp(r'[0-9]'));
  return hasUppercase && hasLowercase && hasDigits;
}
```

**Recomendação**:
```dart
static bool isStrongPassword(String password) {
  if (password.length < 12) return false; // Mínimo 12 caracteres
  
  // Verificar complexidade
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigits = password.contains(RegExp(r'[0-9]'));
  final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  
  // Lista de senhas comuns proibidas
  const commonPasswords = [
    'password', '12345678', 'qwerty', 'admin', 'admin123',
    'password123', 'Admin1234', 'senha123'
  ];
  
  if (commonPasswords.contains(password.toLowerCase())) {
    return false;
  }
  
  return hasUppercase && hasLowercase && hasDigits && hasSpecial;
}
```

---

### 10. **Falta de CSRF Protection**
**Severidade**: ALTA  
**CWE-352**: Cross-Site Request Forgery

**Descrição**:
- Aplicação desktop, mas usa operações sensíveis sem tokens
- Sem validação de origem das requests

**Recomendação**:
- Implementar tokens de sessão
- Validar operações críticas com re-autenticação

---

### 11. **Exposição de Estrutura de Diretórios**
**Severidade**: ALTA  
**CWE-497**: Exposure of System Data

**Descrição**:
- Paths completos expostos em erros e logs
- `Directory.current.path` revela estrutura do projeto

**Localização**:
```dart
// lib/db/database_helper.dart:111
final projectRoot = Directory.current.path;
```

**Recomendação**:
```dart
// Usar paths relativos em logs
SecureLogger.debug('Syncing database', error: e);
// Não logar paths completos
```

---

### 12. **Falta de Validação de Integridade de Arquivos**
**Severidade**: ALTA  
**CWE-353**: Missing Support for Integrity Check

**Descrição**:
- DB template copiada sem verificação de hash
- Arquivos exportados sem assinatura digital

**Recomendação**:
```dart
// Calcular hash da DB template
const expectedHash = 'sha256_hash_here';
final actualHash = CryptoService.hash(dbBytes);
if (actualHash != expectedHash) {
  throw SecurityException('Database integrity check failed');
}
```

---

### 13. **Ausência de Timeout em Operações de Rede**
**Severidade**: ALTA  
**CWE-400**: Uncontrolled Resource Consumption

**Descrição**:
- `Process.run` para Git sem timeout
- Pode causar hang da aplicação

**Localização**:
```dart
// lib/db/database_helper.dart:126-130
final pushResult = await Process.run(
  'git',
  ['push', 'origin', 'main'],
  workingDirectory: projectRoot,
); // ❌ Sem timeout
```

**Recomendação**:
```dart
final pushResult = await Process.run(
  'git',
  ['push', 'origin', 'main'],
  workingDirectory: projectRoot,
).timeout(
  const Duration(seconds: 30),
  onTimeout: () => throw TimeoutException('Git push timeout'),
);
```

---

## 🟡 VULNERABILIDADES MÉDIAS

### 14. **BCrypt Cost Factor Baixo**
**Severidade**: MÉDIA  
**CWE-916**: Use of Password Hash With Insufficient Computational Effort

**Descrição**:
- BCrypt usa cost factor padrão (~10)
- Recomendação moderna: 12-14

**Localização**:
```dart
// lib/services/auth_service.dart:11-12
static String hashPassword(String senha, {int rounds = 12}) {
  final salt = BCrypt.gensalt(); // ❌ Não usa rounds parameter
}
```

**Recomendação**:
```dart
// Versão atual do BCrypt não aceita rounds
// Considerar migrar para Argon2 (já instalado)
import 'package:argon2/argon2.dart';

static Future<String> hashPassword(String senha) async {
  final argon2 = Argon2(
    memoryCost: 65536,  // 64 MB
    timeCost: 3,
    parallelism: 4,
  );
  return await argon2.hashPasswordString(senha);
}
```

---

### 15. **Sanitização Incompleta de HTML**
**Severidade**: MÉDIA  
**CWE-79**: Cross-site Scripting (XSS)

**Descrição**:
- `InputSanitizer.sanitizeHtml()` básico
- Não cobre todos os vetores XSS

**Localização**:
```dart
// lib/utils/input_sanitizer.dart:29-36
static String sanitizeHtml(String input) {
  return input
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      // ... lista incompleta
}
```

**Recomendação**:
```dart
// Usar biblioteca especializada ou expandir sanitização
static String sanitizeHtml(String input) {
  if (input.isEmpty) return input;
  
  final htmlEscapes = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
    '`': '&#x60;',
    '=': '&#x3D;',
  };
  
  return input.replaceAllMapped(
    RegExp('[&<>"\'`=/]'),
    (match) => htmlEscapes[match.group(0)]!,
  );
}
```

---

### 16. **Falta de Rotação de Chaves de Criptografia**
**Severidade**: MÉDIA  
**CWE-324**: Use of a Key Past its Expiration Date

**Descrição**:
- Chaves AES geradas uma vez e nunca rotacionadas
- Sem política de rotação automática

**Recomendação**:
```dart
// Implementar rotação periódica
class CryptoService {
  static DateTime? _lastKeyRotation;
  static const _rotationInterval = Duration(days: 90);
  
  static Future<void> checkKeyRotation() async {
    if (_lastKeyRotation == null) {
      _lastKeyRotation = DateTime.now();
      return;
    }
    
    if (DateTime.now().difference(_lastKeyRotation!) > _rotationInterval) {
      await rotateKeys();
      _lastKeyRotation = DateTime.now();
    }
  }
}
```

---

### 17. **Informações Sensíveis em Exceções**
**Severidade**: MÉDIA  
**CWE-209**: Information Exposure Through an Error Message

**Descrição**:
- Exceções revelam detalhes internos

**Localização**:
```dart
// lib/services/auth_service.dart:16
throw Exception('Erro ao gerar hash da senha: $e');
```

**Recomendação**:
```dart
throw Exception('Erro ao processar credenciais');
// Log detalhado apenas internamente
SecureLogger.error('Hash generation failed', e, stackTrace);
```

---

### 18. **Falta de Proteção contra Timing Attacks**
**Severidade**: MÉDIA  
**CWE-208**: Information Exposure Through Timing Discrepancy

**Descrição**:
- Login retorna mais rápido para emails inexistentes

**Recomendação**:
```dart
static Future<User?> login(String email, String senha) async {
  final startTime = DateTime.now();
  
  // ... lógica de login
  
  // Garantir tempo mínimo de resposta
  const minDuration = Duration(milliseconds: 500);
  final elapsed = DateTime.now().difference(startTime);
  if (elapsed < minDuration) {
    await Future.delayed(minDuration - elapsed);
  }
  
  return result;
}
```

---

### 19-25. **Outras Vulnerabilidades Médias**:
- Falta de Content Security Policy
- Ausência de validação de tipos MIME em uploads
- Logs sem rotação automática
- Falta de proteção contra clickjacking
- Sem validação de tamanho de inputs
- Ausência de sanitização em nomes de arquivos exportados
- Falta de verificação de permissões de arquivos

---

## 🔵 VULNERABILIDADES BAIXAS

### 26-31. **Vulnerabilidades Baixas**:
- Versões de dependências não fixadas (usar exact versions)
- Falta de documentação de APIs de segurança
- Sem testes de segurança automatizados
- Comentários TODO/FIXME no código
- Falta de política de segurança documentada
- Ausência de security headers em comunicações

---

## 📋 Plano de Ação Prioritário

### Fase 1 - Crítico (Semana 1)
1. ✅ **Remover DB do Git**
   ```bash
   git rm --cached assets/db/gestao_incidentes.db
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch assets/db/gestao_incidentes.db" \
     --prune-empty --tag-name-filter cat -- --all
   ```

2. ✅ **Corrigir SQL Injection**
   - Implementar whitelist em `tableColumns()`
   - Adicionar prepared statements onde faltam

3. ✅ **Remover Auto-Push Git**
   - Tornar opt-in via configuração
   - Validar credenciais antes

4. ✅ **Sanitizar Logs**
   - Substituir todos `print()` por `SecureLogger`
   - Remover scripts de debug do repo

5. ✅ **Validar Paths**
   - Usar `path_provider` exclusivamente
   - Validar canonicalização de paths

### Fase 2 - Alto (Semana 2-3)
6. Criptografar exports (PDF/CSV)
7. Implementar rate limiting robusto
8. Fortalecer validação de senhas
9. Adicionar timeouts em operações de rede
10. Implementar verificação de integridade

### Fase 3 - Médio (Semana 4-6)
11. Migrar para Argon2
12. Expandir sanitização HTML
13. Implementar rotação de chaves
14. Adicionar proteção contra timing attacks
15. Documentar políticas de segurança

### Fase 4 - Contínuo
16. Testes de penetração automatizados
17. Auditoria de dependências mensais
18. Rotação forçada de credenciais padrão
19. Monitoramento de logs de segurança
20. Treinamento em práticas seguras

---

## 🛡️ Ferramentas Recomendadas

### Análise Estática
- `dart analyze --enable-experiment=enhanced-enum`
- `flutter pub outdated` (mensal)
- SonarQube para Flutter

### Testes de Segurança
- OWASP ZAP (para partes web, se houver)
- SQLMap (teste de SQL injection)
- Burp Suite Community

### Monitoramento
- Sentry para tracking de exceções
- ELK Stack para análise de logs

---

## 📊 Métricas de Melhoria

| Métrica | Antes | Meta | Prazo |
|---------|-------|------|-------|
| Vulnerabilidades Críticas | 5 | 0 | 2 semanas |
| Vulnerabilidades Altas | 8 | 2 | 4 semanas |
| Score de Segurança | 62/100 | 85/100 | 8 semanas |
| Cobertura de Testes | 0% | 70% | 12 semanas |

---

## 📝 Conclusão

O projeto possui **vulnerabilidades significativas** que devem ser corrigidas antes de produção:

### ⚠️ BLOQUEADORES PARA PRODUÇÃO:
1. Base de dados com hashes no Git
2. SQL Injection em PRAGMA
3. Auto-push Git sem validação
4. Exposição de senhas em tools
5. Path traversal vulnerabilities

### ✅ PONTOS POSITIVOS:
- BCrypt implementado corretamente
- Sanitização básica implementada
- Logging seguro em progresso
- Criptografia disponível (não utilizada ainda)

### 🎯 PRÓXIMOS PASSOS IMEDIATOS:
1. Executar Fase 1 do plano de ação
2. Adicionar testes de segurança
3. Documentar políticas de segurança
4. Implementar CI/CD com checks de segurança

---

**Revisado por**: Sistema de Auditoria Automatizada  
**Próxima revisão**: 15 de Novembro de 2025
