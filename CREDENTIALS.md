# 🔐 Credenciais de Acesso - Sistema RBAC

## ✅ PASSWORD PADRÃO

**TODOS os utilizadores usam a mesma password**:
```
Senha@123456
```

---

## 👥 UTILIZADORES DISPONÍVEIS

### 👑 Administradores (Acesso Total)

#### 1. Henrique
- **Email**: `henrique@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**:
  - ✅ Gerir utilizadores (alterar roles, eliminar contas)
  - ✅ Gerir técnicos
  - ✅ Criar/editar/eliminar incidentes
  - ✅ Alterar status e risco
  - ✅ Ver estatísticas
  - ✅ Exportar relatórios
  - ✅ Comentar

#### 2. Admin
- **Email**: `admin@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**: Iguais ao Henrique

---

### 🔧 Técnicos (Gestão de Incidentes)

#### 3. Gonçalo
- **Email**: `goncalo@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**:
  - ✅ Criar/editar/eliminar incidentes
  - ✅ Alterar status e risco
  - ✅ Ver estatísticas
  - ✅ Exportar relatórios
  - ✅ Comentar
  - ❌ **NÃO PODE** gerir utilizadores
  - ❌ **NÃO PODE** gerir técnicos

#### 4. Duarte
- **Email**: `duarte@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**: Iguais ao Gonçalo

---

### 👤 Utilizadores Normais (Apenas Leitura)

#### 5. Leonardo
- **Email**: `leonardo@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**:
  - ✅ Ver incidentes (apenas leitura)
  - ✅ Comentar em incidentes
  - ✅ Ver próprio perfil
  - ❌ **NÃO PODE** criar/editar/eliminar incidentes
  - ❌ **NÃO PODE** alterar status ou risco
  - ❌ **NÃO PODE** gerir utilizadores ou técnicos
  - ❌ **NÃO PODE** exportar relatórios

#### 6. Francisco
- **Email**: `francisco@exemplo.com`
- **Password**: `Senha@123456`
- **Permissões**: Iguais ao Leonardo

---

## 🧪 TESTES RECOMENDADOS

### Teste 1: Admin Completo
1. Login como **henrique@exemplo.com**
2. Ir para **Perfil** → Deve ver botão "🛡️ Gestão de Utilizadores"
3. Clicar em "Gestão de Utilizadores"
4. Alterar role do Leonardo de `user` para `tecnico`
5. Verificar que Leonardo agora pode criar incidentes

### Teste 2: Técnico Limitado
1. Login como **goncalo@exemplo.com**
2. Dashboard deve mostrar botão "Novo Incidente"
3. Criar novo incidente → DEVE FUNCIONAR
4. Abrir detalhes de incidente → Pode alterar status/risco
5. Ir para **Perfil** → **NÃO DEVE** ver botão "Gestão de Utilizadores"

### Teste 3: Utilizador Normal (Read-Only)
1. Login como **leonardo@exemplo.com**
2. Dashboard **NÃO DEVE** mostrar botão "Novo Incidente"
3. Abrir detalhes de incidente:
   - **NÃO PODE** alterar status ou risco
   - **PODE** adicionar comentários
4. Ir para **Perfil** → Ver badge "👤 Utilizador Normal"

---

## 🔒 SEGURANÇA

### Hash Argon2id
Todos os passwords estão armazenados com:
- **Algoritmo**: Argon2id (vencedor do Password Hashing Competition)
- **Memória**: 64MB
- **Iterações**: 3
- **Paralelismo**: 4 threads
- **Salt**: `somesalt` (fixo para simplificação)

### Proteção Contra Força Bruta
- Máximo de 5 tentativas de login falhadas
- Bloqueio de 30 segundos após 5 tentativas
- Todas as tentativas são registadas em auditoria

---

## 📝 NOTAS IMPORTANTES

1. **Password Temporária**: A password `Senha@123456` é temporária. Em produção, cada utilizador deveria definir a própria password no primeiro login.

2. **Base de Dados**: Localizada em:
   - **Runtime**: `C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db`
   - **Assets**: `assets/db/gestao_incidentes.db` (cópia inicial)

3. **Re-popular**: Para repopular a base de dados:
   ```bash
   dart run tools/populate_users.dart
   ```

4. **Sincronizar para Assets** (se necessário):
   ```powershell
   Copy-Item "C:\Users\Henrique\OneDrive\Documentos\gestao_incidentes.db" -Destination "assets\db\gestao_incidentes.db" -Force
   ```

---

## ⚠️ TROUBLESHOOTING

### Problema: "Senha incorreta"
**Causa**: Base de dados antiga com hashes incompatíveis  
**Solução**:
```bash
dart run tools/populate_users.dart
```

### Problema: "Formato de hash desconhecido"
**Causa**: Hash não é Argon2id nem BCrypt  
**Solução**: Repopular base de dados (comando acima)

### Problema: "Conta bloqueada"
**Causa**: 5 tentativas de login falhadas  
**Solução**: Aguardar 30 segundos ou reiniciar aplicação

---

## 📊 RESUMO RÁPIDO

| Utilizador | Email | Role | Pode Criar Incidentes? | Pode Alterar Roles? |
|-----------|-------|------|----------------------|-------------------|
| Henrique | henrique@exemplo.com | 👑 admin | ✅ Sim | ✅ Sim |
| Admin | admin@exemplo.com | 👑 admin | ✅ Sim | ✅ Sim |
| Gonçalo | goncalo@exemplo.com | 🔧 tecnico | ✅ Sim | ❌ Não |
| Duarte | duarte@exemplo.com | 🔧 tecnico | ✅ Sim | ❌ Não |
| Leonardo | leonardo@exemplo.com | 👤 user | ❌ Não | ❌ Não |
| Francisco | francisco@exemplo.com | 👤 user | ❌ Não | ❌ Não |

**Password para TODOS**: `Senha@123456`
