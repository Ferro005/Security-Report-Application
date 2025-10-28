# 🛡️ Security Report Application

Aplicação desktop standalone para gestão de incidentes de segurança desenvolvida com Flutter + SQLite.

## 📋 Sobre o Projeto

Sistema completo de gestão de incidentes de segurança com autenticação Argon2id, base de dados SQLite local criptografada, gestão de sessões com JWT, e funcionalidades avançadas de relatórios, auditoria e notificações in‑app.

### ✨ Funcionalidades Principais

- 🔐 **Autenticação Segura**: Sistema de login com Argon2id password hashing (winner do Password Hashing Competition 2015)
- 🔒 **Criptografia End-to-End**: Exports PDF/CSV criptografados com AES-256
- 📊 **Dashboard Interativo**: Visualização de incidentes com gráficos (fl_chart)
- 🗄️ **Base de Dados Local**: SQLite com proteção contra SQL injection
- 📝 **Gestão de Incidentes**: CRUD completo com categorização e níveis de risco
- 👥 **Gestão de Utilizadores**: Criação e gestão de técnicos e administradores
- 📄 **Exportação Segura**: Relatórios criptografados em PDF e CSV (AES-256)
- 🔍 **Auditoria**: Log completo com mascaramento de dados sensíveis
- 🛡️ **Input Sanitization**: Proteção contra XSS, SQL injection e path traversal
- 🔔 **Notificações In-App**: Painel rápido de notificações (ícone no topo), com marcação como lidas

## 🚀 Tecnologias Utilizadas

### Core
- **Flutter 3.35.6** - Framework UI (Windows, Linux, macOS, Android, iOS)
- **Dart 3.9.2** - Linguagem de programação
- **SQLite** - Base de dados local (Desktop via FFI, Mobile via sqflite)

### Dependências Principais
| Pacote | Versão | Finalidade |
|--------|--------|------------|
| `sqflite_common_ffi` | 2.3.6 | Base de dados SQLite |
| `sqlcipher_flutter_libs` | 0.6.1 | Criptografia SQLite com AES-256 |
| `argon2` | 1.0.1 | Hash de passwords (Argon2id) |
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
O projeto utiliza `dependency_overrides` para fixar versões de dependências transitivas em ambientes desktop (compatibilidade com `encrypt`/SQLCipher e Flutter 3.35.x). Nota:
- Estes overrides são voltados para Desktop; em Mobile, valide a matriz de versões do seu target.
- Caso surjam conflitos em plataformas específicas, ajuste as constraints no `pubspec.yaml` para o alvo desejado.
- Overrides atuais: `pointycastle: 4.0.0`, pacotes `flutter_secure_storage_*`, e pacotes base do Flutter (`characters`, `meta`, `material_color_utilities`, `test_api`).

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
│   ├── auth_service.dart        # Autenticação Argon2id (v2.1.0)
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
├── reset_clean.dart             # Reset da database (v2.1.0)
├── init_db.dart                 # Inicializar database
├── sync_db.dart                 # Sincronização manual de DB
└── populate_users.dart          # Popular users de teste

## 🧱 Arquitetura (MVVM)

O projeto utiliza MVVM com `provider`:

- ViewModels em `lib/viewmodels/` expõem estado e ações:
   - `BaseViewModel` — estado base (loading, error)
   - `LoginViewModel` — autenticação e criação de conta
   - `DashboardViewModel` — carregamento/filtragem de incidentes e badge de notificações
   - `TecnicosViewModel` — CRUD de técnicos e pesquisa
   - `FormIncidenteViewModel` — carregamento de técnicos e submissão de incidentes
   - `PerfilViewModel` — placeholder para futuras ações de perfil
- As Views (widgets em `lib/screens/`) consomem via `context.watch()`/`read()`.
- `main.dart` envolve o app com `MultiProvider` para registrar os ViewModels.

### Parâmetros Argon2id por plataforma (consistência)

| Plataforma | Memória (m) | Iterações (t) | Paralelismo (p) |
|-----------|--------------|---------------|------------------|
| Desktop   | 64 MB        | 3             | 4                |
| Android   | 32 MB        | 3             | 2                |
| iOS       | 32 MB        | 3             | 2                |

Observações:
- O código atual utiliza `m=64MB, t=3, p=4` (ver `lib/services/auth_service.dart`).
- Ajuste por plataforma se necessário (pode reduzir memória/paralelismo em dispositivos móveis mais modestos).
```

## 📦 Instalação e Configuração

### Pré-requisitos
- Flutter SDK 3.35.6+
- Dart SDK 3.9.2+
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

Nota: Na primeira execução, a base de dados é criada vazia e é gerado apenas o utilizador administrador padrão (`admin@exemplo.com`). As restantes contas de teste só são criadas se executar manualmente os scripts de `tools/` (por exemplo, `init_db.dart`/`populate_users.dart`).

### Segurança
- ✅ Passwords protegidas com **Argon2id** (memory-hard, 64MB RAM, 3 iterações)
- ✅ Política de senha: expiração (90 dias) e histórico (últimas 5) aplicados
- ✅ Validação de senha forte mínima (12+ caracteres, maiúsculas, minúsculas, números e caractere especial)
- ✅ Blacklist de senhas comuns
- ✅ Proteção contra tentativas de login excessivas (account lockout)
- ✅ Auditoria completa de autenticação
- ✅ Logging seguro com mascaramento de dados sensíveis
- ✅ Proteção contra timing attacks
- ✅ Proteção contra SQL injection
- ✅ Input sanitization em todos os campos
- ✅ Database criptografada com AES-256 (SQLCipher)

## 🗄️ Base de Dados

### Localização
- **Template**: Criado automaticamente na primeira execução
- **Runtime (Windows)**: `%USERPROFILE%\Documents\gestao_incidentes.db` (evita redireção para OneDrive)
- **Runtime (Outros)**: Diretório de documentos da aplicação (path_provider)
- **Nota**: Database não é versionada no Git por questões de segurança

### Schema Principal

**utilizadores**
- `id`, `nome`, `email`, `hash`, `tipo`
- `failed_attempts`, `last_failed_at`, `locked_until`
- Hashes: Argon2id (v2.1.0 - production standard)

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

## 🖥️ Plataformas Suportadas

- Desktop: Windows, Linux, macOS (SQLite via FFI + SQLCipher)
- Mobile: Android, iOS (SQLite nativo + SQLCipher)
- Web: Em avaliação (armazenamento cifrado no browser requer backend alternativo). A app compila para web, mas a persistência local cifrada está desativada nesta versão.

## 🛠️ Scripts de Gestão (Tools)

Principais scripts disponíveis em `tools/`:

> Importante:
> - Scripts de migração estão DEPRECATED e não devem ser executados. A aplicação cria/assegura o schema automaticamente.
> - `init_db.dart` e `populate_users.dart` são scripts de desenvolvimento (DEV‑only) e assumem caminhos legados (ex.: OneDrive). Prefira inicializar através da aplicação, que resolve `%USERPROFILE%\\Documents` de forma segura.

```bash
# Resetar database (v2.1.0 - remove todos os dados)
dart run tools/reset_clean.dart

# Inicializar database vazia (DEV‑only; legado)
dart run tools/init_db.dart

# Sincronizar DB manualmente (opcional)
dart run tools/sync_db.dart

# Popular com dados de teste (DEV‑only; legado)
dart run tools/populate_users.dart
```

**Nota**: Scripts de debug e migração obsoletos foram removidos na limpeza v2.1.0.

## 📊 Funcionalidades Detalhadas

### Dashboard
- Listagem de incidentes com filtros (Status, Categoria, Risco)
- Busca por número ou descrição
- Visualização de detalhes em dialog
- Atribuição de técnicos (admin)
- Estatísticas e gráficos
 - Painel de Notificações (ícone de sino no topo; listar, atualizar e marcar todas como lidas)

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

**Status Atual**: ✅ Sem erros; apenas avisos de depreciação informativos (UI); dependências atualizadas

## 📝 Qualidade de Código

- **Linter**: flutter_lints 6.0.0
- **Analysis**: Nenhum issue encontrado
- **Deprecações**: Todas resolvidas
- **Dependencies**: 100% atualizadas (sem outdated packages)

## 🔄 Atualizações Recentes (Outubro 2025)

### v2.1.1 - MVVM rollout (October 28, 2025)
- ✅ Adoção de MVVM com Provider nas telas: Login, Dashboard, Técnicos e Formulário de Incidente
- ✅ Providers globais registados em `main.dart`
- ✅ Documentação e scripts alinhados: scripts de migração permanecem DEPRECATED; tools de DEV marcadas como tal

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
- ✅ Database criptografada com SQLCipher

**v2.1.0 - Final Release**
- ✅ Auditoria completa de segurança
- ✅ Migração Argon2id completa (64MB RAM, 3 iterações, 4 threads)
- ✅ Remoção de scripts de debug (ferramentas obsoletas)
- ✅ Schema de dados alinhado e validado
- ✅ Documentação sincronizada
- ✅ Build release sem erros (0 warnings)

**Score de Segurança**: 62/100 → **91/100**

### Documentação Disponível
- 📄 `SECURITY_AUDIT.md` - Relatório de auditoria (atualizado com v2.1.0)
- 📄 `SECURITY_IMPROVEMENTS.md` - Melhorias de segurança (estado e próximos passos)
- 📄 `SECURITY_IMPROVEMENTS_IMPLEMENTATION.md` - Detalhes de implementação v2.1.0
- 📄 `SESSION_COMPLETION_REPORT.md` - Resumo final da sessão
 - 📄 `docs/security/jwt_policy.md` - Política de sessões JWT (lifetime, refresh, rotação)
 - 📄 `docs/security/data_at_rest_sqlcipher.md` - Dados em repouso (SQLCipher/KDF, PRAGMAs)

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
- [SECURITY_AUDIT.md](SECURITY_AUDIT.md) - Relatório Final de Segurança
- [Flutter Documentation](https://docs.flutter.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/)
- [Argon2 RFC 9106](https://datatracker.ietf.org/doc/html/rfc9106)
- [OWASP Password Storage](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

---

**Status do Projeto**: ✅ Production | 🔒 Hardened | 📦 v2.1.1 | 🏆 91/100 Security Score

*Última atualização: 28 de Outubro de 2025*
