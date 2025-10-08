import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/incidente.dart';
import '../services/incidentes_service.dart';
import 'form_incidente_screen.dart';
import 'detalhes_incidente_dialog.dart';
import 'perfil_screen.dart';
import 'tecnicos_screen.dart';
import 'login_screen.dart';
import '../services/export_service.dart';
import 'dashboard_stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Incidente> todos = [];
  List<Incidente> filtrados = [];
  bool loading = true;
  String filtroTexto = '';
  String filtroStatus = '';
  String filtroCategoria = '';
  String filtroRisco = '';

  final statusList = ['Todos', 'Pendente', 'Em Análise', 'Em andamento', 'Resolvido', 'Cancelado'];
  final categoriaList = ['Todas', 'TI', 'RH', 'Infraestrutura'];
  final riscoList = ['Todos', 'Baixo', 'Médio', 'Alto', 'Crítico'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final lista = await IncidentesService.listar();
    setState(() {
      todos = lista;
      filtrados = lista;
      loading = false;
    });
  }

  void _mostrarSnack(String msg, {Color cor = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _filtrar() {
    setState(() {
      filtrados = todos.where((i) {
        final busca = filtroTexto.isEmpty || i.titulo.toLowerCase().contains(filtroTexto.toLowerCase());
        final st = filtroStatus == 'Todos' || filtroStatus.isEmpty || i.status == filtroStatus;
        final cat = filtroCategoria == 'Todas' || filtroCategoria.isEmpty || i.categoria == filtroCategoria;
        final risco = filtroRisco == 'Todos' || filtroRisco.isEmpty || i.grauRisco == filtroRisco;
        return busca && st && cat && risco;
      }).toList();
    });
  }

  void _abrirDetalhes(Incidente inc) async {
    await showDialog(
      context: context,
      builder: (_) => DetalhesIncidenteDialog(incidente: inc, user: widget.user),
    );
    await _carregar();
  }

  void _novoIncidente() async {
    final criado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormIncidenteScreen(user: widget.user)),
    );
    if (criado == true) {
      _mostrarSnack("✅ Novo incidente criado!");
      await _carregar();
    }
  }

  void _abrirPerfil() async {
    final logout = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilScreen(user: widget.user)),
    );
    if (logout == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.tipo == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestão de Incidentes — ${widget.user.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: _abrirPerfil,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver Estatísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardStatsScreen()),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.engineering),
              tooltip: 'Gestão de Técnicos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TecnicosScreen(user: widget.user)),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () async {
              final file = await ExportService.exportarPDF(filtrados);
              _mostrarSnack('📄 PDF exportado para: ${file.path}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final file = await ExportService.exportarCSV(filtrados);
              _mostrarSnack('📊 CSV exportado para: ${file.path}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Novo Incidente',
            onPressed: _novoIncidente,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Pesquisar por título...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            filtroTexto = v;
                            _filtrar();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filtroStatus.isEmpty ? 'Todos' : filtroStatus,
                          items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) {
                            filtroStatus = v ?? '';
                            _filtrar();
                          },
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filtroCategoria.isEmpty ? 'Todas' : filtroCategoria,
                          items: categoriaList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) {
                            filtroCategoria = v ?? '';
                            _filtrar();
                          },
                          decoration: const InputDecoration(labelText: 'Categoria'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filtroRisco.isEmpty ? 'Todos' : filtroRisco,
                          items: riscoList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) {
                            filtroRisco = v ?? '';
                            _filtrar();
                          },
                          decoration: const InputDecoration(labelText: 'Risco'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? const Center(child: Text('Nenhum incidente encontrado.'))
                      : ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (context, i) {
                            final inc = filtrados[i];
                            final cor = {
                              'Pendente': Colors.orange,
                              'Em Análise': Colors.blue,
                              'Em andamento': Colors.teal,
                              'Resolvido': Colors.green,
                              'Cancelado': Colors.grey,
                            }[inc.status]!;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cor,
                                  child: const Icon(Icons.bug_report, color: Colors.white),
                                ),
                                title: Text(inc.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${inc.categoria} | ${inc.status} | ${inc.grauRisco}'),
                                onTap: () => _abrirDetalhes(inc),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
