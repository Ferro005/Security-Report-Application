### 4. **Session Management Adequado** ✅ JÁ IMPLEMENTADO

**Status**: ✅ IMPLEMENTADO em v2.1.0  
**Severidade**: ALTA  
**Implementação**: JWT (HS256) com expiração de 8h e refresh automático, chave secreta em `flutter_secure_storage`
# 🛡️ Melhorias de Segurança Adicionais

**Última Atualização:** 28 de Outubro de 2025  
**Versão:** v2.1.0 - Production Ready

> Nota (28/10/2025): Documentação sincronizada com a adoção de MVVM com Provider nas principais telas. Scripts de migração permanecem DEPRECATED; o schema é gerido automaticamente pela aplicação.

## Estado Atual: 91/100 ⭐

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
| UI: Centro de notificações (avançado) | 🟠 MÉDIA | +1 ponto | Médio |
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
  # 🛡️ Melhorias de Segurança — v2.1.0 (Atualizado)

  Última atualização: 21 de Outubro de 2025  
  Versão: v2.1.0  
  Score de Segurança: 91/100 ✅

  Este documento consolida o estado final das melhorias de segurança implementadas e os próximos passos. Todo o conteúdo foi revisto e alinhado com o código atual.

  ## ✅ Implementado em v2.1.0

  - Argon2id com SALT único por utilizador (64MB RAM, 3 iterações, 4 lanes)
  - Gestão de Sessões com JWT (HS256)
    - Expiração: 8 horas
    - Auto‑refresh: quando faltar < 1 hora
    - Chave secreta guardada em `flutter_secure_storage`
  - Rate limiting
    - Account lockout após 5 tentativas (30s)
    - Limitador global in‑memory: 20 tentativas/15 min por operação
  - Política de Password
    - Expiração: 90 dias
    - Histórico: bloqueia reutilização das últimas 5
    - Requisitos: mínimo 12 caracteres, maiúscula, minúscula, número e especial
  - Auditoria com retenção
    - Retenção: 90 dias
    - Limpeza automática agendada semanalmente
  - Notificações de Segurança (8 tipos) + painel in‑app com badge de não lidas
  - Criptografia de dados
    - Base de dados SQLite com SQLCipher (AES‑256)
    - Exports PDF/CSV criptografados (AES‑256)
  - Hardening adicional
    - InputSanitizer (XSS/SQL/Path)
    - SecureLogger (mascara dados sensíveis)
    - Caminho da DB no Windows em `%USERPROFILE%\Documents` (evita OneDrive) + validação canónica

  ## 🟡 Próximas melhorias (planeado v2.2.0)

  - 2FA (TOTP) opcional por utilizador
  - Rate limiting por IP (quando aplicável)
  - Centro de notificações avançado (filtros/paginação)
  - Limpeza de deprecações de UI remanescentes

  ## 📌 Notas de alinhamento com o código

  - `lib/services/session_service.dart` implementa JWT (geração, verificação e refresh)
  - `lib/utils/rate_limiter.dart` implementa limitador global (20/15min)
  - `lib/services/password_policy_service.dart` aplica expiração (90d) e histórico (5)
  - `lib/services/auditoria_service.dart` inclui `cleanOldAudits()` e `startAutoCleanup()`
  - `lib/services/notifications_service.dart` + UI com badge no `dashboard`
  - `lib/services/export_service.dart` grava `.encrypted` (AES‑256)
  - `lib/db/database_helper.dart` usa SQLCipher e valida caminho seguro

  ---

  Status Final: ✅ Production Ready | 91/100
static Future<User?> verifyTwoFactor(int userId, String code) async {
