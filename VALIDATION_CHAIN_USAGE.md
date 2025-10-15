# Guia de Uso do Validation Chain 0.0.11

## Visão Geral

O `validation_chain` foi integrado no projeto para fornecer **validação e sanitização robustas** usando uma abordagem de **chain of responsibility**.

## Arquivo: `lib/utils/validation_chains.dart`

Contém **ValidationChains**, **SanitizationChains**, **MapValidators** e **MapSanitizers** pré-configurados.

---

## 📋 Como Usar em TextFormFields (Flutter)

### Exemplo 1: Validação de Email

```dart
import 'package:flutter/material.dart';
import '../utils/validation_chains.dart';

TextFormField(
  decoration: const InputDecoration(labelText: 'Email'),
  keyboardType: TextInputType.emailAddress,
  validator: ValidationChains.emailValidation.validate,
  onSaved: (value) {
    final sanitized = ValidationChains.emailSanitization.sanitize(value);
    // Usar sanitized (email em minúsculas, sem espaços, sem caracteres de controle)
  },
)
```

### Exemplo 2: Validação de Senha

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Senha'),
  obscureText: true,
  validator: ValidationChains.passwordValidation.validate,
  // Retorna mensagens: "Campo obrigatório", "Mínimo de 12 caracteres", 
  // "Senha deve conter letra maiúscula", etc.
)
```

### Exemplo 3: Validação de Nome

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Nome Completo'),
  validator: ValidationChains.nameValidation.validate,
  onSaved: (value) {
    final sanitized = ValidationChains.nameSanitization.sanitize(value);
    // Normaliza espaços, remove caracteres de controle
  },
)
```

### Exemplo 4: Validação de Título de Incidente

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Título do Incidente'),
  validator: ValidationChains.incidentTitleValidation.validate,
  maxLength: 200,
)
```

---

## 🗺️ Como Usar MapValidator e MapSanitizer (Backend/API)

### Exemplo 1: Validação de Dados de Login

```dart
import '../utils/validation_chains.dart';

Future<void> login(Map<String, dynamic> credentials) async {
  // 1. Sanitizar dados de entrada
  final sanitized = ValidationChains.loginMapSanitizer.sanitize(credentials);
  
  // 2. Validar dados sanitizados
  final error = ValidationChains.loginMapValidator.validate(sanitized);
  
  if (error != null) {
    throw Exception('Validação falhou: $error');
  }
  
  // 3. Usar dados validados e sanitizados
  final email = sanitized['email'];
  final password = sanitized['password'];
  
  // Proceder com autenticação...
}
```

### Exemplo 2: Validação Detalhada (Múltiplos Erros)

```dart
Future<void> createUser(Map<String, dynamic> userData) async {
  // Sanitizar primeiro
  final sanitized = ValidationChains.userCreationMapSanitizer.sanitize(userData);
  
  // Validar e obter TODOS os erros (não apenas o primeiro)
  final errors = ValidationChains.userCreationMapValidator.rawValidate(sanitized);
  
  if (errors != null) {
    // errors é List<ValidationError>
    for (var error in errors) {
      print('Campo "${error.field}": ${error.errors.join(", ")}');
    }
    throw Exception('Múltiplos erros de validação');
  }
  
  // Criar usuário com dados sanitizados e validados
  await UserService.create(sanitized);
}
```

### Exemplo 3: Validação de Criação de Incidente

```dart
Future<Incidente> createIncident(Map<String, dynamic> data) async {
  // 1. Sanitizar
  final sanitized = ValidationChains.incidentCreationMapSanitizer.sanitize(data);
  
  // 2. Validar
  final error = ValidationChains.incidentCreationMapValidator.validate(sanitized);
  
  if (error != null) {
    throw ArgumentError('Erro de validação: $error');
  }
  
  // 3. Criar incidente
  return Incidente(
    titulo: sanitized['titulo'],
    descricao: sanitized['descricao'],
    categoria: sanitized['categoria'],
    grauRisco: sanitized['grauRisco'],
    status: sanitized['status'] ?? 'Pendente',
    // ...
  );
}
```

---

## 🔧 Criar Validações Customizadas

### ValidationChain Customizado

```dart
import 'package:validation_chain/validation_chain.dart';

// Definir validadores customizados
String? isEven(String? value) {
  if (value == null || value.isEmpty) return null;
  final number = int.tryParse(value);
  if (number == null) return 'Não é um número';
  return number % 2 == 0 ? null : 'Deve ser um número par';
}

String? positiveNumber(String? value) {
  if (value == null || value.isEmpty) return null;
  final number = int.tryParse(value);
  if (number == null) return 'Não é um número';
  return number > 0 ? null : 'Deve ser positivo';
}

// Criar chain customizado
final customValidation = ValidationChain([
  ValidationChains.required,
  ValidationChains.numbersOnly,
  positiveNumber,
  isEven,
]);

// Usar no TextFormField
TextFormField(
  validator: customValidation.validate,
)
```

### SanitizationChain Customizado

```dart
// Definir sanitizer customizado
String? removeEmojis(String? value) {
  if (value == null) return null;
  // Remove emojis e símbolos especiais
  return value.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
}

String? capitalizeWords(String? value) {
  if (value == null || value.isEmpty) return value;
  return value.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// Criar chain customizado
final customSanitization = SanitizationChain([
  ValidationChains.trim,
  ValidationChains.normalizeSpaces,
  removeEmojis,
  capitalizeWords,
]);

// Usar no onSaved
TextFormField(
  onSaved: (value) {
    final sanitized = customSanitization.sanitize(value);
    // sanitized está limpo, normalizado e capitalizado
  },
)
```

---

## 📦 MapValidator e MapSanitizer Customizados

```dart
// Criar validadores para um formulário de configurações
final settingsMapValidator = MapValidator({
  'theme': [
    ValidationChains.required,
    (value) => ['light', 'dark'].contains(value) ? null : 'Tema inválido',
  ],
  'notifications': [
    ValidationChains.required,
    (value) => ['true', 'false'].contains(value) ? null : 'Valor booleano inválido',
  ],
  'language': [
    ValidationChains.required,
    (value) => ['pt', 'en', 'es'].contains(value) ? null : 'Idioma não suportado',
  ],
});

final settingsMapSanitizer = MapSanitizer({
  'theme': [ValidationChains.trim, ValidationChains.toLowerCase],
  'notifications': [ValidationChains.trim, ValidationChains.toLowerCase],
  'language': [ValidationChains.trim, ValidationChains.toLowerCase],
});

// Uso
Future<void> updateSettings(Map<String, dynamic> settings) async {
  final sanitized = settingsMapSanitizer.sanitize(settings);
  final error = settingsMapValidator.validate(sanitized);
  
  if (error != null) {
    throw Exception('Configuração inválida: $error');
  }
  
  await saveSettings(sanitized);
}
```

---

## 🎯 Vantagens do Validation Chain

### ✅ Antes (Sem Validation Chain)

```dart
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email obrigatório';
  }
  value = value.trim().toLowerCase();
  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
    return 'Email inválido';
  }
  if (value.length > 255) {
    return 'Email muito longo';
  }
  return null;
}

// Código repetitivo em cada campo
```

### ✅ Depois (Com Validation Chain)

```dart
// Reutilizável em todo o projeto
TextFormField(
  validator: ValidationChains.emailValidation.validate,
  onSaved: (value) => ValidationChains.emailSanitization.sanitize(value),
)
```

---

## 🔐 Integração com InputSanitizer Existente

O `InputSanitizer` continua disponível para operações standalone:

```dart
import '../utils/input_sanitizer.dart';
import '../utils/validation_chains.dart';

// Usar InputSanitizer para casos específicos
final cleaned = InputSanitizer.sanitizeHtml(userInput);

// Usar ValidationChains para forms
TextFormField(
  validator: ValidationChains.emailValidation.validate,
)
```

---

## 📚 Validadores Disponíveis

| Validador | Descrição |
|-----------|-----------|
| `required` | Campo obrigatório |
| `emailFormat` | Formato de email válido |
| `strongPassword` | Senha forte (12+ chars, maiúscula, minúscula, número, especial) |
| `minLength(n)` | Mínimo de n caracteres |
| `maxLength(n)` | Máximo de n caracteres |
| `lettersOnly` | Apenas letras |
| `numbersOnly` | Apenas números |
| `alphanumeric` | Alfanumérico |
| `urlFormat` | URL válida |
| `phonePortugal` | Telefone português (9 dígitos) |
| `numericValue` | Valor numérico |
| `uuidFormat` | UUID válido |

## 🧹 Sanitizers Disponíveis

| Sanitizer | Descrição |
|-----------|-----------|
| `trim` | Remove espaços |
| `toLowerCase` | Converte para minúsculas |
| `toUpperCase` | Converte para maiúsculas |
| `removeSpecialChars` | Remove caracteres especiais |
| `removeControlChars` | Remove caracteres de controle |
| `normalizeSpaces` | Normaliza espaços múltiplos |
| `escapeHtml` | Escape HTML |
| `stripHtml` | Remove tags HTML |
| `digitsOnly` | Apenas dígitos |
| `limitLength(n)` | Limita comprimento |

## 🎬 Chains Pré-configurados

- `emailValidation` + `emailSanitization`
- `passwordValidation`
- `nameValidation` + `nameSanitization`
- `phoneValidation` + `phoneSanitization`
- `urlValidation`
- `incidentTitleValidation`
- `incidentDescriptionValidation` + `incidentDescriptionSanitization`

## 🗺️ MapValidators Pré-configurados

- `loginMapValidator` + `loginMapSanitizer`
- `userCreationMapValidator` + `userCreationMapSanitizer`
- `incidentCreationMapValidator` + `incidentCreationMapSanitizer`

---

## 🚀 Próximos Passos

1. **Migrar formulários existentes** para usar ValidationChains
2. **Aplicar MapSanitizers** nas APIs de criação de dados
3. **Criar validações customizadas** conforme necessário
4. **Adicionar testes unitários** para validadores customizados

---

## 📖 Documentação Oficial

- [validation_chain no pub.dev](https://pub.dev/packages/validation_chain)
- [Repositório GitHub](https://github.com/pr47h4m/validation_chain)
