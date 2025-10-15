# 🛡️ Security Report Application

Aplicação desktop standalone para gestão de incidentes de segurança desenvolvida com Flutter + SQLite.

## 📋 Sobre o Projeto

Sistema completo de gestão de incidentes de segurança com autenticação BCrypt, base de dados SQLite local, e funcionalidades avançadas de relatórios e auditoria.

### ✨ Funcionalidades Principais

- 🔐 **Autenticação Segura**: Sistema de login com BCrypt password hashing
- 📊 **Dashboard Interativo**: Visualização de incidentes com gráficos (fl_chart)
- 🗄️ **Base de Dados Local**: SQLite com sincronização automática
- 📝 **Gestão de Incidentes**: CRUD completo com categorização e níveis de risco
- 👥 **Gestão de Utilizadores**: Criação e gestão de técnicos e administradores
- 📄 **Exportação**: Relatórios em PDF e CSV
- 🔍 **Auditoria**: Log completo de ações dos utilizadores
- 🔄 **Auto-Sync Git**: Sincronização automática da DB com commit e push para GitHub

## 🚀 Tecnologias Utilizadas

### Core
- **Flutter 3.35.5** - Framework UI
- **Dart 3.3.0+** - Linguagem de programação
- **SQLite (sqflite_common_ffi)** - Base de dados local

### Dependências Principais
| Pacote | Versão | Finalidade |
|--------|--------|------------|
| `sqflite_common_ffi` | 2.3.6 | Base de dados SQLite |
| `bcrypt` | 1.1.3 | Hash de passwords |
| `pdf` | 3.11.3 | Geração de relatórios PDF |
| `csv` | 6.0.0 | Exportação para CSV |
| `fl_chart` | 1.1.1 | Gráficos interativos |
| `google_fonts` | 6.3.2 | Fontes customizadas |
| `flutter_secure_storage` | 9.2.4 | Armazenamento seguro |
| `encrypt` | 5.0.3 | Encriptação de dados |
| `logger` | 2.6.2 | Sistema de logging |
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
│   └── database_helper.dart     # Gestão da base de dados + auto-sync Git
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
│   ├── auth_service.dart        # Autenticação BCrypt
│   ├── incidentes_service.dart
│   ├── tecnicos_service.dart
│   ├── auditoria_service.dart
│   ├── export_service.dart      # PDF/CSV exports
│   └── detalhes_service.dart
└── theme/
    └── app_theme.dart           # Tema customizado

tools/
├── auto_migrate.dart            # Migração automática de schema
├── sync_db.dart                 # Sincronização manual de DB
├── list_users.dart              # Listar utilizadores
├── migrate_db.dart              # Adicionar colunas
├── fix_hash.dart                # Corrigir hashes BCrypt
├── compare_dbs.dart             # Comparar DBs
└── ... (12 scripts de gestão)

assets/
└── db/
    └── gestao_incidentes.db     # Base de dados template
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

### Utilizadores Pré-configurados

| Email | Password | Tipo | Descrição |
|-------|----------|------|-----------|
| `admin@exemplo.com` | `Admin1234` | Administrador | Acesso total |
| `joao@exemplo.com` | `Admin1234` | Técnico | Gestão de incidentes |

### Segurança
- ✅ Passwords protegidas com **BCrypt** (cost factor 10)
- ✅ Validação de hash antes de verificação
- ✅ Proteção contra hashes vazios
- ✅ Tratamento de exceções em operações criptográficas
- ✅ Controle de tentativas falhadas de login
- ✅ Auditoria completa de ações

## 🗄️ Base de Dados

### Localização
- **Template (version control)**: `assets/db/gestao_incidentes.db`
- **Runtime**: `C:\Users\[USER]\OneDrive\Documentos\gestao_incidentes.db`

### Schema Principal

**usuarios**
- `id`, `nome`, `email`, `hash`, `tipo`
- `failed_attempts`, `last_failed_at`, `locked_until`

**incidentes**
- `id`, `numero`, `descricao`, `categoria`, `data_ocorrencia`
- `status`, `grau_risco`, `user_id`, `tecnico_id`

**auditoria**
- `id`, `ts`, `user_id`, `acao`, `detalhe`

### Sincronização Automática

O sistema possui **auto-sync com Git** integrado:

1. **Quando**: Ao criar novo utilizador (apenas em DEBUG)
2. **O que faz**:
   - Copia DB runtime → `assets/db/`
   - `git add assets/db/gestao_incidentes.db`
   - `git commit -m "auto: update users database [timestamp]"`
   - `git push origin main`
3. **Console Output**:
   ```
   ✓ Base de dados sincronizada com assets/db/
   ✓ Commit automático criado
   ✓ Push automático para GitHub concluído
     📦 DB atualizada no repositório!
   ```

Ver: [`AUTO_SYNC_STATUS.md`](AUTO_SYNC_STATUS.md) para mais detalhes.

## 🛠️ Scripts de Gestão (Tools)

O projeto inclui 12 scripts Dart para manutenção:

```bash
# Listar utilizadores da DB empacotada
dart run tools/list_users.dart

# Migração automática de schema
dart run tools/auto_migrate.dart

# Sincronizar DB manualmente (runtime → assets)
dart run tools/sync_db.dart

# Comparar DBs (runtime vs packaged)
dart run tools/compare_dbs.dart

# Verificar password do admin
dart run tools/verify_admin_password.dart

# Corrigir hashes duplicados
dart run tools/fix_hash.dart
```

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
- **PDF**: Relatório formatado com logo e estatísticas
- **CSV**: Export de dados para Excel/análise

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

### v1.0.0 - Otimização Completa
- ✅ Atualizadas todas as 19 dependências diretas e transitivas
- ✅ Corrigidos todos os erros e warnings de análise
- ✅ Resolvidas 6 deprecações (DropdownButtonFormField)
- ✅ Removidos imports e variáveis não utilizadas
- ✅ Implementado auto-commit Git em DatabaseHelper
- ✅ Removida dependência obsoleta `argon2`
- ✅ Adicionado flutter_test e flutter_lints
- ✅ Limpeza de ficheiros obsoletos

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob licença proprietária. Todos os direitos reservados.

## 👨‍💻 Autor

**Henrique Ferro** - [Ferro005](https://github.com/Ferro005)

## 🔗 Links Úteis

- [Repositório GitHub](https://github.com/Ferro005/Security-Report-Application)
- [Flutter Documentation](https://docs.flutter.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [BCrypt Dart Package](https://pub.dev/packages/bcrypt)

---

**Status do Projeto**: ✅ Produção | 🔄 Em manutenção ativa | 📦 v1.0.0

*Última atualização: Outubro 2025*
