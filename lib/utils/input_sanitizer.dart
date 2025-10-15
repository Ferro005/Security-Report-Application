import 'dart:convert';

/// Utilitário para sanitização e validação de inputs
class InputSanitizer {
  
  /// Remove caracteres especiais perigosos para SQL injection
  static String sanitizeSql(String input) {
    if (input.isEmpty) return input;
    
    // Remove ou escapa caracteres perigosos
    return input
        .replaceAll("'", "''")  // Escape single quotes
        .replaceAll(';', '')     // Remove semicolons
        .replaceAll('--', '')    // Remove SQL comments
        .replaceAll('/*', '')    // Remove block comments
        .replaceAll('*/', '')
        .replaceAll('xp_', '')   // Remove stored procedure calls
        .replaceAll('DROP', '')  // Remove dangerous keywords
        .replaceAll('DELETE', '')
        .replaceAll('TRUNCATE', '')
        .replaceAll('UPDATE', '')
        .replaceAll('INSERT', '');
  }

  /// Sanitiza HTML/XSS
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return input;
    
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .replaceAll('&', '&amp;');
  }

  /// Remove espaços extras e normaliza
  static String normalize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Valida email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida senha forte
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    // Deve conter: maiúscula, minúscula, número
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    
    return hasUppercase && hasLowercase && hasDigits;
  }

  /// Valida nome (apenas letras e espaços)
  static bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    return name.isNotEmpty && nameRegex.hasMatch(name);
  }

  /// Remove caracteres não alfanuméricos
  static String alphanumericOnly(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Limita comprimento do input
  static String limitLength(String input, int maxLength) {
    return input.length > maxLength 
        ? input.substring(0, maxLength) 
        : input;
  }

  /// Sanitiza input geral (combinação de técnicas)
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    
    var sanitized = normalize(input);
    sanitized = sanitizeHtml(sanitized);
    return sanitized;
  }

  /// Valida e sanitiza email
  static String? sanitizeEmail(String email) {
    final sanitized = normalize(email.toLowerCase());
    return isValidEmail(sanitized) ? sanitized : null;
  }

  /// Remove path traversal attempts
  static String sanitizePath(String path) {
    return path
        .replaceAll('..', '')
        .replaceAll('~', '')
        .replaceAll('//', '/')
        .replaceAll('\\\\', '\\');
  }

  /// Codifica para uso seguro em JSON
  static String jsonSafe(String input) {
    return jsonEncode(input).replaceAll('"', '');
  }

  /// Máscara de dados sensíveis para logs
  static String maskSensitive(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  /// Máscara de email para logs
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';
    
    final username = parts[0];
    final domain = parts[1];
    
    final maskedUsername = username.length > 2
        ? '${username[0]}***${username[username.length - 1]}'
        : '***';
    
    return '$maskedUsername@$domain';
  }

  /// Remove null bytes e caracteres de controle
  static String removeControlChars(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Validação de número de incidente
  static bool isValidIncidentNumber(String number) {
    final regex = RegExp(r'^INC-\d{6}$');
    return regex.hasMatch(number);
  }

  /// Sanitiza descrição de incidente
  static String sanitizeDescription(String description) {
    var sanitized = sanitize(description);
    sanitized = limitLength(sanitized, 1000);
    sanitized = removeControlChars(sanitized);
    return sanitized;
  }
}
