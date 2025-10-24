import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../utils/secure_logger.dart';

/// Serviço para gerenciar a chave de criptografia do banco de dados
/// de forma segura usando flutter_secure_storage
class EncryptionKeyService {
  static final EncryptionKeyService instance = EncryptionKeyService._init();

  static const String _keyStorageKey = 'database_encryption_key';
  static const String _saltStorageKey = 'database_encryption_salt';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  EncryptionKeyService._init();

  /// Obtém ou gera a chave de criptografia do banco de dados
  Future<String> getDatabasePassword() async {
    try {
      // Tentar ler chave existente
      final String? existingKey =
          await _secureStorage.read(key: _keyStorageKey);
      if (existingKey != null && existingKey.isNotEmpty) {
        SecureLogger.database('Using existing encryption key');
        return existingKey;
      }

      // Se não existir, gerar nova chave
      SecureLogger.database('Generating new encryption key');
      final newKey = _generateSecureKey();
      await _secureStorage.write(key: _keyStorageKey, value: newKey);
      SecureLogger.database('Encryption key generated and stored securely');
      return newKey;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to get database password', e, stackTrace);
      rethrow;
    }
  }

  /// Gera uma chave segura aleatória de 256 bits
  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Gera um salt para derivação de chave (se necessário)
  Future<String> getSalt() async {
    final String? existingSalt =
        await _secureStorage.read(key: _saltStorageKey);
    if (existingSalt != null && existingSalt.isNotEmpty) {
      return existingSalt;
    }

    final newSalt = _generateSecureKey();
    await _secureStorage.write(key: _saltStorageKey, value: newSalt);
    return newSalt;
  }

  /// Deriva uma chave a partir de uma senha de usuário (opcional)
  /// Útil se quiser que o usuário defina sua própria senha
  String deriveKeyFromPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// Remove todas as chaves armazenadas (usar com cuidado!)
  Future<void> clearKeys() async {
    SecureLogger.warning(
        'Clearing all encryption keys - DATABASE WILL BE INACCESSIBLE!');
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _saltStorageKey);
  }

  /// Verifica se já existe uma chave armazenada
  Future<bool> hasKey() async {
    final String? existingKey = await _secureStorage.read(key: _keyStorageKey);
    return existingKey != null && existingKey.isNotEmpty;
  }
}
