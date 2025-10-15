import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_management_service.dart';

class GestaoUsersScreen extends StatefulWidget {
  final User adminUser;
  
  const GestaoUsersScreen({super.key, required this.adminUser});

  @override
  State<GestaoUsersScreen> createState() => _GestaoUsersScreenState();
}

class _GestaoUsersScreenState extends State<GestaoUsersScreen> {
  List<Map<String, dynamic>> users = [];
  Map<String, int> stats = {};
  bool loading = true;
  String filtroRole = 'Todos';

  final roleList = ['Todos', 'admin', 'tecnico', 'user'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    try {
      final allUsers = await UserManagementService.listarTodosUsuarios();
      final statistics = await UserManagementService.getStatisticsByRole();
      
      setState(() {
        users = allUsers;
        stats = statistics;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _mostrarErro('Erro ao carregar utilizadores: $e');
    }
  }

  void _mostrarSnack(String msg, {Color cor = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarErro(String msg) => _mostrarSnack(msg, cor: Colors.red);

  Future<void> _alterarRole(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final currentRole = user['tipo'] as String;
    final userName = user['nome'] as String;

    // Prevent changing own role
    if (userId == widget.adminUser.id) {
      _mostrarErro('Não pode alterar o seu próprio role');
      return;
    }

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar Role de $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role atual: $currentRole'),
            const SizedBox(height: 16),
            const Text('Escolha novo role:'),
            const SizedBox(height: 8),
            ...['admin', 'tecnico', 'user'].map((role) {
              return RadioListTile<String>(
                title: Text(_getRoleDisplayName(role)),
                value: role,
                groupValue: currentRole,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != currentRole) {
      try {
        final success = await UserManagementService.atualizarRole(
          widget.adminUser.id,
          userId,
          newRole,
        );

        if (success) {
          _mostrarSnack('✅ Role de $userName alterado para ${_getRoleDisplayName(newRole)}');
          await _carregar();
        } else {
          _mostrarErro('Falha ao alterar role');
        }
      } catch (e) {
        _mostrarErro('Erro: $e');
      }
    }
  }

  Future<void> _confirmarEliminacao(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final userName = user['nome'] as String;

    // Prevent deleting own account
    if (userId == widget.adminUser.id) {
      _mostrarErro('Não pode eliminar a sua própria conta');
      return;
    }

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Utilizador'),
        content: Text(
          'Tem a certeza que deseja eliminar "$userName"?\n\n'
          'Esta ação é irreversível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        final success = await UserManagementService.deletarUsuario(
          widget.adminUser.id,
          userId,
        );

        if (success) {
          _mostrarSnack('🗑️ Utilizador $userName eliminado');
          await _carregar();
        } else {
          _mostrarErro('Falha ao eliminar utilizador');
        }
      } catch (e) {
        _mostrarErro('Erro: $e');
      }
    }
  }

  String _getRoleDisplayName(String role) {
    return {
      'admin': '👑 Administrador',
      'tecnico': '🔧 Técnico',
      'user': '👤 Utilizador Normal',
    }[role] ?? role;
  }

  Color _getRoleColor(String role) {
    return {
      'admin': Colors.red,
      'tecnico': Colors.blue,
      'user': Colors.green,
    }[role] ?? Colors.grey;
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (filtroRole == 'Todos') {
      return users;
    }
    return users.where((u) => u['tipo'] == filtroRole).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Gestão de Utilizadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip(
                          '👑 Admins',
                          stats['admin'] ?? 0,
                          Colors.red,
                        ),
                        _buildStatChip(
                          '🔧 Técnicos',
                          stats['tecnico'] ?? 0,
                          Colors.blue,
                        ),
                        _buildStatChip(
                          '👤 Utilizadores',
                          stats['user'] ?? 0,
                          Colors.green,
                        ),
                        _buildStatChip(
                          '📊 Total',
                          users.length,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: filtroRole,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Role',
                      prefixIcon: Icon(Icons.filter_list),
                      border: OutlineInputBorder(),
                    ),
                    items: roleList.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role == 'Todos' ? 'Todos' : _getRoleDisplayName(role)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => filtroRole = value ?? 'Todos');
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Users List
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(
                          child: Text('Nenhum utilizador encontrado'),
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final userId = user['id'] as int;
                            final userName = user['nome'] as String;
                            final userEmail = user['email'] as String;
                            final userRole = user['tipo'] as String;
                            final isCurrentUser = userId == widget.adminUser.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(userRole),
                                  child: Text(
                                    userName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      const Chip(
                                        label: Text(
                                          'Você',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: Colors.amber,
                                        padding: EdgeInsets.all(2),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📧 $userEmail'),
                                    const SizedBox(height: 4),
                                    Chip(
                                      label: Text(
                                        _getRoleDisplayName(userRole),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: _getRoleColor(userRole),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                                trailing: isCurrentUser
                                    ? null
                                    : PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'role') {
                                            _alterarRole(user);
                                          } else if (action == 'delete') {
                                            _confirmarEliminacao(user);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'role',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Alterar Role'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Eliminar',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
