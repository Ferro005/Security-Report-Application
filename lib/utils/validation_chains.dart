import 'package:validation_chain/validation_chain.dart';

/// Coleção de ValidationChains e SanitizationChains pré-configuradas
/// usando o pacote validation_chain 0.0.11
class ValidationChains {
  
  // ==================== VALIDATORS ====================
  
  /// Validador: campo obrigatório
  static String? required(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Campo obrigatório' : null;
  }

  /// Validador: email válido
  static String? emailFormat(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value) ? null : 'Email inválido';
  }

  /// Validador: senha forte
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 12) return 'Senha deve ter no mínimo 12 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Senha deve conter letra maiúscula';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Senha deve conter letra minúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Senha deve conter número';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'))) {
      return 'Senha deve conter caractere especial';
    }
    return null;
  }

  /// Validador: comprimento mínimo
  static String? Function(String?) minLength(int min) {
    return (String? value) {
      if (value == null || value.isEmpty) return null;
      return value.length < min ? 'Mínimo de $min caracteres' : null;
    };
  }

  /// Validador: comprimento máximo
  static String? Function(String?) maxLength(int max) {
    return (String? value) {
      if (value == null || value.isEmpty) return null;
      return value.length > max ? 'Máximo de $max caracteres' : null;
    };
  }

  /// Validador: apenas letras
  static String? lettersOnly(String? value) {
    if (value == null || value.isEmpty) return null;
    final lettersRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    return lettersRegex.hasMatch(value) ? null : 'Apenas letras permitidas';
  }

  /// Validador: apenas números
  static String? numbersOnly(String? value) {
    if (value == null || value.isEmpty) return null;
    final numbersRegex = RegExp(r'^[0-9]+$');
    return numbersRegex.hasMatch(value) ? null : 'Apenas números permitidos';
  }

  /// Validador: alfanumérico
  static String? alphanumeric(String? value) {
    if (value == null || value.isEmpty) return null;
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(value) ? null : 'Apenas letras e números';
  }

  /// Validador: URL válida
  static String? urlFormat(String? value) {
    if (value == null || value.isEmpty) return null;
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$'
    );
    return urlRegex.hasMatch(value) ? null : 'URL inválida';
  }

  /// Validador: telefone português (9 dígitos)
  static String? phonePortugal(String? value) {
    if (value == null || value.isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length == 9 ? null : 'Telefone deve ter 9 dígitos';
  }

  /// Validador: valor numérico
  static String? numericValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value) != null ? null : 'Valor numérico inválido';
  }

  /// Validador: UUID válido
  static String? uuidFormat(String? value) {
    if (value == null || value.isEmpty) return null;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value) ? null : 'UUID inválido';
  }

  // ==================== SANITIZERS ====================

  /// Sanitizer: remover espaços extras
  static String? trim(String? value) {
    return value?.trim();
  }

  /// Sanitizer: converter para minúsculas
  static String? toLowerCase(String? value) {
    return value?.toLowerCase();
  }

  /// Sanitizer: converter para maiúsculas
  static String? toUpperCase(String? value) {
    return value?.toUpperCase();
  }

  /// Sanitizer: remover caracteres especiais
  static String? removeSpecialChars(String? value) {
    return value?.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Sanitizer: remover caracteres de controle
  static String? removeControlChars(String? value) {
    return value?.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Sanitizer: normalizar espaços (remover múltiplos espaços)
  static String? normalizeSpaces(String? value) {
    return value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Sanitizer: escape HTML
  static String? escapeHtml(String? value) {
    if (value == null) return null;
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Sanitizer: remover tags HTML
  static String? stripHtml(String? value) {
    return value?.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Sanitizer: apenas dígitos
  static String? digitsOnly(String? value) {
    return value?.replaceAll(RegExp(r'\D'), '');
  }

  /// Sanitizer: limitar comprimento
  static String? Function(String?) limitLength(int maxLength) {
    return (String? value) {
      if (value == null || value.length <= maxLength) return value;
      return value.substring(0, maxLength);
    };
  }

  // ==================== VALIDATION CHAINS ====================

  /// ValidationChain para email
  static final emailValidation = ValidationChain([
    required,
    emailFormat,
    maxLength(255),
  ]);

  /// ValidationChain para senha
  static final passwordValidation = ValidationChain([
    required,
    minLength(12),
    strongPassword,
  ]);

  /// ValidationChain para nome
  static final nameValidation = ValidationChain([
    required,
    lettersOnly,
    minLength(2),
    maxLength(100),
  ]);

  /// ValidationChain para telefone
  static final phoneValidation = ValidationChain([
    required,
    phonePortugal,
  ]);

  /// ValidationChain para URL
  static final urlValidation = ValidationChain([
    urlFormat,
  ]);

  /// ValidationChain para título de incidente
  static final incidentTitleValidation = ValidationChain([
    required,
    minLength(5),
    maxLength(200),
  ]);

  /// ValidationChain para descrição de incidente
  static final incidentDescriptionValidation = ValidationChain([
    required,
    minLength(10),
    maxLength(1000),
  ]);

  // ==================== SANITIZATION CHAINS ====================

  /// SanitizationChain para email
  static final emailSanitization = SanitizationChain([
    trim,
    toLowerCase,
    removeControlChars,
  ]);

  /// SanitizationChain para nome
  static final nameSanitization = SanitizationChain([
    trim,
    normalizeSpaces,
    removeControlChars,
  ]);

  /// SanitizationChain para texto geral
  static final textSanitization = SanitizationChain([
    trim,
    normalizeSpaces,
    removeControlChars,
    escapeHtml,
  ]);

  /// SanitizationChain para telefone
  static final phoneSanitization = SanitizationChain([
    trim,
    digitsOnly,
  ]);

  /// SanitizationChain para descrição de incidente
  static final incidentDescriptionSanitization = SanitizationChain([
    trim,
    normalizeSpaces,
    removeControlChars,
    escapeHtml,
    limitLength(1000),
  ]);

  // ==================== MAP VALIDATORS ====================

  /// MapValidator para login
  static final loginMapValidator = MapValidator({
    'email': [required, emailFormat],
    'password': [required, minLength(12)],
  });

  /// MapValidator para criação de usuário
  static final userCreationMapValidator = MapValidator({
    'nome': [required, lettersOnly, minLength(2), maxLength(100)],
    'email': [required, emailFormat, maxLength(255)],
    'password': [required, minLength(12), strongPassword],
    'tipo': [required],
  });

  /// MapValidator para criação de incidente
  static final incidentCreationMapValidator = MapValidator({
    'titulo': [required, minLength(5), maxLength(200)],
    'descricao': [required, minLength(10), maxLength(1000)],
    'categoria': [required],
    'grauRisco': [required],
  });

  // ==================== MAP SANITIZERS ====================

  /// MapSanitizer para login
  static final loginMapSanitizer = MapSanitizer({
    'email': [trim, toLowerCase, removeControlChars],
    'password': [trim, removeControlChars],
  });

  /// MapSanitizer para criação de usuário
  static final userCreationMapSanitizer = MapSanitizer({
    'nome': [trim, normalizeSpaces, removeControlChars],
    'email': [trim, toLowerCase, removeControlChars],
    'password': [trim, removeControlChars],
  });

  /// MapSanitizer para criação de incidente
  static final incidentCreationMapSanitizer = MapSanitizer({
    'titulo': [trim, normalizeSpaces, removeControlChars, escapeHtml],
    'descricao': [trim, normalizeSpaces, removeControlChars, escapeHtml, limitLength(1000)],
    'categoria': [trim],
    'grauRisco': [trim],
    'status': [trim],
  });
}
