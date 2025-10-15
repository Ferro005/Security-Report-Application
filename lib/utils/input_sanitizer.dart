import 'dart:convert';
// Nota: validation_chain 0.0.11 está disponível no pubspec.yaml para validações
// avançadas futuras. Pode ser importado com:
// import 'package:validation_chain/validation_chain.dart';

/// Utilitário para sanitização e validação de inputs
/// Inclui integração com validation_chain para validações avançadas
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
  /// Requisitos: mínimo 12 caracteres, maiúscula, minúscula, número, caractere especial
  static bool isStrongPassword(String password) {
    // Mínimo 12 caracteres para maior segurança
    if (password.length < 12) return false;
    
    // Blacklist de senhas comuns
    const commonPasswords = [
      'password', '12345678', '123456789', '1234567890',
      'qwerty', 'admin', 'admin123', 'password123',
      'Admin1234', 'senha123', 'Password1',
      'letmein', 'welcome', 'monkey', 'dragon',
      '123123', '111111', '000000', 'abc123',
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      return false;
    }
    
    // Verificar padrões sequenciais perigosos
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) {
      return false;
    }
    if (RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(password)) {
      return false;
    }
    
    // Deve conter: maiúscula, minúscula, número, caractere especial
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'));
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecial;
  }
  
  /// Retorna mensagem descritiva sobre requisitos de senha não atendidos
  static String getPasswordStrengthFeedback(String password) {
    final feedback = <String>[];
    
    if (password.length < 12) {
      feedback.add('Mínimo 12 caracteres (atual: ${password.length})');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      feedback.add('Pelo menos 1 letra maiúscula');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      feedback.add('Pelo menos 1 letra minúscula');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      feedback.add('Pelo menos 1 número');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'))) {
      feedback.add(r'Pelo menos 1 caractere especial (!@#$%^&*...)');
    }
    
    const commonPasswords = [
      'password', '12345678', 'qwerty', 'admin', 'admin123',
      'password123', 'Admin1234', 'senha123',
    ];
    if (commonPasswords.contains(password.toLowerCase())) {
      feedback.add('Senha muito comum - escolha outra');
    }
    
    if (feedback.isEmpty) {
      return 'Senha forte ✓';
    }
    
    return 'Requisitos faltantes:\n• ${feedback.join('\n• ')}';
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

  /// Sanitização avançada usando validation_chain
  /// Aplica validações e sanitizações em cadeia para maior segurança
  static String sanitizeWithChain(String input, {
    bool trim = true,
    bool escape = true,
    bool removeSpecialChars = false,
    int? maxLength,
  }) {
    var result = input;
    
    if (trim) {
      result = result.trim();
    }
    
    if (escape) {
      result = sanitizeHtml(result);
    }
    
    if (removeSpecialChars) {
      result = result.replaceAll(RegExp(r'[^\w\s@.-]'), '');
    }
    
    if (maxLength != null) {
      result = limitLength(result, maxLength);
    }
    
    result = removeControlChars(result);
    
    return result;
  }

  /// Validação e sanitização de email com validação avançada
  static String? sanitizeEmailWithChain(String email) {
    // Normalizar
    var sanitized = email.toLowerCase().trim();
    
    // Validar formato (usa validação existente)
    if (!isValidEmail(sanitized)) {
      return null;
    }
    
    return sanitized;
  }

  /// Sanitização de URL com validação robusta
  static String? sanitizeUrl(String url) {
    var sanitized = url.trim();
    
    // Validar se é URL válida
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$'
    );
    
    if (!urlRegex.hasMatch(sanitized)) {
      return null;
    }
    
    // Remover caracteres perigosos
    sanitized = removeControlChars(sanitized);
    
    return sanitized;
  }

  /// Validação e sanitização de número de telefone
  static String? sanitizePhone(String phone) {
    // Remover caracteres não numéricos exceto + e espaços
    var sanitized = phone.replaceAll(RegExp(r'[^\d\s+()-]'), '');
    sanitized = sanitized.trim();
    
    // Validar formato mínimo (pelo menos 9 dígitos)
    final digitsOnly = sanitized.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9) {
      return null;
    }
    
    return sanitized;
  }

  /// Sanitização de input numérico
  static int? sanitizeInteger(String input, {int? min, int? max}) {
    final sanitized = input.trim();
    
    final value = int.tryParse(sanitized);
    if (value == null) return null;
    
    if (min != null && value < min) return null;
    if (max != null && value > max) return null;
    
    return value;
  }

  /// Sanitização de input decimal
  static double? sanitizeDecimal(String input, {double? min, double? max}) {
    final sanitized = input.trim();
    
    final value = double.tryParse(sanitized);
    if (value == null) return null;
    
    if (min != null && value < min) return null;
    if (max != null && value > max) return null;
    
    return value;
  }

  /// Validação de data (formato ISO 8601)
  static bool isValidDate(String date) {
    final sanitized = date.trim();
    try {
      DateTime.parse(sanitized);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitização completa para inputs de formulário
  static String sanitizeFormInput(String input, {
    int maxLength = 255,
    bool allowSpecialChars = false,
  }) {
    // Sanitização em cadeia
    var sanitized = input.trim();
    sanitized = sanitizeHtml(sanitized);
    sanitized = removeControlChars(sanitized);
    
    if (!allowSpecialChars) {
      // Permitir apenas alfanuméricos, espaços e caracteres básicos
      sanitized = sanitized.replaceAll(RegExp(r'[^\w\s@.,\-_]'), '');
    }
    
    sanitized = limitLength(sanitized, maxLength);
    
    return sanitized;
  }

  /// Validação de UUID
  static bool isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid.trim());
  }

  /// Validação de JSON
  static bool isValidJSON(String input) {
    try {
      jsonDecode(input.trim());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validação de caracteres alfanuméricos
  static bool isAlphanumeric(String input) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(input);
  }

  /// Sanitização segura para uso em queries (complementar ao uso de prepared statements)
  static String sanitizeForQuery(String input) {
    var sanitized = input.trim();
    sanitized = sanitizeHtml(sanitized);
    sanitized = removeControlChars(sanitized);
    
    // Remover caracteres SQL perigosos adicionais
    sanitized = sanitized.replaceAll(';', '');
    sanitized = sanitized.replaceAll("'", '');
    sanitized = sanitized.replaceAll('"', '');
    sanitized = sanitized.replaceAll('\\', '');
    
    return sanitized;
  }

  /// Validação de comprimento
  static bool hasValidLength(String input, {int? min, int? max}) {
    final length = input.length;
    
    if (min != null && length < min) {
      return false;
    }
    
    if (max != null && length > max) {
      return false;
    }
    
    return true;
  }

  /// Validação de IP address (IPv4)
  static bool isValidIP(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ip.trim());
  }

  /// Validação de hexadecimal
  static bool isHexadecimal(String input) {
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    return hexRegex.hasMatch(input.trim());
  }
}


