# Sistema de Controlo de Acesso Baseado em Roles (RBAC)

## 📋 Visão Geral

Este documento descreve o sistema de controlo de acesso baseado em roles implementado na aplicação de Gestão de Incidentes.

## 🎭 Roles Disponíveis

### 1. **Administrador** (`admin`)
- **Ícone**: 👑
- **Cor**: Vermelho
- **Permissões**:
  - ✅ Gerir utilizadores (atribuir roles, eliminar contas)
  - ✅ Criar, editar e eliminar incidentes
  - ✅ Alterar status e grau de risco dos incidentes
  - ✅ Ver estatísticas e relatórios
  - ✅ Gerir técnicos
  - ✅ Exportar dados (PDF, CSV)
  - ✅ Comentar em incidentes
  - ✅ Acesso total ao sistema

### 2. **Técnico** (`tecnico`)
- **Ícone**: 🔧
- **Cor**: Azul
- **Permissões**:
  - ✅ Criar, editar e eliminar incidentes
  - ✅ Alterar status e grau de risco dos incidentes
  - ✅ Ver estatísticas e relatórios
  - ✅ Exportar dados (PDF, CSV)
  - ✅ Comentar em incidentes
  - ❌ **NÃO PODE** gerir utilizadores
  - ❌ **NÃO PODE** gerir técnicos

### 3. **Utilizador Normal** (`user`)
- **Ícone**: 👤
- **Cor**: Verde
- **Permissões**:
  - ✅ Ver incidentes (apenas leitura)
  - ✅ Comentar em incidentes
  - ✅ Ver o próprio perfil
  - ❌ **NÃO PODE** criar/editar/eliminar incidentes
  - ❌ **NÃO PODE** alterar status ou risco
  - ❌ **NÃO PODE** gerir utilizadores ou técnicos
  - ❌ **NÃO PODE** exportar dados

## 🛡️ Funcionalidades de Segurança

### Gestão de Utilizadores (Admin Only)

#### Acesso
- Ecrã acessível através de: **Perfil → Gestão de Utilizadores**
- Apenas visível para administradores

#### Funcionalidades
1. **Listar Todos os Utilizadores**
   - Visualização de todos os utilizadores do sistema
   - Filtro por role (Todos, admin, tecnico, user)
   - Estatísticas: contagem por role e total

2. **Alterar Role de Utilizador**
   - Administradores podem promover/despromover utilizadores
   - Roles disponíveis: admin, tecnico, user
   - **Restrição**: Admin não pode alterar o próprio role
   - Confirmação obrigatória antes da alteração

3. **Eliminar Utilizador**
   - Administradores podem remover utilizadores do sistema
   - **Restrição**: Admin não pode eliminar a própria conta
   - Confirmação obrigatória com aviso de ação irreversível

4. **Auditoria**
   - Todas as alterações de role são registadas
   - Todas as eliminações de utilizadores são registadas
   - Inclui: ID do admin, timestamp, detalhes da ação

### Controlo de Acesso em Incidentes

#### Dashboard
- **Botão "Novo Incidente"**: Apenas visível para admins e técnicos
- **Gestão de Técnicos**: Apenas visível para admins
- Exportação (PDF/CSV): Todos os utilizadores

#### Detalhes do Incidente
- **Alterar Status**: Apenas admins e técnicos
- **Alterar Grau de Risco**: Apenas admins e técnicos
- **Comentários**: Todos os utilizadores podem comentar
- **Visualização**: Todos os utilizadores podem ver

## 📊 Serviços Implementados

### `UserManagementService`

#### Métodos Principais:

```dart
// Listar todos os utilizadores
Future<List<Map<String, dynamic>>> listarTodosUsuarios()

// Atualizar role de um utilizador (admin only)
Future<bool> atualizarRole(int adminId, int targetUserId, String newRole)

// Eliminar utilizador (admin only)
Future<bool> deletarUsuario(int adminId, int targetUserId)

// Obter estatísticas por role
Future<Map<String, int>> getStatisticsByRole()

// Verificar se utilizador é admin
Future<bool> isAdmin(int userId)

// Verificar se utilizador pode gerir incidentes
Future<bool> canManageIncidents(int userId)
```

#### Validações de Segurança:
- ✅ Validação de roles permitidos (`admin`, `tecnico`, `user`)
- ✅ Prevenção de auto-modificação de role
- ✅ Prevenção de auto-eliminação
- ✅ Auditoria automática de todas as operações

## 🎨 Interface de Utilizador

### Ecrã de Perfil (`perfil_screen.dart`)
- **Informação do Utilizador**:
  - Avatar colorido por role
  - Nome e email
  - Badge de role com cor e ícone

- **Botão "Gestão de Utilizadores"**:
  - Apenas visível para admins
  - Cor azul para destacar funcionalidade administrativa

### Ecrã de Gestão de Utilizadores (`gestao_users_screen.dart`)
- **Estatísticas no Topo**:
  - Número de admins (vermelho)
  - Número de técnicos (azul)
  - Número de utilizadores normais (verde)
  - Total de utilizadores (roxo)

- **Filtros**:
  - Filtro por role com dropdown
  - Visualização clara de roles com cores e ícones

- **Lista de Utilizadores**:
  - Avatar com inicial do nome
  - Nome, email e role
  - Badge "Você" para utilizador atual
  - Menu de ações (alterar role, eliminar)
  - Proteção: menu não aparece no próprio utilizador

## 🔒 Boas Práticas Implementadas

### 1. Princípio do Menor Privilégio
- Cada role tem apenas as permissões necessárias
- Utilizadores normais têm acesso mínimo (leitura + comentários)

### 2. Segregação de Deveres
- Admins gerem utilizadores
- Técnicos gerem incidentes
- Separação clara de responsabilidades

### 3. Auditoria Completa
- Todas as mudanças de role são registadas
- Todas as eliminações são registadas
- Rastreabilidade completa de ações administrativas

### 4. Validação de Entrada
- Roles permitidos são validados
- Prevenção de operações inválidas
- Mensagens de erro claras e informativas

### 5. Proteção Contra Erros
- Confirmação obrigatória para ações destrutivas
- Prevenção de auto-modificação/eliminação
- Validação em múltiplas camadas

## 📝 Exemplos de Uso

### Admin Alterando Role de Utilizador

```dart
// No ecrã de gestão de utilizadores
await UserManagementService.atualizarRole(
  adminId: 8,           // ID do Henrique (admin)
  targetUserId: 9,      // ID do Leonardo (user)
  newRole: 'tecnico',   // Promover para técnico
);
// Leonardo agora pode gerir incidentes
```

### Verificação de Permissões

```dart
// No dashboard
final canManage = widget.user.tipo == 'admin' || widget.user.tipo == 'tecnico';
if (canManage) {
  // Mostrar botão "Novo Incidente"
}

// No detalhes do incidente
if (canManageIncident) {
  // Permitir alteração de status/risco
}
```

## 🗂️ Estrutura de Ficheiros

```
lib/
├── services/
│   └── user_management_service.dart    # Lógica de gestão de utilizadores
├── screens/
│   ├── gestao_users_screen.dart        # UI de gestão de utilizadores
│   ├── perfil_screen.dart              # Perfil com botão admin
│   ├── dashboard_screen.dart           # Restrição de botão "Novo Incidente"
│   └── detalhes_incidente_dialog.dart  # Restrição de status/risco
```

## 🧪 Testes Recomendados

### Teste 1: Admin Gerindo Utilizadores
1. Login como Henrique (admin)
2. Ir para Perfil → Gestão de Utilizadores
3. Alterar Leonardo de `user` para `tecnico`
4. Verificar auditoria registada
5. Login como Leonardo
6. Verificar que agora pode criar incidentes

### Teste 2: Técnico com Permissões Limitadas
1. Login como Gonçalo (tecnico)
2. Verificar que botão "Novo Incidente" está visível
3. Criar novo incidente
4. Alterar status e risco
5. Ir para Perfil
6. Verificar que **NÃO** existe botão "Gestão de Utilizadores"

### Teste 3: Utilizador Normal Apenas Leitura
1. Login como Leonardo (user)
2. Verificar que botão "Novo Incidente" **NÃO** está visível
3. Abrir detalhes de incidente
4. Verificar que **NÃO** pode alterar status/risco
5. Verificar que **PODE** adicionar comentários
6. Ir para Perfil
7. Verificar badge de "👤 Utilizador Normal"

### Teste 4: Proteções de Segurança
1. Login como Admin (admin)
2. Ir para Gestão de Utilizadores
3. Tentar alterar o próprio role → **DEVE FALHAR**
4. Tentar eliminar a própria conta → **DEVE FALHAR**
5. Alterar role de Henrique → **DEVE FALHAR**
6. Eliminar Henrique → **DEVE FALHAR**

## 📈 Melhorias Futuras

### Sugestões de Expansão:
1. **Permissões Granulares**:
   - Controlar permissões por categoria de incidente
   - Permissões específicas por técnico

2. **Gestão de Grupos**:
   - Criar grupos de utilizadores
   - Atribuir permissões por grupo

3. **Aprovação de Mudanças de Role**:
   - Requer aprovação de 2 admins
   - Workflow de aprovação

4. **Histórico de Permissões**:
   - Ver todas as mudanças de role de um utilizador
   - Timeline de privilégios

5. **Permissões Temporárias**:
   - Elevar privilégios temporariamente
   - Auto-revogação após período

## 🎯 Conclusão

O sistema RBAC implementado fornece:
- ✅ Controlo de acesso granular
- ✅ Segregação de deveres clara
- ✅ Auditoria completa
- ✅ Interface intuitiva
- ✅ Proteções de segurança robustas

Todos os utilizadores têm acesso apropriado às funcionalidades necessárias para as suas responsabilidades, sem privilégios excessivos.
