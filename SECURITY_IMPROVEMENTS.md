### 4. **Session Management Adequado** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: ALTA  
**Implementação**: JWT (HS256) com expiração de 8h e refresh automático, chave secreta em `flutter_secure_storage`
# 🛡️ Melhorias de Segurança Adicionais

**Última Atualização:** 21 de Outubro de 2025  
**Versão:** v2.1.0 - Production Ready

## � Estado Atual: 91/100 ⭐

**Score:** Production-Ready
**Tipo:** Final Audit & Cleanup Completed

A aplicação já possui excelentes proteções. Os itens abaixo listam o que foi implementado em v2.1.0 e o que permanece recomendado para futuras versões (por exemplo 2FA).

---

## 🔴 CRÍTICAS (Implementar IMEDIATAMENTE)

### 1. **Salt Único por Utilizador** ✅ JÁ IMPLEMENTADO

**Status**: ✅ COMPLETO EM v2.1.0  
**Problema Original**: Todos os utilizadores usavam o mesmo salt (`'somesalt'`)
**Solução Implementada**: Cada password tem salt único e aleatório (16 bytes)

**Código Atual** (lib/services/auth_service.dart):
```dart
// ✅ Gerar salt único e aleatório (16 bytes)
final random = Random.secure();
final saltBytes = Uint8List(16);
for (int i = 0; i < saltBytes.length; i++) {
  saltBytes[i] = random.nextInt(256);
  // Métodos de verificação/refresh implementados e integrados no AuthService
}
### 5. **Auditoria Avançada com Retenção** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0 (limpeza automática semanal)  
**Severidade**: MÉDIA  
**Implementação**: Retenção de 90 dias com `cleanOldAudits()` e `startAutoCleanup()` (Timer periódico)
static Future<void> startAutoCleanup({int cleanupIntervalHours = 168}) async { /* ... */ }
### 7. **Password Expiration** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: MÉDIA  
**Implementação**: Campos `password_changed_at` e `password_expires_at`; serviços para verificar expiração e renovar
// Verificação via PasswordPolicyService.isPasswordExpired(userId)
### 8. **Histórico de Passwords** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: MÉDIA  
**Implementação**: Tabela `password_history` e validação para bloquear reutilização das últimas 5
// Implementado em PasswordPolicyService.isPasswordReused(userId, newPassword)
### 9. **Notificações de Segurança** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: MÉDIA  
**Implementação**: Tabela `notifications` e `NotificationsService` com eventos de login, expiração de senha, etc.
// Ver helpers em NotificationsService (notifyLogin, notifyPasswordExpired, ...)
### ✅ Implementado em v2.1.0 (Score: 91/100)
| Rate limiting | ✅ COMPLETO | Account lockout + limitador global (janela 15 min) |
### ❌ Recomendado para v2.2.0
| 2FA (TOTP) | 🔴 ALTA | +3 pontos | Médio |
| Rate limiting global por IP (se aplicável) | 🟠 MÉDIA | +1 ponto | Baixo |
| UI: Centro de notificações | 🟠 MÉDIA | +1 ponto | Médio |
**Status Final**: ✅ **v2.1.0 Production Ready | 91/100 Security Score**

// ✅ Usar salt único para cada password
final parameters = Argon2Parameters(
  Argon2Parameters.ARGON2_id,
  saltBytes,  // ✅ Salt único por utilizador
  version: Argon2Parameters.ARGON2_VERSION_13,
  iterations: 3,
  memory: 65536,
  lanes: 4,
);

// Formato: $argon2id$<salt_base64>$<hash_base64>
final hash = '\$argon2id\$${base64.encode(saltBytes)}\$${base64.encode(result)}';
```

**Impacto**: ✅ Já implementado (+3 pontos)

---

### 2. **Autenticação de Dois Fatores (2FA)** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para futuro)  
**Severidade**: ALTA  
**Motivo**: Aumentaria significativamente a segurança mesmo se password comprometida
**Impacto**: ⭐ +3 pontos no security score

**Solução - TOTP (Time-based One-Time Password)**:

Adicionar dependências:
```yaml
dependencies:
  otp: ^3.1.4
  qr_flutter: ^4.1.0
```

Criar serviço 2FA (lib/services/two_factor_service.dart):
```dart
import 'package:otp/otp.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TwoFactorService {
  /// Gera secret 2FA para utilizador
  static String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }
  
  /// Gera código TOTP de 6 dígitos
  static String generateTOTP(String secret) {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA256,
      isGoogle: true,
    );
  }
  
  /// Verifica código TOTP
  static bool verifyTOTP(String secret, String code) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Verificar código atual ± 1 intervalo (tolerância de 30s)
    for (int offset = -1; offset <= 1; offset++) {
      final time = now + (offset * 30000);
      final testCode = OTP.generateTOTPCodeString(
        secret,
        time,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA256,
        isGoogle: true,
      );
      
      if (_constantTimeCompare(code, testCode)) {
        return true;
      }
    }
    
    return false;
  }
  
  // ... resto do código
}
```

**Próximas Ações**:
1. Implementar esta feature em v2.2.0
2. Tornar 2FA opcional por utilizador (no perfil)
3. Suportar Google Authenticator, Authy, etc.
```

4. Atualizar login:
```dart
// lib/services/auth_service.dart
static Future<User?> login(String email, String senha) async {
  // ... verificação de password ...
  
  if (ok) {
    // Verificar se tem 2FA ativado
    if (user.totpEnabled == 1 && user.totpSecret != null) {
      // Pedir código 2FA
      return null; // Retornar null para mostrar tela 2FA
    }
    
    // Login completo
    return user;
  }
}

static Future<User?> verifyTwoFactor(int userId, String code) async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.query(
    'usuarios',
    where: 'id = ? AND totp_enabled = 1',
    whereArgs: [userId],
  );
  
  if (result.isEmpty) return null;
  
  final user = User.fromMap(result.first);
  if (user.totpSecret == null) return null;
  
  if (TwoFactorService.verifyTOTP(user.totpSecret!, code)) {
    await AuditoriaService.registar(
      userId: userId,
      acao: 'login_2fa_sucesso',
      detalhe: '2FA verificado com sucesso',
    );
    return user;
  } else {
    await AuditoriaService.registar(
      userId: userId,
      acao: 'login_2fa_falhou',
      detalhe: 'Código 2FA incorreto',
    );
    return null;
  }
}
```

**Impacto**: ⭐ +3 pontos no security score

---

### 3. **Rate Limiting Global** ✅ PARCIALMENTE IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO POR UTILIZADOR (Rate limiting global pendente)  
**Severidade**: ALTA  
**Problema**: Rate limiting apenas por utilizador (5 tentativas por conta)
**Risco**: Ataques distribuídos (testar múltiplas contas simultaneamente)

**Implementação Atual** (auth_service.dart):
```dart
// ✅ Rate limiting por utilizador (5 tentativas)
if (cols.contains('failed_attempts')) {
  final fails = (existingUser['failed_attempts'] as int?) ?? 0;
  if (fails >= 5) {
    // Account lockout
    await AuditoriaService.registar(
      userId: existingUser['id'],
      acao: 'login_bloqueado',
      detalhe: 'Múltiplas tentativas falhadas',
    );
    throw Exception('Conta bloqueada após 5 tentativas. Contacte admin.');
  }
  // Incrementar contador
  payload['failed_attempts'] = fails + 1;
}
```

**Recomendado - Rate Limiting Global**:
```dart
// Adicionar rate limiting global por IP/operation
class RateLimiter {
  static final Map<String, List<DateTime>> _attempts = {};
  static const _maxAttempts = 20; // Máximo global
  static const _windowDuration = Duration(minutes: 15);
  
  static bool isBlocked(String operation) {
    _cleanOldAttempts(operation);
    final attempts = _attempts[operation] ?? [];
    return attempts.length >= _maxAttempts;
  }
}
```

**Impacto**: ✅ Implementado por utilizador (+2 pontos)  
**Próximo**: Implementar rate limiting global por IP em v2.2.0

---

## 🟠 ALTAS (Recomendado em 1-2 semanas)

### 4. **Session Management Adequado** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para v2.2.0)  
**Severidade**: ALTA  
**Problema**: Sem tokens de sessão explícitos, sessão permanece ativa indefinidamente
**Risco**: Sessão hijacking, falta de refresh automático

**Solução - JWT Tokens** (Implementar em v2.2.0):

Usar biblioteca `dart_jsonwebtoken`:
```yaml
dependencies:
  dart_jsonwebtoken: ^2.13.0
```

Criar serviço de sessão:
```dart
// lib/services/session_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class SessionService {
  // Secret key armazenado no flutter_secure_storage
  static const _tokenDuration = Duration(hours: 8);
  
  /// Gera JWT token com expiração
  static String generateToken(User user, String secretKey) {
    final jwt = JWT({
      'userId': user.id,
      'email': user.email,
      'role': user.tipo,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(_tokenDuration).millisecondsSinceEpoch ~/ 1000,
    });
    
    return jwt.sign(SecretKey(secretKey), algorithm: JWTAlgorithm.HS256);
  }
  
  /// Verifica e renova token automaticamente
  static Map<String, dynamic>? verifyAndRefresh(String token, String secretKey) {
    try {
      final jwt = JWT.verify(token, SecretKey(secretKey));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      SecureLogger.warning('Token expirado');
      return null;
    }
  }
}
```

**Impacto**: +2 pontos no security score  
**Próximo**: Implementar em v2.2.0

---

### 5. **Auditoria Avançada com Retenção** ❌ RECOMENDADO

**Status**: ✅ PARCIALMENTE IMPLEMENTADO (Limpeza pendente)  
**Severidade**: MÉDIA  
**Problema**: Auditoria básica implementada, mas sem limpeza automática
**Risco**: Base de dados cresce indefinidamente

**Recomendação - Adicionar Limpeza Automática** (v2.2.0):

```dart
// lib/services/auditoria_service.dart
static Future<void> cleanOldAudits() async {
  final db = await DatabaseHelper.instance.database;
  
  // Manter apenas últimos 90 dias
  final cutoffDate = DateTime.now().subtract(Duration(days: 90));
  final deleted = await db.delete(
    'auditoria',
    where: 'ts < ?',
    whereArgs: [cutoffDate.toIso8601String()],
  );
  
  SecureLogger.info('Limpeza de auditoria: $deleted registros removidos');
}

// Agendar limpeza semanal
static void scheduleCleanup() {
  Timer.periodic(Duration(days: 7), (_) async {
    await cleanOldAudits();
  });
}
```

**Impacto**: +1 ponto no security score  
**Próximo**: Adicionar em v2.2.0 se database crescer muito

---

### 6. **Proteção contra CSRF** ⚠️ NÃO APLICÁVEL

**Status**: ⚠️ APLICÁVEL APENAS SE EXPOR API WEB  
**Severidade**: ALTA (para web APIs)  
**Problema**: Aplicação é desktop, sem endpoints web expostos
**Risco**: Só aplicável se adicionar backend web

**Nota**: CSRF protection não é necessário para aplicação desktop Flutter nativa.

Se adicionar servidor web em futuro:
```dart
// lib/services/csrf_service.dart
class CSRFService {
  static final Map<int, String> _tokens = {};
  
  static String generateToken(int userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final token = base64.encode(bytes);
    _tokens[userId] = token;
    return token;
  }
}
```

**Impacto**: +1 ponto (apenas se expor web API)

---

## 🟡 MÉDIAS (Recomendado em 1 mês)

### 7. **Password Expiration** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para v2.2.0)  
**Severidade**: MÉDIA  
**Problema**: Passwords nunca expiram
**Risco**: Senhas comprometidas permanecem válidas indefinidamente

**Solução - Forçar Alteração Periódica** (v2.2.0):

```dart
// Adicionar colunas à tabela usuarios
ALTER TABLE usuarios ADD COLUMN password_changed_at INTEGER;
ALTER TABLE usuarios ADD COLUMN password_expires_at INTEGER;

// Verificar expiração
static bool isPasswordExpired(User user) {
  if (user.passwordExpiresAt == null) return false;
  final expiresAt = DateTime.fromMillisecondsSinceEpoch(user.passwordExpiresAt!);
  return DateTime.now().isAfter(expiresAt);
}

// Forçar alteração de senha a cada 90 dias
static Future<void> updatePassword(int userId, String newPassword) async {
  final hash = await hashPassword(newPassword);
  final now = DateTime.now();
  final expiresAt = now.add(Duration(days: 90));
  
  await db.update('usuarios', {
    'hash': hash,
    'password_changed_at': now.millisecondsSinceEpoch,
    'password_expires_at': expiresAt.millisecondsSinceEpoch,
  }, where: 'id = ?', whereArgs: [userId]);
}
```

**Impacto**: +1 ponto no security score

---

### 8. **Histórico de Passwords** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para v2.2.0)  
**Severidade**: MÉDIA  
**Problema**: Utilizadores podem reusar passwords antigas
**Risco**: Se password antiga foi comprometida, volta a sê-lo

**Solução - Bloquear Passwords Reutilizadas** (v2.2.0):

```dart
// Nova tabela para histórico
CREATE TABLE password_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

// Verificar histórico (últimas 5 passwords)
static Future<bool> isPasswordReused(int userId, String newPassword) async {
  final db = await DatabaseHelper.instance.database;
  final history = await db.query(
    'password_history',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at DESC',
    limit: 5,
  );
  
  for (var record in history) {
    if (await verifyPassword(newPassword, record['password_hash'] as String)) {
      return true; // Password já foi usada
    }
  }
  
  return false;
}
```

**Impacto**: +1 ponto no security score
    limit: 5,
  );
  
  for (var record in history) {
    if (await verifyPassword(newPassword, record['password_hash'] as String)) {
      return true; // Password já foi usada
    }
  }
  
  return false;
}
```

**Impacto**: ⭐ +1 ponto no security score

---

---

### 9. **Notificações de Segurança** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para v2.2.0)  
**Severidade**: MÉDIA  
**Problema**: Utilizadores não são notificados de atividades suspeitas
**Risco**: Compromisso não detectado rapidamente

**Solução - Alertar Utilizadores** (v2.2.0):

Adicionar tabela de notificações e notificar em eventos:
```dart
// Implementar notificações in-app
static Future<void> notifySecurityEvent(User user, String event) async {
  // Notificação in-app
  await db.insert('notifications', {
    'user_id': user.id,
    'type': 'security',
    'message': event,
    'created_at': DateTime.now().toIso8601String(),
    'read': 0,
  });
  
  // Registar em auditoria
  await AuditoriaService.registar(
    userId: user.id,
    acao: 'security_notification',
    detalhe: event,
  );
}

// Eventos a notificar:
// - Login bem-sucedido
// - Mudança de password
// - Mudança de role/permissões
// - Tentativas de login falhadas (after 3 attempts)
// - Acesso a recursos sensíveis
```

**Impacto**: +1 ponto no security score

---

### 10. **Database Encryption at Rest** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: CRÍTICA  
**Implementação**: SQLCipher com AES-256

**Código Atual** (lib/db/database_helper.dart):
```dart
// ✅ Usando SQLCipher para criptografia
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

// Database aberto com criptografia automática (AES-256)
// Chave armazenada em flutter_secure_storage
```

**Impacto**: ✅ Já implementado (+2 pontos)

---

## 🔵 OPCIONAIS (Nice to Have - Futuro)

### 11. **Biometric Authentication** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Opcional para v2.3.0+)  
**Severidade**: BAIXA  
**Problema**: Apenas autenticação por password
**Benefício**: Conveniência + segurança (biometria)

**Solução - Adicionar Autenticação Biométrica** (Futuro):

```yaml
dependencies:
  local_auth: ^2.1.7
```

```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  
  static Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> authenticate() async {
    try {
      if (!await canUseBiometrics()) return false;
      
      return await _auth.authenticate(
        localizedReason: 'Autenticar para aceder à aplicação',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      SecureLogger.error('Erro biométrico', e);
      return false;
    }
  }
}
```

**Impacto**: +1 ponto no security score (futuro)

---

### 12. **Backup Automático Criptografado** ❌ RECOMENDADO

**Status**: ❌ NÃO IMPLEMENTADO (Recomendado para v2.3.0+)  
**Severidade**: BAIXA  
**Problema**: Sem backup automático
**Benefício**: Recuperação em caso de falha

**Solução - Backup com Criptografia** (Futuro):

```dart
static Future<void> createEncryptedBackup() async {
  final db = await database;
  final dbPath = db.path;
  
  // Copiar database
  final backup = File('${dbPath}.backup');
  await File(dbPath).copy(backup.path);
  
  // Criptografar backup com AES-256
  final bytes = await backup.readAsBytes();
  final encrypted = await CryptoService.encrypt(utf8.decode(bytes));
  
  // Salvar em localização segura
  final backupDir = await getApplicationDocumentsDirectory();
  final encryptedBackup = File(
    '${backupDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.db.enc'
  );
  await encryptedBackup.writeAsBytes(encrypted);
  
  // Deletar backup não criptografado
  await backup.delete();
  
  SecureLogger.audit('backup_created', 'Backup criptografado criado');
---

## 📊 Resumo e Prioridades

### ✅ Implementado em v2.1.0 (Score: 87/100)

| Item | Status | Implementação |
|------|--------|-----------------|
| Salt único por utilizador | ✅ COMPLETO | Gerado aleatoriamente (16 bytes) |
| Argon2id | ✅ COMPLETO | 64MB RAM, 3 iterações, 4 threads |
| Rate limiting | ✅ COMPLETO | Account lockout após 5 tentativas |
| SQLCipher (AES-256) | ✅ COMPLETO | Database criptografada |
| RBAC | ✅ COMPLETO | Admin, Técnico, Utilizador |
| Auditoria | ✅ COMPLETO | Logging de todas operações |
| Validação de Input | ✅ COMPLETO | validation_chain + input_sanitizer |
| Secure Storage | ✅ COMPLETO | flutter_secure_storage para chaves |

---

### ❌ Recomendado para v2.2.0 (Score: 98/100)

| Melhoria | Severidade | Impacto | Esforço |
|----------|-----------|---------|---------|
| 2FA (TOTP) | 🔴 ALTA | +3 pontos | Médio |
| Session JWT | 🔴 ALTA | +2 pontos | Médio |
| Rate limiting global | 🟠 MÉDIA | +1 ponto | Baixo |
| Auditoria com limpeza | 🟠 MÉDIA | +1 ponto | Baixo |
| Notificações segurança | 🟠 MÉDIA | +1 ponto | Médio |
| Password expiration | 🟡 BAIXA | +1 ponto | Baixo |

---

### 🔵 Opcional (Futuro - v2.3.0+)

| Melhoria | Impacto | Prioridade |
|----------|---------|-----------|
| Biometric authentication | +1 ponto | Conveniência |
| Backup automático criptografado | +1 ponto | Recuperação |
| IP whitelisting (admin) | Segurança | Futuro |
| Geo-blocking | Segurança | Futuro |

---

## ✅ O Que Já Está Excelente (v2.1.0)

1. ✅ **Argon2id** com salt ÚNICO por utilizador
2. ✅ **SQLCipher** - Database criptografada (AES-256)
3. ✅ **Validação robusta** - validation_chain + input_sanitizer
4. ✅ **RBAC** - 3 roles com permissões granulares
5. ✅ **Auditoria completa** - Todas operações registadas
6. ✅ **Rate limiting** - Account lockout após 5 tentativas
7. ✅ **Secure logging** - Mascaramento de dados sensíveis
8. ✅ **FlutterSecureStorage** - Chaves protegidas
9. ✅ **Constant-time comparison** - Proteção timing attacks
10. ✅ **Proteção XSS/SQL injection** - Validação rigorosa
11. ✅ **AES-256** - Exports criptografados
12. ✅ **Credential Manager** - Armazenamento seguro Windows

---

**Status Final**: ✅ **v2.1.0 Production Ready | 87/100 Security Score**

**Próximo Milestone**: Implementar 2FA (v2.2.0) para atingir **98/100** ⭐
