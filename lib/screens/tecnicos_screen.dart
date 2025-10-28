import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../utils/validation_chains.dart';
import '../viewmodels/tecnicos_view_model.dart';

class TecnicosScreen extends StatefulWidget {
  final User user;
  const TecnicosScreen({super.key, required this.user});

  @override
  State<TecnicosScreen> createState() => _TecnicosScreenState();
}

class _TecnicosScreenState extends State<TecnicosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _pesquisaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TecnicosViewModel>().carregar();
    });
  }

  Future<void> _pesquisar(String termo) async {
    final vm = context.read<TecnicosViewModel>();
    if (termo.isEmpty) {
      await vm.carregar();
    } else {
      await vm.pesquisar(termo);
    }
  }

  Future<void> _adicionar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final nome = ValidationChains.nameSanitization.sanitize(_nomeCtrl.text) ?? '';
    final vm = context.read<TecnicosViewModel>();
    await vm.adicionar(nome);
    if (!mounted) return;
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
      );
    } else {
      _nomeCtrl.clear();
    }
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
      final vm = context.read<TecnicosViewModel>();
      await vm.atualizar(id, sanitized);
      if (!mounted) return;
      if (vm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
        );
      }
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
      final vm = context.read<TecnicosViewModel>();
      await vm.apagar(id);
      if (!mounted) return;
      if (vm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
        );
      }
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
            onPressed: () => context.read<TecnicosViewModel>().carregar(),
          ),
        ],
      ),
      body: context.watch<TecnicosViewModel>().loading
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
                          context.read<TecnicosViewModel>().carregar();
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
                    child: context.watch<TecnicosViewModel>().tecnicos.isEmpty
                        ? const Center(child: Text('Nenhum técnico registado.'))
                        : ListView.builder(
                            itemCount: context.watch<TecnicosViewModel>().tecnicos.length,
                            itemBuilder: (context, i) {
                              final t = context.watch<TecnicosViewModel>().tecnicos[i];
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
