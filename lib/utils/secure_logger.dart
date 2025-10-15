import 'package:logger/logger.dart';
import 'input_sanitizer.dart';

/// Logger seguro que não expõe dados sensíveis
class SecureLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Lista de palavras-chave que indicam dados sensíveis
  static final _sensitiveKeywords = [
    'password',
    'senha',
    'hash',
    'token',
    'secret',
    'key',
    'credential',
    'auth',
    'api_key',
    'private',
  ];

  /// Verifica se o texto contém dados sensíveis
  static bool _containsSensitiveData(String message) {
    final lowerMessage = message.toLowerCase();
    return _sensitiveKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Sanitiza mensagem antes de logar
  static String _sanitizeMessage(String message) {
    if (_containsSensitiveData(message)) {
      // Se contém dados sensíveis, mascarar
      return '[DADOS SENSÍVEIS REMOVIDOS] ${message.substring(0, message.length > 50 ? 50 : message.length)}...';
    }
    return InputSanitizer.sanitize(message);
  }

  /// Log de debug (apenas em modo desenvolvimento)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (const bool.fromEnvironment('dart.vm.product')) return;
    _logger.d(_sanitizeMessage(message), error: error, stackTrace: stackTrace);
  }

  /// Log de informação
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(_sanitizeMessage(message), error: error, stackTrace: stackTrace);
  }

  /// Log de aviso
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(_sanitizeMessage(message), error: error, stackTrace: stackTrace);
  }

  /// Log de erro
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(_sanitizeMessage(message), error: error, stackTrace: stackTrace);
  }

  /// Log fatal (erro crítico)
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(_sanitizeMessage(message), error: error, stackTrace: stackTrace);
  }

  /// Log de auditoria (sem sanitização para manter integridade)
  static void audit(String action, String details, {int? userId}) {
    final timestamp = DateTime.now().toIso8601String();
    final userInfo = userId != null ? 'User:$userId' : 'System';
    _logger.i('🔒 AUDIT [$timestamp] $userInfo - Action: $action | Details: $details');
  }

  /// Log de acesso
  static void access(String email, bool success, {String? reason}) {
    final maskedEmail = InputSanitizer.maskEmail(email);
    final status = success ? '✓ SUCCESS' : '✗ FAILED';
    final reasonText = reason != null ? ' | Reason: $reason' : '';
    _logger.i('🔑 ACCESS $status - Email: $maskedEmail$reasonText');
  }

  /// Log de operação de base de dados
  static void database(String operation, {String? table, int? affectedRows}) {
    final tableInfo = table != null ? ' on $table' : '';
    final rowsInfo = affectedRows != null ? ' ($affectedRows rows)' : '';
    _logger.d('💾 DB $operation$tableInfo$rowsInfo');
  }

  /// Log de criptografia
  static void crypto(String operation, bool success) {
    final status = success ? 'SUCCESS' : 'FAILED';
    _logger.d('🔐 CRYPTO $operation - $status');
  }
}
