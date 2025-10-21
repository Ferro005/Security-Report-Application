import 'package:flutter/material.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'gestao_users_screen.dart';

class PerfilScreen extends StatelessWidget {
  final User user;
  const PerfilScreen({super.key, required this.user});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.tipo == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Utilizador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _getRoleColor(user.tipo),
                      child: Text(
                        user.nome.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.nome,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Chip(
                      avatar: Icon(
                        Icons.badge,
                        color: _getRoleColor(user.tipo),
                      ),
                      label: Text(
                        _getRoleDisplayName(user.tipo),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getRoleColor(user.tipo).withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Admin-only: User Management Button
            if (isAdmin) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GestaoUsersScreen(adminUser: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('🛡️ Gestão de Utilizadores'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Spacer(),

            // Logout Button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Terminar Sessão'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _logout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
