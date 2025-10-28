import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/incidente.dart';
import '../utils/validation_chains.dart';
import '../viewmodels/form_incidente_view_model.dart';

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
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FormIncidenteViewModel>().carregarTecnicos();
    });

    if (widget.incidente != null) {
      tituloCtrl.text = widget.incidente!.titulo;
      descCtrl.text = widget.incidente!.descricao;
      categoriaSelecionada = widget.incidente!.categoria;
      riscoSelecionado = widget.incidente!.grauRisco;
      tecnicoSelecionado = widget.incidente!.tecnicoId;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<FormIncidenteViewModel>();
    final sucesso = await vm.salvar(
      user: widget.user,
      incidente: widget.incidente,
      titulo: tituloCtrl.text,
      descricao: descCtrl.text,
      categoria: categoriaSelecionada,
      grauRisco: riscoSelecionado,
      tecnicoId: tecnicoSelecionado,
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.pop(context, true);
    } else {
      final msg = vm.error ?? 'Erro ao guardar incidente';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.tipo == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incidente == null ? 'Novo Incidente' : 'Editar Incidente'),
      ),
      body: context.watch<FormIncidenteViewModel>().loading
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
                          ...context.watch<FormIncidenteViewModel>().tecnicos.map((t) => DropdownMenuItem<int?>(
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
