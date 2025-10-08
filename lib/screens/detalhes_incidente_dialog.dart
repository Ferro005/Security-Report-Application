import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../models/user.dart';
import '../services/detalhes_service.dart';

class DetalhesIncidenteDialog extends StatefulWidget {
  final Incidente incidente;
  final User user;
  const DetalhesIncidenteDialog({super.key, required this.incidente, required this.user});

  @override
  State<DetalhesIncidenteDialog> createState() => _DetalhesIncidenteDialogState();
}

class _DetalhesIncidenteDialogState extends State<DetalhesIncidenteDialog> {
  List<Map<String, dynamic>> comentarios = [];
  List<Map<String, dynamic>> historico = [];
  final comentarioCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    comentarios = await DetalhesService.listarComentarios(widget.incidente.id);
    historico = await DetalhesService.listarHistorico(widget.incidente.id);
    setState(() => loading = false);
  }

  Future<void> _adicionarComentario() async {
    if (comentarioCtrl.text.trim().isEmpty) return;
    await DetalhesService.adicionarComentario(
      incidenteId: widget.incidente.id,
      usuarioId: widget.user.id,
      comentario: comentarioCtrl.text.trim(),
    );
    comentarioCtrl.clear();
    await _carregarDados();
  }

  Future<void> _atualizarStatus(String novoStatus) async {
    await DetalhesService.atualizarStatus(
      incidenteId: widget.incidente.id,
      novoStatus: novoStatus,
      alteradoPor: widget.user.id,
    );
    await _carregarDados();
  }

  Future<void> _atualizarRisco(String novoRisco) async {
    await DetalhesService.atualizarRisco(
      incidenteId: widget.incidente.id,
      novoRisco: novoRisco,
    );
    await _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.tipo == 'admin';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.incidente.titulo,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${widget.incidente.categoria} | ${widget.incidente.status} | ${widget.incidente.grauRisco}',
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 20),

                  // 🧭 Se for admin, pode mudar status/risco
                  if (isAdmin) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: widget.incidente.status,
                          items: ['Pendente', 'Em Análise', 'Em andamento', 'Resolvido', 'Cancelado']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _atualizarStatus(v);
                          },
                        ),
                        DropdownButton<String>(
                          value: widget.incidente.grauRisco,
                          items: ['Baixo', 'Médio', 'Alto', 'Crítico']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _atualizarRisco(v);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                  ],

                  // 💬 Comentários
                  Expanded(
                    child: ListView(
                      children: [
                        const Text('💬 Comentários', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        for (var c in comentarios)
                          ListTile(
                            title: Text(c['comentario'] ?? ''),
                            subtitle: Text('${c['autor']} • ${c['data_comentario']}'),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: comentarioCtrl,
                          decoration: InputDecoration(
                            hintText: 'Escreve um comentário...',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _adicionarComentario,
                            ),
                          ),
                        ),
                        const Divider(height: 30),
                        const Text('📜 Histórico de Status',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        for (var h in historico)
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 10, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h['status'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${h['alterado_por_nome'] ?? '—'} • ${h['data_alteracao']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
