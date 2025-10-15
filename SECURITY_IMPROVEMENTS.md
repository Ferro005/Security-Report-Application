# 🛡️ Melhorias de Segurança Adicionais

## 📊 Estado Atual: 92/100 ⭐

A aplicação já possui excelentes proteções, mas aqui estão melhorias recomendadas para alcançar **98+/100**.

---

## 🔴 CRÍTICAS (Implementar IMEDIATAMENTE)

### 1. **Salt Único por Utilizador**
**Severidade**: CRÍTICA  
**Problema Atual**: Todos os utilizadores usam o mesmo salt (`'somesalt'`)
**Risco**: Se um atacante obtiver acesso ao código, pode fazer rainbow table attacks para todos os utilizadores de uma vez

**Solução**:
```dart
// lib/services/auth_service.dart
import 'dart:math';

static Future<String> hashPassword(String senha) async {
  // Gerar salt único e aleatório (16 bytes)
  final random = Random.secure();
  final saltBytes = Uint8List(16);
  for (int i = 0; i < saltBytes.length; i++) {
    saltBytes[i] = random.nextInt(256);
  }
  
  final parameters = Argon2Parameters(
    Argon2Parameters.ARGON2_id,
    saltBytes,  // ✅ Salt único
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
  
  // Formato: $argon2id$<salt_base64>$<hash_base64>
  final hash = '\$argon2id\$${base64.encode(saltBytes)}\$${base64.encode(result)}';
  return hash;
}

static Future<bool> verifyPassword(String senha, String hash) async {
  if (hash.startsWith(r'$argon2')) {
    // Parse: $argon2id$<salt>$<hash>
    final parts = hash.split('\$');
    if (parts.length < 4) return false;
    
    final saltBytes = base64.decode(parts[2]);
    final storedHash = base64.decode(parts[3]);
    
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      saltBytes,  // ✅ Usar salt do hash
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
    
    // Comparação constant-time
    return _constantTimeCompare(result, storedHash);
  }
  // ... resto do código
}

static bool _constantTimeCompare(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
```

**Impacto**: ⭐ +3 pontos no security score

---

### 2. **Autenticação de Dois Fatores (2FA)**
**Severidade**: ALTA  
**Problema Atual**: Apenas password (single factor)
**Risco**: Password comprometida = acesso total

**Solução - TOTP (Time-based One-Time Password)**:

1. Adicionar dependência:
```yaml
# pubspec.yaml
dependencies:
  otp: ^3.1.4
  qr_flutter: ^4.1.0
```

2. Criar serviço 2FA:
```dart
// lib/services/two_factor_service.dart
import 'package:otp/otp.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TwoFactorService {
  static const _storage = FlutterSecureStorage();
  
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
    final expectedCode = generateTOTP(secret);
    
    // Verificar código atual ± 1 intervalo (tolerância de 30s)
    final now = DateTime.now().millisecondsSinceEpoch;
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
  
  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
  
  /// Gera URI otpauth:// para QR code
  static String getOTPAuthUri(String email, String secret) {
    final issuer = Uri.encodeComponent('Security Report App');
    final account = Uri.encodeComponent(email);
    return 'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=SHA256&digits=6&period=30';
  }
  
  /// Salva secret 2FA para utilizador
  static Future<void> enableTwoFactor(int userId, String secret) async {
    final db = await DatabaseHelper.instance.database;
    
    // Adicionar coluna se não existir
    final cols = await DatabaseHelper.instance.tableColumns('usuarios');
    if (!cols.contains('totp_secret')) {
      await db.execute('ALTER TABLE usuarios ADD COLUMN totp_secret TEXT');
      await db.execute('ALTER TABLE usuarios ADD COLUMN totp_enabled INTEGER DEFAULT 0');
    }
    
    await db.update(
      'usuarios',
      {'totp_secret': secret, 'totp_enabled': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    SecureLogger.audit('2fa_enabled', 'Utilizador $userId ativou 2FA');
  }
  
  /// Desabilita 2FA
  static Future<void> disableTwoFactor(int userId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'usuarios',
      {'totp_secret': null, 'totp_enabled': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    SecureLogger.audit('2fa_disabled', 'Utilizador $userId desativou 2FA');
  }
}
```

3. Atualizar tela de perfil:
```dart
// lib/screens/perfil_screen.dart
ElevatedButton.icon(
  onPressed: () async {
    final secret = TwoFactorService.generateSecret();
    final uri = TwoFactorService.getOTPAuthUri(user.email, secret);
    
    // Mostrar QR code
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Configurar 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: uri, size: 200),
            SizedBox(height: 16),
            Text('Escaneie com Google Authenticator ou similar'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Código de verificação'),
              onSubmitted: (code) async {
                if (TwoFactorService.verifyTOTP(secret, code)) {
                  await TwoFactorService.enableTwoFactor(user.id, secret);
                  Navigator.pop(context);
                  _mostrarSnack('2FA ativado com sucesso!');
                } else {
                  _mostrarErro('Código incorreto');
                }
              },
            ),
          ],
        ),
      ),
    );
  },
  icon: Icon(Icons.security),
  label: Text('Ativar 2FA'),
)
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

### 3. **Rate Limiting Global**
**Severidade**: ALTA  
**Problema Atual**: Rate limiting apenas por utilizador (5 tentativas)
**Risco**: Ataques distribuídos (testar múltiplas contas)

**Solução**:
```dart
// lib/services/rate_limiter.dart
class RateLimiter {
  static final Map<String, List<DateTime>> _attempts = {};
  static const _maxAttempts = 20; // 20 tentativas totais
  static const _windowDuration = Duration(minutes: 15);
  
  /// Verifica se operação está bloqueada
  static bool isBlocked(String operation) {
    _cleanOldAttempts(operation);
    
    final attempts = _attempts[operation] ?? [];
    return attempts.length >= _maxAttempts;
  }
  
  /// Registra tentativa
  static void recordAttempt(String operation) {
    _attempts.putIfAbsent(operation, () => []);
    _attempts[operation]!.add(DateTime.now());
    _cleanOldAttempts(operation);
    
    SecureLogger.info('Rate limit: ${_attempts[operation]!.length}/$_maxAttempts para $operation');
  }
  
  static void _cleanOldAttempts(String operation) {
    final attempts = _attempts[operation];
    if (attempts == null) return;
    
    final cutoff = DateTime.now().subtract(_windowDuration);
    attempts.removeWhere((time) => time.isBefore(cutoff));
  }
  
  /// Reseta contador (admin only)
  static void reset(String operation) {
    _attempts.remove(operation);
    SecureLogger.audit('rate_limit_reset', 'Rate limit resetado para $operation');
  }
}

// Usar no login
static Future<User?> login(String email, String senha) async {
  // Rate limiting global
  if (RateLimiter.isBlocked('login')) {
    SecureLogger.warning('Rate limit excedido para login');
    throw Exception('Muitas tentativas de login. Tente novamente em 15 minutos.');
  }
  
  RateLimiter.recordAttempt('login');
  
  // ... resto do código ...
}
```

**Impacto**: ⭐ +1 ponto no security score

---

## 🟠 ALTAS (Implementar em 1-2 semanas)

### 4. **Session Management Adequado**
**Problema Atual**: Sem tokens de sessão, sem expiração
**Risco**: Sessão permanece ativa indefinidamente

**Solução - JWT Tokens**:
```yaml
dependencies:
  dart_jsonwebtoken: ^2.13.0
```

```dart
// lib/services/session_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class SessionService {
  static const _secretKey = 'your-256-bit-secret'; // MOVER PARA flutter_secure_storage
  static const _tokenDuration = Duration(hours: 8);
  
  /// Gera JWT token
  static String generateToken(User user) {
    final jwt = JWT({
      'userId': user.id,
      'email': user.email,
      'role': user.tipo,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(_tokenDuration).millisecondsSinceEpoch ~/ 1000,
    });
    
    return jwt.sign(SecretKey(_secretKey), algorithm: JWTAlgorithm.HS256);
  }
  
  /// Verifica token
  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secretKey));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      SecureLogger.warning('Token expirado');
      return null;
    } on JWTException catch (e) {
      SecureLogger.error('Token inválido', e);
      return null;
    }
  }
  
  /// Renova token
  static String? refreshToken(String oldToken) {
    final payload = verifyToken(oldToken);
    if (payload == null) return null;
    
    // Só renova se falta menos de 1 hora para expirar
    final exp = payload['exp'] as int;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final timeLeft = expiresAt.difference(DateTime.now());
    
    if (timeLeft.inHours < 1) {
      final user = User(
        id: payload['userId'],
        email: payload['email'],
        nome: '',
        tipo: payload['role'],
      );
      return generateToken(user);
    }
    
    return null;
  }
}
```

**Impacto**: ⭐ +2 pontos no security score

---

### 5. **Auditoria Avançada com Retenção**
**Problema Atual**: Auditoria básica, sem limpeza automática
**Risco**: Base de dados cresce indefinidamente

**Solução**:
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

// Agendar limpeza periódica
static void scheduleCleanup() {
  Timer.periodic(Duration(days: 7), (_) async {
    await cleanOldAudits();
  });
}

// Exportar auditoria para arquivo
static Future<File> exportAuditLogs(DateTime start, DateTime end) async {
  final db = await DatabaseHelper.instance.database;
  final logs = await db.query(
    'auditoria',
    where: 'ts >= ? AND ts <= ?',
    whereArgs: [start.toIso8601String(), end.toIso8601String()],
    orderBy: 'ts DESC',
  );
  
  // Exportar para JSON criptografado
  final jsonData = jsonEncode(logs);
  final encrypted = await CryptoService.encrypt(jsonData);
  
  final file = File('${Directory.systemTemp.path}/audit_${start.millisecondsSinceEpoch}.json.enc');
  await file.writeAsBytes(encrypted);
  
  return file;
}
```

**Impacto**: ⭐ +1 ponto no security score

---

### 6. **Proteção contra CSRF (Cross-Site Request Forgery)**
**Problema Atual**: Sem tokens CSRF
**Risco**: Ataques CSRF se expor API web

**Solução**:
```dart
// lib/services/csrf_service.dart
import 'dart:math';
import 'dart:convert';

class CSRFService {
  static final Map<int, String> _tokens = {};
  
  /// Gera token CSRF único para sessão
  static String generateToken(int userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final token = base64.encode(bytes);
    
    _tokens[userId] = token;
    return token;
  }
  
  /// Verifica token CSRF
  static bool verifyToken(int userId, String token) {
    return _tokens[userId] == token;
  }
  
  /// Invalida token (logout)
  static void invalidateToken(int userId) {
    _tokens.remove(userId);
  }
}
```

**Impacto**: ⭐ +1 ponto (se expor API web)

---

## 🟡 MÉDIAS (Implementar em 1 mês)

### 7. **Password Expiration**
**Problema**: Passwords nunca expiram
**Solução**:
```dart
// Adicionar colunas
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

**Impacto**: ⭐ +1 ponto no security score

---

### 8. **Histórico de Passwords**
**Problema**: Utilizadores podem reusar passwords antigas
**Solução**:
```dart
// Nova tabela
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

**Impacto**: ⭐ +1 ponto no security score

---

### 9. **Notificações de Segurança**
**Problema**: Utilizadores não são notificados de atividades suspeitas
**Solução**:
```dart
// Notificar em eventos de segurança
static Future<void> notifySecurityEvent(User user, String event) async {
  // Email (se configurado)
  if (emailService != null) {
    await emailService.send(
      to: user.email,
      subject: 'Alerta de Segurança - $event',
      body: 'Detectamos $event na sua conta...',
    );
  }
  
  // Notificação in-app
  await db.insert('notifications', {
    'user_id': user.id,
    'type': 'security',
    'message': event,
    'created_at': DateTime.now().toIso8601String(),
    'read': 0,
  });
  
  // Log
  await AuditoriaService.registar(
    userId: user.id,
    acao: 'security_notification',
    detalhe: event,
  );
}

// Eventos a notificar:
// - Login de novo dispositivo/localização
// - Mudança de password
// - Mudança de email
// - Mudança de role (admin)
// - Tentativas de login falhadas
// - 2FA ativado/desativado
```

**Impacto**: ⭐ +1 ponto no security score

---

### 10. **Database Encryption at Rest**
**Problema**: Base de dados SQLite não criptografada
**Solução**:
```yaml
dependencies:
  sqflite_sqlcipher: ^2.2.1  # Substituir sqflite_common_ffi
```

```dart
// lib/db/database_helper.dart
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<Database> _initDB() async {
  final path = join(dir.path, 'gestao_incidentes.db');
  
  // Obter chave de criptografia do flutter_secure_storage
  final storage = FlutterSecureStorage();
  String? dbKey = await storage.read(key: 'db_encryption_key');
  
  if (dbKey == null) {
    // Gerar nova chave (primeira vez)
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    dbKey = base64.encode(bytes);
    await storage.write(key: 'db_encryption_key', value: dbKey);
  }
  
  // Abrir database com criptografia
  return await openDatabase(
    path,
    version: 1,
    password: dbKey,  // ✅ Criptografia ativada
    onCreate: _onCreate,
  );
}
```

**Impacto**: ⭐ +2 pontos no security score

---

## 🔵 OPCIONAIS (Nice to Have)

### 11. **Biometric Authentication**
```yaml
dependencies:
  local_auth: ^2.1.7
```

```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  
  static Future<bool> authenticate() async {
    try {
      final available = await _auth.canCheckBiometrics;
      if (!available) return false;
      
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

**Impacto**: ⭐ +1 ponto no security score

---

### 12. **Backup Automático Criptografado**
```dart
static Future<void> createEncryptedBackup() async {
  final db = await database;
  final dbPath = db.path;
  
  // Copiar database
  final backup = File('${dbPath}.backup');
  await File(dbPath).copy(backup.path);
  
  // Criptografar backup
  final bytes = await backup.readAsBytes();
  final encrypted = await CryptoService.encrypt(utf8.decode(bytes));
  
  // Salvar em localização segura
  final backupDir = await getApplicationDocumentsDirectory();
  final encryptedBackup = File('${backupDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.db.enc');
  await encryptedBackup.writeAsBytes(encrypted);
  
  // Deletar backup não criptografado
  await backup.delete();
  
  SecureLogger.audit('backup_created', 'Backup criptografado criado');
}
```

**Impacto**: ⭐ +1 ponto no security score

---

## 📊 Roadmap de Implementação

### Semana 1 (CRÍTICO)
- [ ] ✅ Salt único por utilizador
- [ ] ✅ 2FA (TOTP)
- [ ] ✅ Rate limiting global

**Score esperado**: 92 → 98/100

### Semana 2-3 (ALTO)
- [ ] Session management (JWT)
- [ ] Auditoria avançada
- [ ] CSRF protection

**Score esperado**: 98 → 99/100

### Mês 1 (MÉDIO)
- [ ] Password expiration
- [ ] Password history
- [ ] Notificações de segurança
- [ ] Database encryption at rest

**Score esperado**: 99 → 100/100

### Opcional (Futuro)
- [ ] Biometric authentication
- [ ] Backup automático
- [ ] IP whitelisting para admins
- [ ] Geo-blocking

---

## 🎯 Resumo de Prioridades

| Melhoria | Severidade | Esforço | Impacto | Prioridade |
|----------|-----------|---------|---------|-----------|
| Salt único | CRÍTICA | Baixo | +3 | 🔴 AGORA |
| 2FA (TOTP) | CRÍTICA | Médio | +3 | 🔴 AGORA |
| Rate limiting | ALTA | Baixo | +1 | 🔴 AGORA |
| Session JWT | ALTA | Médio | +2 | 🟠 Semana 2 |
| DB Encryption | MÉDIA | Baixo | +2 | 🟡 Mês 1 |
| Password expiry | MÉDIA | Baixo | +1 | 🟡 Mês 1 |
| Biometrics | BAIXA | Médio | +1 | 🔵 Futuro |

---

## ✅ O Que Já Está Excelente

1. ✅ Argon2id com configuração adequada
2. ✅ Validação e sanitização (validation_chain)
3. ✅ RBAC completo
4. ✅ Auditoria básica
5. ✅ Rate limiting por utilizador
6. ✅ Secure logging
7. ✅ Proteção XSS/SQL injection
8. ✅ AES-256 para exports
9. ✅ Input validation robusta
10. ✅ Constant-time comparison

---

**Score Projetado com Melhorias**: **100/100** 🏆

Implemente as melhorias críticas primeiro (Semana 1) para alcançar **98/100** rapidamente!
