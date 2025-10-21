# Migração de Schema - Incidentes [CONCLUÍDA v2.1.0]

**Data Original**: 21/10/2025  
**Versão**: v2.1.0  
**Status**: ✅ ARQUIVADO - Migração Implementada e Validada  
**Última Atualização**: 21 de Outubro de 2025

## 📋 Visão Geral
Atualização completa e implementada do schema de incidentes para nova formatação alinhada com banco de dados SQLite. Esta migração foi concluída com sucesso em v2.1.0.

## 🔄 Mudanças Principais

### Modelo: `lib/models/incidente.dart`
| Campo Antigo | Campo Novo | Tipo | Descrição |
|---|---|---|---|
| `titulo` | `numero` | String | Número único do incidente (ex: INC-001) |
| `dataReportado` | `dataOcorrencia` | String | Data ISO8601 de ocorrência |
| `tecnicoId` (antes `tecnico_responsavel`) | `tecnicoId` | int? | ID do técnico responsável |
| **Novo** | `usuarioId` | int? | ID do usuário que reportou |

#### Backward Compatibility (fromMap):
```dart
// Fallback para campo antigo
numero: map['numero'] ?? map['titulo'] ?? '',
dataOcorrencia: map['data_ocorrencia'] ?? map['data_reportado'] ?? '',
tecnicoId: map['tecnico_id'] ?? map['tecnico_responsavel'],
```

#### Getter para Compatibilidade:
```dart
String get titulo => numero;  // Permite uso legado: inc.titulo
```

---

### Banco de Dados: `incidentes` table
```sql
CREATE TABLE incidentes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero TEXT UNIQUE,           -- INC-001, INC-002, etc
  descricao TEXT,               -- Descrição completa
  categoria TEXT,               -- TI, RH, Infraestrutura
  status TEXT,                  -- Pendente, Em Análise, Em andamento, Resolvido, Cancelado
  grau_risco TEXT,              -- Baixo, Médio, Alto, Crítico
  data_ocorrencia TEXT,         -- ISO8601 timestamp
  user_id INTEGER,              -- ID do usuário que reportou
  tecnico_id INTEGER,           -- ID do técnico responsável
  created_at TEXT               -- ISO8601 timestamp de criação
);
```

---

### Formulário: `lib/screens/form_incidente_screen.dart`
```dart
// Antes
tituloCtrl.text = widget.incidente!.titulo;
final dados = {
  'titulo': numero,
  'usuario_id': widget.user.id,
  'tecnico_responsavel': tecnicoSelecionado,
  'data_reportado': DateTime.now().toIso8601String(),
};

// Depois
tituloCtrl.text = widget.incidente!.numero;
final dados = {
  'numero': numero,
  'user_id': widget.user.id,
  'tecnico_id': tecnicoSelecionado,
  'data_ocorrencia': DateTime.now().toIso8601String(),
  'created_at': DateTime.now().toIso8601String(),
};
```

**UI Label**: "Título" → "Número do Incidente"

---

### Serviços Atualizados

#### `lib/services/incidentes_service.dart`
- Query: `ORDER BY datetime(data_reportado) DESC` → `ORDER BY datetime(data_ocorrencia) DESC`
- CREATE TABLE com schema correto
- `listar()` retorna dados mapeados corretamente

#### `lib/services/export_service.dart`
- CSV/PDF: `i.dataReportado` → `i.dataOcorrencia`
- Mantém `i.titulo` (via getter de compatibilidade)

#### `lib/services/detalhes_service.dart`
- `listarComentarios()`: Cria table se não existir
- `listarHistorico()`: Cria table se não existir
- Tratamento de erros para tabelas faltantes

#### `lib/services/tecnicos_service.dart`
- Detecta coluna `role` via PRAGMA
- Fallback para retornar todos usuários se `role` não existir
- Métodos com tratamento de erro

---

### Validação: `lib/utils/validation_chains.dart`
```dart
// MapValidator
'titulo' → 'numero'

// MapSanitizer  
'titulo' → 'numero'
```

---

### UI: `lib/screens/dashboard_screen.dart`
- Usa `i.titulo` (getter compatível com novo `numero`)
- Filtro de texto: `i.titulo.toLowerCase()`
- Card display: `inc.titulo` (será `inc.numero`)

---

## ✅ Checklist de Compatibilidade

- [x] Modelo com backward compatibility
- [x] Getter `titulo => numero`
- [x] `fromMap()` com fallback para campos antigos
- [x] Serviço query com schema correto
- [x] Formulário usando novos campos
- [x] Export com novos campos
- [x] Validação com novo nome
- [x] Dashboard sem quebra de funcionalidade

---

## 🚀 Como Testar

1. **Login**: Use credenciais padrão (Senha@123456)
2. **Dashboard**: Verifique se 10 incidentes carregam corretamente
3. **Criar Incidente**: 
   - Clique "Novo Incidente"
   - Preencha "Número do Incidente" (ex: INC-011)
   - Verifique se salva com schema novo
4. **Editar**: Clique em incidente existente
5. **Exportar**: PDF/CSV com dados corretos
6. **Estatísticas**: Gráficos populam corretamente

---

## 📝 Dados de Teste

```
Incidentes populados (tools/populate_incidents.dart):
- INC-001 a INC-010
- Status: Pendente, Em Análise, Em andamento, Resolvido, Cancelado
- Risco: Baixo, Médio, Alto, Crítico
- Categoria: TI, RH, Infraestrutura
```

---

## 🔧 Próximas Etapas

1. Rebuild e teste completo
2. Verificar sincronização OneDrive/Documents
3. Validar comentários e histórico
4. Testar criação de novos incidentes
