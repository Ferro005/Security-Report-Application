import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import 'package:bcrypt/bcrypt.dart'; // Manter para verificar hashes antigos
import '../db/database_helper.dart';
import '../models/user.dart';
import '../utils/input_sanitizer.dart';
import '../utils/secure_logger.dart';
import 'auditoria_service.dart';
import 'session_service.dart';
import 'password_policy_service.dart';
import 'notifications_service.dart';
import '../utils/rate_limiter.dart';

class AuthService {
  /// Gera hash seguro com Argon2id (winner do Password Hashing Competition)
  /// Recomendação por plataforma:
  /// - Desktop: m=64MB, t=3, p=1–2 (evita thrash em máquinas fracas)
  /// - Android/iOS: m=32–48MB, t=3, p=1
  /// Observação: o código atual usa m=64MB, t=3, p=4 por compatibilidade histórica.
  /// Consulte o README (tabela de parâmetros) para detalhes e plano de transição.
  /// SECURITY: Cada password tem salt único e aleatório (16 bytes)
  static Future<String> hashPassword(String senha) async {
    try {
      // Gerar salt único e aleatório (16 bytes)
      final random = Random.secure();
      final saltBytes = Uint8List(16);
      for (int i = 0; i < saltBytes.length; i++) {
        saltBytes[i] = random.nextInt(256);
      }
      
      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,  // Argon2id (resistente a GPU e side-channel)
        saltBytes,                    // ✅ Salt único por utilizador
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3,               // Time cost
        memory: 65536,               // 64 MB (em KB)
  lanes: 4,                    // Parallelism (p)
      );
      
      final argon2 = Argon2BytesGenerator();
      argon2.init(parameters);
      
      final passwordBytes = utf8.encode(senha);
      final result = Uint8List(32); // 32 bytes output
      argon2.generateBytes(passwordBytes, result, 0, result.length);
      
      // Formato: $argon2id$<salt_base64>$<hash_base64>
      final hash = '\$argon2id\$${base64.encode(saltBytes)}\$${base64.encode(result)}';
      SecureLogger.crypto('argon2_hash_generated', true);
      return hash;
    } catch (e) {
      SecureLogger.error('Erro ao gerar hash Argon2', e);
      throw Exception('Erro ao processar credenciais');
    }
  }
  
  /// Verifica senha contra hash (suporta BCrypt legado e Argon2)
  /// SECURITY: Usa constant-time comparison para prevenir timing attacks
  static Future<bool> verifyPassword(String senha, String hash) async {
    try {
      // Detectar tipo de hash
      if (hash.startsWith(r'$argon2')) {
        // Parse: $argon2id$<salt>$<hash>
        final parts = hash.split('\$');
        
        // Formato antigo (sem salt separado) - compatibilidade retroativa
        if (parts.length == 3) {
          final hashPart = parts[2];
          final storedHash = base64.decode(hashPart);
          
          final parameters = Argon2Parameters(
            Argon2Parameters.ARGON2_id,
            utf8.encode('somesalt'),  // Salt fixo antigo
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
          
          final matches = _constantTimeCompare(result, storedHash);
          SecureLogger.crypto('argon2_verification_legacy', matches);
          return matches;
        }
        
        // Formato novo (com salt único) - mais seguro
        if (parts.length == 4) {
          final saltBytes = base64.decode(parts[2]);
          final storedHash = base64.decode(parts[3]);
          
          final parameters = Argon2Parameters(
            Argon2Parameters.ARGON2_id,
            saltBytes,  // ✅ Salt único do hash
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
          
          final matches = _constantTimeCompare(result, storedHash);
          SecureLogger.crypto('argon2_verification', matches);
          return matches;
        }
        
        SecureLogger.warning('Formato de hash Argon2 inválido');
        return false;
      } else if (hash.startsWith(r'$2') || hash.startsWith(r'$2a$') || hash.startsWith(r'$2b$')) {
        // Hash BCrypt legado
        SecureLogger.info('Verificando hash BCrypt legado - migração recomendada');
        final result = BCrypt.checkpw(senha, hash);
        SecureLogger.crypto('bcrypt_verification_legacy', result);
        return result;
      } else {
        SecureLogger.warning('Formato de hash desconhecido');
        return false;
      }
    } catch (e) {
      SecureLogger.error('Erro ao verificar senha', e);
      return false;
    }
  }
  
  /// Comparação constant-time para prevenir timing attacks
  /// SECURITY: Não permite ao atacante descobrir quantos bytes estão corretos
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    
    return diff == 0;
  }

  /// Cria um novo usuário com senha hasheada
  static Future<bool> criarUsuario(String nome, String email, String senha) async {
    try {
      // Sanitizar e validar inputs
      nome = InputSanitizer.sanitize(nome);
      final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
      
      if (sanitizedEmail == null) {
        throw Exception('Email inválido');
      }
      
      if (!InputSanitizer.isValidName(nome)) {
        throw Exception('Nome inválido. Use apenas letras e espaços.');
      }
      
      if (!InputSanitizer.isStrongPassword(senha)) {
        throw Exception('Senha fraca. Deve ter no mínimo 8 caracteres com maiúsculas, minúsculas e números.');
      }
      
      final db = await DatabaseHelper.instance.database;
      
      // Verificar se email já existe
      final existe = await db.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [sanitizedEmail],
        limit: 1,
      );

      if (existe.isNotEmpty) {
        SecureLogger.warning('Tentativa de cadastro com email existente');
        throw Exception('Email já cadastrado');
      }

      // Gerar hash da senha com Argon2
      final hash = await hashPassword(senha);

      // Inserir novo usuário
      await db.insert('usuarios', {
        'nome': nome,
        'email': sanitizedEmail,
        'hash': hash,
        'tipo': 'usuario',
        'failed_attempts': 0,
        'last_failed_at': null,
        'locked_until': null,
      });

      SecureLogger.audit('criar_usuario', 'Novo usuário: ${InputSanitizer.maskEmail(sanitizedEmail)}');
      
      await AuditoriaService.registar(
        acao: 'criar_usuario',
        detalhe: 'Novo usuário criado: ${InputSanitizer.maskEmail(sanitizedEmail)}'
      );

      // Sincronizar com assets DB (apenas em modo debug)
      await DatabaseHelper.instance.syncToAssets();

      return true;
    } catch (e) {
      SecureLogger.error('Erro ao criar usuário', e);
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  /// Tenta login com bloqueio temporário e logs de auditoria
  static Future<User?> login(String email, String senha) async {
    try {
        // Rate limiting global (por operação)
        if (RateLimiter.isBlocked('login')) {
          SecureLogger.warning('Rate limit global atingido para login');
          await AuditoriaService.registar(
            acao: 'login_bloqueado_rate_limit',
            detalhe: 'Muitas tentativas de login globais nas últimas 15 min',
          );
          await Future.delayed(const Duration(milliseconds: 300));
          return null;
        }

        // Registrar tentativa atual
        RateLimiter.record('login');
        // Sanitizar email
        final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
        if (sanitizedEmail == null) {
          SecureLogger.access(email, false, reason: 'Email inválido');
          return null;
        }
        
        final db = await DatabaseHelper.instance.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Buscar usuário
        final rows = await db.query(
            'usuarios',
            where: 'email = ?',
            whereArgs: [sanitizedEmail],
            limit: 1,
        );

        if (rows.isEmpty) {
            SecureLogger.access(sanitizedEmail, false, reason: 'Usuário não encontrado');
            await AuditoriaService.registar(
                acao: 'login_erro',
                detalhe: 'Email não existente: ${InputSanitizer.maskEmail(sanitizedEmail)}'
            );
            await Future.delayed(const Duration(milliseconds: 200));
            return null;
        }

        final user = User.fromMap(rows.first);

        // Verificar bloqueio
        if (user.lockedUntil != null && user.lockedUntil! > now) {
            SecureLogger.access(sanitizedEmail, false, reason: 'Conta bloqueada');
            throw Exception('Conta bloqueada. Tente novamente dentro de 30 segundos.');
        }

        // Verificação segura de senha (Argon2 ou BCrypt legado)
        bool ok = false;
        try {
          if (user.hash.isNotEmpty) {
            ok = await verifyPassword(senha, user.hash);
          } else {
            SecureLogger.warning('Hash vazio para usuário ${user.id}');
            await AuditoriaService.registar(
              acao: 'login_erro',
              detalhe: 'Hash de usuário vazio para id=${user.id}',
              userId: user.id,
            );
          }
        } catch (e) {
          SecureLogger.error('Erro ao verificar senha', e);
          await AuditoriaService.registar(
            acao: 'login_erro',
            detalhe: 'Erro ao verificar senha: ${e.toString()}',
            userId: user.id,
          );
          ok = false;
        }

        if (!ok) {
            final fails = (user.failedAttempts ?? 0) + 1;
            int? lockedUntil;
            
            if (fails >= 5) {
                lockedUntil = DateTime.now()
                    .add(const Duration(seconds: 30))
                    .millisecondsSinceEpoch;
                SecureLogger.warning('Conta bloqueada após 5 tentativas: ${user.id}');
            }

            final cols = await DatabaseHelper.instance.tableColumns('usuarios');
            final payload = <String, Object?>{};
            if (cols.contains('failed_attempts')) payload['failed_attempts'] = fails;
            if (cols.contains('last_failed_at')) payload['last_failed_at'] = now;
            if (cols.contains('locked_until')) payload['locked_until'] = lockedUntil;

            if (payload.isNotEmpty) {
              await db.update('usuarios', payload, where: 'id = ?', whereArgs: [user.id]);
            }

            SecureLogger.access(sanitizedEmail, false, reason: 'Senha incorreta (tentativa $fails)');
            
            await AuditoriaService.registar(
                acao: 'login_erro',
                userId: user.id,
                detalhe: 'Senha incorreta (tentativa $fails)'
            );

            await Future.delayed(const Duration(milliseconds: 200));
            return null;
        }

        // Login bem sucedido - resetar contadores
        final cols2 = await DatabaseHelper.instance.tableColumns('usuarios');
        final resetPayload = <String, Object?>{};
        if (cols2.contains('failed_attempts')) resetPayload['failed_attempts'] = 0;
        if (cols2.contains('last_failed_at')) resetPayload['last_failed_at'] = null;
        if (cols2.contains('locked_until')) resetPayload['locked_until'] = null;

        if (resetPayload.isNotEmpty) {
          await db.update('usuarios', resetPayload, where: 'id = ?', whereArgs: [user.id]);
        }

        // Gerar JWT token para sessão
        await SessionService.initializeSecretKey(); // Inicializar chave se necessário
        final token = await SessionService.generateToken(user);
        SecureLogger.audit('session_token_generated', 'Token JWT gerado para ${user.email} ($token)', userId: user.id);

        // Verificar expiração de senha
        bool passwordExpired = false;
        int? daysUntilExpiration;
        
        if (cols2.contains('password_expires_at')) {
          passwordExpired = await PasswordPolicyService.isPasswordExpired(user.id);
          daysUntilExpiration = await PasswordPolicyService.getDaysUntilExpiration(user.id);
          
          if (passwordExpired) {
            SecureLogger.warning('Senha expirada para ${user.email}');
            await NotificationsService.notifyPasswordExpired(user.id);
          } else if (daysUntilExpiration <= 7 && daysUntilExpiration > 0) {
            SecureLogger.info('Senha expira em $daysUntilExpiration dias para ${user.email}');
            await NotificationsService.notifyPasswordExpiringSoon(user.id, daysUntilExpiration);
          }
        }

        // Enviar notificação de login bem-sucedido
        await NotificationsService.notifyLogin(user.id, user.email);

        SecureLogger.access(sanitizedEmail, true);
        SecureLogger.audit('login_sucesso', 'Usuário: ${user.id}', userId: user.id);
        
        await AuditoriaService.registar(
            acao: 'login_sucesso',
            userId: user.id,
            detalhe: passwordExpired ? 'Senha expirada' : null
        );

        return user;
    } catch (e) {
        SecureLogger.error('Erro no login', e);
        throw Exception('Erro durante login: $e');
    }
  }
}
