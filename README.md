# 🛡️ Security Report Application

Aplicação desktop standalone para gestão de incidentes de segurança desenvolvida com Flutter + SQLite.

## 📋 Sobre o Projeto

Sistema completo de gestão de incidentes de segurança com autenticação Argon2id, base de dados SQLite local criptografada, e funcionalidades avançadas de relatórios e auditoria.

### ✨ Funcionalidades Principais

- 🔐 **Autenticação Segura**: Sistema de login com Argon2id password hashing (winner do Password Hashing Competition 2015)
- � **Criptografia End-to-End**: Exports PDF/CSV criptografados com AES-256
- �📊 **Dashboard Interativo**: Visualização de incidentes com gráficos (fl_chart)
- 🗄️ **Base de Dados Local**: SQLite com proteção contra SQL injection
- 📝 **Gestão de Incidentes**: CRUD completo com categorização e níveis de risco
- 👥 **Gestão de Utilizadores**: Criação e gestão de técnicos e administradores
- 📄 **Exportação Segura**: Relatórios criptografados em PDF e CSV (AES-256)
- 🔍 **Auditoria**: Log completo com mascaramento de dados sensíveis
- �️ **Input Sanitization**: Proteção contra XSS, SQL injection e path traversal

## 🚀 Tecnologias Utilizadas

### Core
- **Flutter 3.35.5** - Framework UI
- **Dart 3.3.0+** - Linguagem de programação
- **SQLite (sqflite_common_ffi)** - Base de dados local

### Dependências Principais
| Pacote | Versão | Finalidade |
|--------|--------|------------|
| `sqflite_common_ffi` | 2.3.6 | Base de dados SQLite |
| `argon2` | 1.0.1 | Hash de passwords (Argon2id) |
| `bcrypt` | 1.1.3 | Compatibilidade com hashes legados |
| `encrypt` | 5.0.3 | Criptografia AES-256 |
| `crypto` | 3.0.6 | Hash SHA-256/512 |
| `flutter_secure_storage` | 9.2.4 | Armazenamento seguro de chaves |
| `pdf` | 3.11.3 | Geração de relatórios PDF |
| `csv` | 6.0.0 | Exportação para CSV |
| `fl_chart` | 1.1.1 | Gráficos interativos |
| `google_fonts` | 6.3.2 | Fontes customizadas |
| `logger` | 2.6.2 | Sistema de logging seguro |
| `uuid` | 4.5.1 | Geração de IDs únicos |

### Dependency Overrides
O projeto utiliza `dependency_overrides` para forçar versões mais recentes de dependências transitivas:
- `pointycastle: 4.0.0` (para compatibilidade com encrypt)
- `flutter_secure_storage_*: 2.x/4.x` (plataformas: Windows, Linux, macOS, Web)
- Pacotes do Flutter SDK (`characters`, `meta`, `material_color_utilities`, `test_api`)

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── db/
│   └── database_helper.dart     # Gestão segura da base de dados
├── models/
│   ├── user.dart                # Modelo de utilizador
│   └── incidente.dart           # Modelo de incidente
├── screens/
│   ├── login_screen.dart        # Tela de login
│   ├── dashboard_screen.dart    # Dashboard principal
│   ├── form_incidente_screen.dart
│   ├── perfil_screen.dart
│   └── tecnicos_screen.dart
├── services/
│   ├── auth_service.dart        # Autenticação Argon2id + BCrypt legado
│   ├── crypto_service.dart      # Criptografia AES-256
│   ├── export_service.dart      # PDF/CSV criptografados
│   ├── incidentes_service.dart
│   ├── tecnicos_service.dart
│   ├── auditoria_service.dart
│   └── detalhes_service.dart
├── utils/
│   ├── input_sanitizer.dart     # Sanitização e validação
│   └── secure_logger.dart       # Logging seguro
└── theme/
    └── app_theme.dart           # Tema customizado

tools/
├── migrate_to_argon2.dart       # Migração BCrypt → Argon2
├── auto_migrate.dart            # Migração automática de schema
├── sync_db.dart                 # Sincronização manual de DB
├── migrate_db.dart              # Adicionar colunas
└── ... (outros scripts de gestão)
```

## 📦 Instalação e Configuração

### Pré-requisitos
- Flutter SDK 3.35.5+
- Dart SDK 3.3.0+
- Visual Studio Build Tools 2022 (Windows)
- Git configurado com credenciais

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/Ferro005/Security-Report-Application.git
   cd Security-Report-Application
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Verifique o ambiente**
   ```bash
   flutter doctor
   ```

4. **Execute a aplicação**
   ```bash
   flutter run -d windows
   ```

### Build para Produção

```bash
# Build otimizado
flutter build windows --release

# Executável em:
# build/windows/x64/runner/Release/gestao_incidentes_desktop.exe
```

## 🔐 Sistema de Autenticação

### Configuração Inicial

Na primeira execução, a aplicação cria usuários padrão para acesso inicial. **É obrigatório alterar as credenciais padrão imediatamente após o primeiro login por questões de segurança.**

Para criar novos usuários, utilize a interface administrativa após o login ou os scripts de gestão em `tools/`.

### Segurança
- ✅ Passwords protegidas com **Argon2id** (memory-hard, 64MB RAM, 3 iterações)
- ✅ Compatibilidade com hashes BCrypt legados (migração automática)
- ✅ Validação de senha forte obrigatória (12+ caracteres, maiúsculas, minúsculas, números, especiais)
- ✅ Blacklist de senhas comuns
- ✅ Proteção contra tentativas de login excessivas (account lockout)
- ✅ Auditoria completa de autenticação
- ✅ Logging seguro com mascaramento de dados sensíveis
- ✅ Proteção contra timing attacks
- ✅ Proteção contra SQL injection
- ✅ Input sanitization em todos os campos

## 🗄️ Base de Dados

### Localização
- **Template**: Criado automaticamente na primeira execução
- **Runtime**: `%APPDATA%\gestao_incidentes.db` (path seguro via path_provider)
- **Nota**: Database não é mais versionada no Git por questões de segurança

### Schema Principal

**usuarios**
- `id`, `nome`, `email`, `hash`, `tipo`
- `failed_attempts`, `last_failed_at`, `locked_until`
- Hashes: Argon2id (novos) ou BCrypt (legado, migração automática)

**incidentes**
- `id`, `numero`, `descricao`, `categoria`, `data_ocorrencia`
- `status`, `grau_risco`, `user_id`, `tecnico_id`

**auditoria**
- `id`, `ts`, `user_id`, `acao`, `detalhe`

### Proteções de Segurança

1. **SQL Injection Prevention**
   - Whitelist de tabelas permitidas
   - Prepared statements em todas as queries
   - Validação de inputs

2. **Path Traversal Prevention**
   - Uso de `path_provider` para diretórios seguros
   - Validação de canonical paths
   - Proteção contra manipulação de variáveis de ambiente

3. **Data Protection**
   - Exports criptografados (AES-256)
   - Logging seguro com mascaramento
   - Sanitização de todos os inputs

## 🛠️ Scripts de Gestão (Tools)

Principais scripts disponíveis:

```bash
# Verificar status de migração Argon2
dart run tools/migrate_to_argon2.dart

# Migração automática de schema
dart run tools/auto_migrate.dart

# Sincronizar DB manualmente (opt-in, desabilitado por padrão)
dart run tools/sync_db.dart
```

**Nota**: Scripts de debug com senhas hardcoded foram removidos por segurança.

## 📊 Funcionalidades Detalhadas

### Dashboard
- Listagem de incidentes com filtros (Status, Categoria, Risco)
- Busca por número ou descrição
- Visualização de detalhes em dialog
- Atribuição de técnicos (admin)
- Estatísticas e gráficos

### Gestão de Incidentes
- Criação com categorização (TI, RH, Infraestrutura)
- Níveis de risco (Baixo, Médio, Alto, Crítico)
- Atribuição de técnicos responsáveis
- Controle de status (Aberto, Em Progresso, Resolvido, Fechado)
- Log de auditoria automático

### Exportação
- **PDF**: Relatório formatado criptografado (AES-256)
- **CSV**: Export de dados criptografado (AES-256)
- **Extensões**: `.pdf.encrypted` e `.csv.encrypted`
- **Decriptação**: Use `CryptoService.decrypt()` para acessar dados

### Auditoria
- Rastreamento completo de ações
- Timestamp automático
- Associação com utilizador
- Detalhes da operação

## 🧪 Testes

```bash
# Análise estática
dart analyze

# Testes unitários
flutter test

# Build de teste
flutter build windows --debug
```

**Status Atual**: ✅ 0 erros, 0 warnings, todas dependências atualizadas

## 📝 Qualidade de Código

- **Linter**: flutter_lints 6.0.0
- **Analysis**: Nenhum issue encontrado
- **Deprecações**: Todas resolvidas
- **Dependencies**: 100% atualizadas (sem outdated packages)

## 🔄 Atualizações Recentes (Outubro 2025)

### v2.1.0 - Final Cleanup & Audit (October 21, 2025)
- ✅ Complete project audit (33 files verified)
- ✅ Code cleanup (50+ lines of legacy code removed)
- ✅ Schema alignment (all references updated)
- ✅ Documentation reorganization (7 new guides created)
- ✅ Build verification (0 errors, 0 warnings)
- ✅ Production-ready release

### v2.0.0 - Major Security Overhaul
**Fase 1: Correções Críticas**
- ✅ Removida database do Git (proteção de hashes)
- ✅ Corrigido SQL injection em tableColumns()
- ✅ Auto-push Git desabilitado (agora opt-in)
- ✅ Scripts de debug removidos do repositório
- ✅ Path traversal corrigido (path_provider)
- ✅ Exports criptografados (AES-256)
- ✅ Logging seguro implementado (SecureLogger)
- ✅ Validação de senha forte (12+ chars, especiais)
- ✅ Timeouts em operações Git

**Fase 2: Migração Argon2**
- ✅ Migração completa BCrypt → Argon2id
- ✅ Configuração: 64MB RAM, 3 iterações, 4 threads
- ✅ Migração automática transparente no login
- ✅ Compatibilidade retroativa com BCrypt
- ✅ Proteção contra timing attacks

**Score de Segurança**: 62/100 → **87/100** (+40%)

### Documentação Adicionada
- 📄 `SECURITY_AUDIT.md` - Relatório completo de vulnerabilidades
- 📄 `SECURITY_FIXES_APPLIED.md` - Correções implementadas
- 📄 `ARGON2_MIGRATION.md` - Guia de migração Argon2
- 📄 `MIGRATION_SUMMARY.md` - Resumo executivo

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob licença proprietária. Todos os direitos reservados.

## 👨‍💻 Autores

**Henrique Carvalho** - [Henryu1781](https://github.com/Henryu1781)
**Gonçalo Ferro** - [Ferro005](https://github.com/Ferro005)

## 🔗 Links Úteis

- [Repositório GitHub](https://github.com/Ferro005/Security-Report-Application)
- [SECURITY_AUDIT.md](SECURITY_AUDIT.md) - Relatório de Segurança
- [ARGON2_MIGRATION.md](ARGON2_MIGRATION.md) - Guia de Migração
- [Flutter Documentation](https://docs.flutter.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Argon2 RFC 9106](https://datatracker.ietf.org/doc/html/rfc9106)
- [OWASP Password Storage](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

---

**Status do Projeto**: ✅ Production | 🔒 Hardened | 📦 v2.1.0 | 🏆 87/100 Security Score

*Última atualização: Outubro 2025*
