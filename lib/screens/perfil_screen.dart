import 'package:flutter/material.dart';
import '../models/user.dart';
import 'login_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Utilizador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Nome: ${user.nome}', style: const TextStyle(fontSize: 18)),
            Text('📧 Email: ${user.email}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Terminar Sessão'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
