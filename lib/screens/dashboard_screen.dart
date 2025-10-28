import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/incidente.dart';
import 'form_incidente_screen.dart';
import 'detalhes_incidente_dialog.dart';
import 'perfil_screen.dart';
import 'tecnicos_screen.dart';
import 'login_screen.dart';
import '../services/export_service.dart';
import 'dashboard_stats_screen.dart';
import 'notifications_panel.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_view_model.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final statusList = ['Todos', 'Pendente', 'Em Análise', 'Em andamento', 'Resolvido', 'Cancelado'];
  final categoriaList = ['Todas', 'TI', 'RH', 'Infraestrutura'];
  final riscoList = ['Todos', 'Baixo', 'Médio', 'Alto', 'Crítico'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<DashboardViewModel>();
      await vm.carregar();
      await vm.refreshUnread(widget.user.id);
    });
  }

  Future<void> _carregar() async {
    await context.read<DashboardViewModel>().carregar();
  }

  Future<void> _loadUnread() async {
    await context.read<DashboardViewModel>().refreshUnread(widget.user.id);
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NotificationsPanel(userId: widget.user.id),
    );
    await _loadUnread();
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

  // Filtering handled by DashboardViewModel

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
    final vm = context.watch<DashboardViewModel>();
    final role = widget.user.tipo.trim().toLowerCase();
    final isAdmin = role == 'admin' || role == 'administrador' || role == 'administrator';
    final isTecnico = role == 'tecnico' || role == 'técnico' || role == 'technician';
    final canManageIncidents = isAdmin || isTecnico;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestão de Incidentes — ${widget.user.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: _abrirPerfil,
          ),
          // Notificações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notificações',
                  onPressed: _openNotifications,
                ),
                if (vm.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        vm.unreadCount > 99 ? '99+' : '${vm.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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
              final file = await ExportService.exportarPDF(vm.incidentes);
              _mostrarSnack('📄 PDF exportado para: ${file.path}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final file = await ExportService.exportarCSV(vm.incidentes);
              _mostrarSnack('📊 CSV exportado para: ${file.path}');
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar PDF Descriptografado',
              onPressed: () async {
                final file = await ExportService.exportarPDFDescriptografado(vm.incidentes);
                _mostrarSnack('📄 PDF descriptografado exportado para: ${file.path}');
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.table_chart_outlined),
              tooltip: 'Exportar CSV Descriptografado',
              onPressed: () async {
                final file = await ExportService.exportarCSVDescriptografado(vm.incidentes);
                _mostrarSnack('📊 CSV descriptografado exportado para: ${file.path}');
              },
            ),
          // Only admins and technicians can create new incidents
          if (canManageIncidents)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Novo Incidente',
              onPressed: _novoIncidente,
            ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            tooltip: 'Desligar Aplicação',
            onPressed: () async {
              final confirmacao = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Desligar Aplicação'),
                  content: const Text('Tem a certeza que deseja fechar a aplicação?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Desligar'),
                    ),
                  ],
                ),
              );
              if (confirmacao == true) {
                exit(0);
              }
            },
          ),
        ],
      ),
    body: vm.loading
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
                          onChanged: (v) => context.read<DashboardViewModel>().setFiltroTexto(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: vm.filtroStatus,
                          items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => context.read<DashboardViewModel>().setFiltroStatus(v ?? ''),
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: vm.filtroCategoria,
                          items: categoriaList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => context.read<DashboardViewModel>().setFiltroCategoria(v ?? ''),
                          decoration: const InputDecoration(labelText: 'Categoria'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: vm.filtroRisco,
                          items: riscoList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => context.read<DashboardViewModel>().setFiltroRisco(v ?? ''),
                          decoration: const InputDecoration(labelText: 'Risco'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: vm.incidentes.isEmpty
                      ? const Center(child: Text('Nenhum incidente encontrado.'))
                      : ListView.builder(
                          itemCount: vm.incidentes.length,
                          itemBuilder: (context, i) {
                            final inc = vm.incidentes[i];
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
