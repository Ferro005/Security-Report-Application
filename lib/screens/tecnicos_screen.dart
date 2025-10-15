import 'package:flutter/material.dart';
import '../services/tecnicos_service.dart';
import '../models/user.dart';
import '../utils/validation_chains.dart';

class TecnicosScreen extends StatefulWidget {
  final User user;
  const TecnicosScreen({super.key, required this.user});

  @override
  State<TecnicosScreen> createState() => _TecnicosScreenState();
}

class _TecnicosScreenState extends State<TecnicosScreen> {
  List<Map<String, dynamic>> tecnicos = [];
  bool loading = true;
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _pesquisaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final lista = await TecnicosService.listar();
    setState(() {
      tecnicos = lista;
      loading = false;
    });
  }

  Future<void> _pesquisar(String termo) async {
    if (termo.isEmpty) {
      _carregar();
    } else {
      final lista = await TecnicosService.pesquisar(termo);
      setState(() => tecnicos = lista);
    }
  }

  Future<void> _adicionar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final nome = ValidationChains.nameSanitization.sanitize(_nomeCtrl.text) ?? '';
    await TecnicosService.adicionar(nome);
    _nomeCtrl.clear();
    _carregar();
  }

  Future<void> _editar(int id, String nomeAtual) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: nomeAtual);
    
    final novoNome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Técnico'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Nome do técnico'),
            validator: ValidationChains.nameValidation.validate,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, ctrl.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (novoNome != null) {
      final sanitized = ValidationChains.nameSanitization.sanitize(novoNome) ?? '';
      await TecnicosService.atualizar(id, sanitized);
      _carregar();
    }
  }

  Future<void> _apagar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Desejas realmente apagar este técnico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );

    if (confirmar == true) {
      await TecnicosService.apagar(id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Técnicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 🔍 Pesquisa
                  TextField(
                    controller: _pesquisaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar técnico',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _pesquisaCtrl.clear();
                          _carregar();
                        },
                      ),
                    ),
                    onChanged: _pesquisar,
                  ),
                  const SizedBox(height: 12),

                  // ➕ Adicionar técnico
                  Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Novo técnico',
                              border: OutlineInputBorder(),
                            ),
                            validator: ValidationChains.nameValidation.validate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                          onPressed: _adicionar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📜 Lista
                  Expanded(
                    child: tecnicos.isEmpty
                        ? const Center(child: Text('Nenhum técnico registado.'))
                        : ListView.builder(
                            itemCount: tecnicos.length,
                            itemBuilder: (context, i) {
                              final t = tecnicos[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.engineering, color: Colors.teal),
                                  title: Text(t['nome']),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _editar(t['id'], t['nome']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _apagar(t['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
