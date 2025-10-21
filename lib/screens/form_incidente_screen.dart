import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/incidente.dart';
import '../services/incidentes_service.dart';
import '../services/tecnicos_service.dart';
import '../utils/validation_chains.dart';

class FormIncidenteScreen extends StatefulWidget {
  final User user;
  final Incidente? incidente;

  const FormIncidenteScreen({super.key, required this.user, this.incidente});

  @override
  State<FormIncidenteScreen> createState() => _FormIncidenteScreenState();
}

class _FormIncidenteScreenState extends State<FormIncidenteScreen> {
  final _formKey = GlobalKey<FormState>();

  final tituloCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String categoriaSelecionada = 'TI';
  String riscoSelecionado = 'Baixo';
  int? tecnicoSelecionado;

  List<Map<String, dynamic>> tecnicos = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _carregarTecnicos();

    if (widget.incidente != null) {
      tituloCtrl.text = widget.incidente!.titulo;
      descCtrl.text = widget.incidente!.descricao;
      categoriaSelecionada = widget.incidente!.categoria;
      riscoSelecionado = widget.incidente!.grauRisco;
      tecnicoSelecionado = widget.incidente!.tecnicoId;
    }
  }

  Future<void> _carregarTecnicos() async {
    final lista = await TecnicosService.listar();
    setState(() => tecnicos = lista);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // Sanitizar dados antes de enviar
      final titulo = ValidationChains.incidentDescriptionSanitization.sanitize(tituloCtrl.text) ?? '';
      final descricao = ValidationChains.incidentDescriptionSanitization.sanitize(descCtrl.text) ?? '';

      final dados = {
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoriaSelecionada,
        'grau_risco': riscoSelecionado,
        'status': widget.incidente?.status ?? 'Pendente',
        'usuario_id': widget.user.id,
        'tecnico_responsavel': tecnicoSelecionado,
        'data_reportado': DateTime.now().toIso8601String(),
      };

      bool sucesso;
      if (widget.incidente == null) {
        sucesso = await IncidentesService.criar(dados);
      } else {
        sucesso = await IncidentesService.atualizar(widget.incidente!.id, dados);
      }

      if (!mounted) return;
      Navigator.pop(context, sucesso);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar incidente: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.tipo == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incidente == null ? 'Novo Incidente' : 'Editar Incidente'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: ValidationChains.incidentTitleValidation.validate,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      validator: ValidationChains.incidentDescriptionValidation.validate,
                      maxLength: 1000,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: categoriaSelecionada,
                      items: ['TI', 'RH', 'Infraestrutura']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => categoriaSelecionada = v ?? 'TI'),
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: riscoSelecionado,
                      items: ['Baixo', 'Médio', 'Alto', 'Crítico']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => riscoSelecionado = v ?? 'Baixo'),
                      decoration: const InputDecoration(labelText: 'Grau de Risco'),
                    ),
                    const SizedBox(height: 10),
                    if (isAdmin)
                      DropdownButtonFormField<int?>(
                        initialValue: tecnicoSelecionado,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('— Nenhum técnico —')),
                          ...tecnicos.map((t) => DropdownMenuItem<int?>(
                                value: t['id'] as int?,
                                child: Text(t['nome'].toString()),
                              )),
                        ],
                        onChanged: (v) => setState(() => tecnicoSelecionado = v),
                        decoration: const InputDecoration(labelText: 'Técnico Responsável'),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: _salvar,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
