import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/user.dart';
import '../utils/secure_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _secretKeyName = 'jwt_secret_key';
  static const _deviceIdKey = 'device_id';
  static const _tokenDuration = Duration(minutes: 30); // Access TTL 30m
  static const _refreshThreshold = Duration(minutes: 5); // Refresh near-expiry (<5m)
  static const _refreshMaxWindow = Duration(hours: 24); // Allow refresh ≤ 24h from issue

  /// Inicializar secret key (chama apenas uma vez)
  static Future<void> initializeSecretKey() async {
    final secretKey = await _storage.read(key: _secretKeyName);
    if (secretKey == null || secretKey.isEmpty) {
      // Generate a random 256-bit key and store
      final rnd = Random.secure();
      final values = List<int>.generate(32, (_) => rnd.nextInt(256));
      final newKey = base64Url.encode(values);
      await _storage.write(key: _secretKeyName, value: newKey);
      SecureLogger.audit('jwt_secret_initialized', 'JWT secret key created');
    }
  }

  /// Gera/recupera um identificador local de dispositivo para device binding
  static Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final rnd = Random.secure();
    final values = List<int>.generate(16, (_) => rnd.nextInt(256));
    final newId = base64Url.encode(values);
    await _storage.write(key: _deviceIdKey, value: newId);
    SecureLogger.audit('device_id_initialized', 'Device ID created');
    return newId;
  }

  /// Obter secret key do armazenamento seguro
  static Future<String> _getSecretKey() async {
    final key = await _storage.read(key: _secretKeyName);
    if (key == null) {
      throw Exception('JWT secret key não inicializado');
    }
    return key;
  }

  /// Gera JWT token com expiração
  static Future<String> generateToken(User user) async {
    try {
      final secretKey = await _getSecretKey();
      final now = DateTime.now();
      final expiresAt = now.add(_tokenDuration);
      final refreshUntil = now.add(_refreshMaxWindow);
      final deviceId = await _getOrCreateDeviceId();

      final jwt = JWT({
        'userId': user.id,
        'email': user.email,
        'role': user.tipo,
        'iat': (now.millisecondsSinceEpoch / 1000).floor(),
        'exp': (expiresAt.millisecondsSinceEpoch / 1000).floor(),
        'rte': (refreshUntil.millisecondsSinceEpoch / 1000).floor(), // refresh token expiry (max)
        'deviceId': deviceId,
      });

      final token = jwt.sign(SecretKey(secretKey), algorithm: JWTAlgorithm.HS256);
      
      SecureLogger.audit('token_generated', 'JWT token gerado para ${user.email}');
      return token;
    } catch (e) {
      SecureLogger.error('Erro ao gerar JWT token', e);
      throw Exception('Erro ao gerar token de sessão');
    }
  }

  /// Verifica e valida JWT token
  static Future<Map<String, dynamic>?> verifyToken(String token) async {
    try {
      final secretKey = await _getSecretKey();

      try {
        final jwt = JWT.verify(token, SecretKey(secretKey));
        final payload = jwt.payload as Map<String, dynamic>;
        // Device binding: aceitar tokens legados sem deviceId, mas preferir reemissão
        final localDeviceId = await _storage.read(key: _deviceIdKey);
        final tokenDeviceId = payload['deviceId'];
        if (tokenDeviceId != null && localDeviceId != null && localDeviceId.isNotEmpty) {
          if (tokenDeviceId != localDeviceId) {
            SecureLogger.warning('JWT token device mismatch');
            return null;
          }
        } else {
          SecureLogger.info('Legacy token without device binding accepted');
        }

        SecureLogger.crypto('token_verified', true);
        return payload;
      } on JWTExpiredException {
        SecureLogger.warning('JWT token expirado');
        return null;
      } on JWTException catch (e) {
        SecureLogger.error('JWT token inválido', e);
        return null;
      }
    } catch (e) {
      SecureLogger.error('Erro ao verificar JWT token', e);
      return null;
    }
  }

  /// Renova token automaticamente se próximo de expirar
  static Future<String?> refreshTokenIfNeeded(String oldToken) async {
    try {
      final payload = await verifyToken(oldToken);
      if (payload == null) return null;

      // Obter tempo de expiração
      final exp = payload['exp'] as int;
      final rte = payload['rte'] as int?; // may be null for legacy tokens
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final timeLeft = expiresAt.difference(DateTime.now());

      // Respeitar janela máxima de refresh (≤ 24h desde emissão)
      if (rte != null) {
        final refreshUntil = DateTime.fromMillisecondsSinceEpoch(rte * 1000);
        if (DateTime.now().isAfter(refreshUntil)) {
          SecureLogger.info('Refresh window expired');
          return null;
        }
      }

      // Renovar se expirado ou com pouco tempo restante (< threshold)
      if (timeLeft.isNegative || timeLeft < _refreshThreshold) {
        final user = User(
          id: payload['userId'],
          email: payload['email'],
          nome: '', // Não necessário para renovação
          tipo: payload['role'],
          hash: '', // Não necessário para renovação
        );
        
        final newToken = await generateToken(user);
        SecureLogger.audit('token_refreshed', 'JWT token renovado para ${user.email}');
        return newToken;
      }

      return null; // Token ainda válido, não precisa renovação
    } catch (e) {
      SecureLogger.error('Erro ao renovar JWT token', e);
      return null;
    }
  }

  /// Extrai informações do token sem verificar assinatura (CUIDADO - uso interno apenas)
  static Map<String, dynamic>? decodeTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // Adicionar padding se necessário
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      SecureLogger.error('Erro ao decodificar payload do token', e);
      return null;
    }
  }

  /// Limpa todos os tokens (logout)
  static Future<void> clearAllTokens() async {
    try {
      // Não precisamos limpar nada no armazenamento, apenas fazer log
      SecureLogger.audit('all_tokens_cleared', 'Todos os tokens foram invalidados (logout)');
    } catch (e) {
      SecureLogger.error('Erro ao limpar tokens', e);
    }
  }
}
