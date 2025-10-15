import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  bool loading = false;
  String? erro;

  Future<void> _doLogin() async {
    setState(() => erro = null);
    setState(() => loading = true);

    final user = await AuthService.login(emailCtrl.text.trim(), senhaCtrl.text);
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    } else {
      setState(() => erro = 'Credenciais inválidas.');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gestão de Incidentes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
              const SizedBox(height: 16),
              if (erro != null) Text(erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : _doLogin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _mostrarDialogCriarConta,
                child: const Text('Criar nova conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogCriarConta() {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    final confirmarSenhaCtrl = TextEditingController();
    String? erro;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Criar Nova Conta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: senhaCtrl,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              TextField(
                controller: confirmarSenhaCtrl,
                decoration: const InputDecoration(labelText: 'Confirmar Senha'),
                obscureText: true,
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(erro!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validações
                if (nomeCtrl.text.trim().isEmpty) {
                  setState(() => erro = 'Nome é obrigatório');
                  return;
                }
                if (emailCtrl.text.trim().isEmpty) {
                  setState(() => erro = 'Email é obrigatório');
                  return;
                }
                if (senhaCtrl.text.length < 6) {
                  setState(() => erro = 'Senha deve ter no mínimo 6 caracteres');
                  return;
                }
                if (senhaCtrl.text != confirmarSenhaCtrl.text) {
                  setState(() => erro = 'Senhas não conferem');
                  return;
                }

                try {
                  await AuthService.criarUsuario(
                    nomeCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    senhaCtrl.text,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Conta criada com sucesso! Faça login para continuar.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  setState(() => erro = e.toString());
                }
              },
              child: const Text('Criar Conta'),
            ),
          ],
        ),
      ),
    );
  }
}
