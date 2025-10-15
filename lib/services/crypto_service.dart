import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Serviço centralizado de criptografia e segurança
class CryptoService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'app_encryption_key';
  static const _ivName = 'app_encryption_iv';
  
  static encrypt_lib.Key? _cachedKey;
  static encrypt_lib.IV? _cachedIV;

  /// Inicializa ou recupera chave de criptografia
  static Future<void> initialize() async {
    try {
      // Tentar recuperar chave existente
      String? keyStr = await _storage.read(key: _keyName);
      String? ivStr = await _storage.read(key: _ivName);

      if (keyStr == null || ivStr == null) {
        // Gerar nova chave e IV
        final key = encrypt_lib.Key.fromSecureRandom(32);
        final iv = encrypt_lib.IV.fromSecureRandom(16);

        await _storage.write(key: _keyName, value: base64.encode(key.bytes));
        await _storage.write(key: _ivName, value: base64.encode(iv.bytes));

        _cachedKey = key;
        _cachedIV = iv;
      } else {
        _cachedKey = encrypt_lib.Key(base64.decode(keyStr));
        _cachedIV = encrypt_lib.IV(base64.decode(ivStr));
      }
    } catch (e) {
      // Fallback: usar chave derivada de constante (não recomendado para produção)
      _cachedKey = encrypt_lib.Key.fromUtf8('my32lengthsupersecretnooneknows1');
      _cachedIV = encrypt_lib.IV.fromLength(16);
    }
  }

  /// Encripta texto usando AES-256
  static Future<String> encrypt(String plainText) async {
    if (_cachedKey == null || _cachedIV == null) {
      await initialize();
    }

    final encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(_cachedKey!, mode: encrypt_lib.AESMode.cbc)
    );
    
    final encrypted = encrypter.encrypt(plainText, iv: _cachedIV!);
    return encrypted.base64;
  }

  /// Decripta texto usando AES-256
  static Future<String> decrypt(String encryptedText) async {
    if (_cachedKey == null || _cachedIV == null) {
      await initialize();
    }

    try {
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_cachedKey!, mode: encrypt_lib.AESMode.cbc)
      );
      
      final encrypted = encrypt_lib.Encrypted.fromBase64(encryptedText);
      return encrypter.decrypt(encrypted, iv: _cachedIV!);
    } catch (e) {
      throw Exception('Erro ao decriptar dados: $e');
    }
  }

  /// Gera hash SHA-256 de um texto
  static String hash(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gera hash SHA-512 (mais seguro)
  static String hashSecure(String text) {
    final bytes = utf8.encode(text);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Verifica integridade de dados
  static bool verifyIntegrity(String data, String expectedHash) {
    return hash(data) == expectedHash;
  }

  /// Limpa dados sensíveis da memória
  static void clearSensitiveData(List<int> data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  /// Limpa cache de chaves (ao fazer logout)
  static Future<void> clearCache() async {
    _cachedKey = null;
    _cachedIV = null;
  }

  /// Rotaciona chaves de criptografia (para segurança aumentada)
  static Future<void> rotateKeys() async {
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _ivName);
    _cachedKey = null;
    _cachedIV = null;
    await initialize();
  }
}
