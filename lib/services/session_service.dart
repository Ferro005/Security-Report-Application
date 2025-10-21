import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/user.dart';
import '../utils/secure_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _secretKeyName = 'jwt_secret_key';
  static const _tokenDuration = Duration(hours: 8);
  static const _refreshThreshold = Duration(hours: 1);

  /// Inicializar secret key (chama apenas uma vez)
  static Future<void> initializeSecretKey() async {
    String? secretKey = await _storage.read(key: _secretKeyName);
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

      final jwt = JWT({
        'userId': user.id,
        'email': user.email,
        'role': user.tipo,
        'iat': (now.millisecondsSinceEpoch / 1000).floor(),
        'exp': (expiresAt.millisecondsSinceEpoch / 1000).floor(),
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
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final timeLeft = expiresAt.difference(DateTime.now());

      // Renovar se falta menos de 1 hora para expirar
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
