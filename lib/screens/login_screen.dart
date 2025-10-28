import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/validation_chains.dart';
import 'dashboard_screen.dart';
import '../viewmodels/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<LoginViewModel>();
    vm.clearError();
    // Sanitizar inputs antes de enviar
    final email = ValidationChains.emailSanitization.sanitize(emailCtrl.text) ?? '';
    final senha = senhaCtrl.text;

    final user = await vm.login(email, senha);
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
      );
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gestão de Incidentes', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationChains.emailValidation.validate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: senhaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: ValidationChains.passwordValidation.validate,
                ),
                const SizedBox(height: 16),
                Consumer<LoginViewModel>(
                  builder: (context, vm, _) => vm.error != null
                      ? Text(vm.error!, style: const TextStyle(color: Colors.red))
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: context.watch<LoginViewModel>().loading ? null : _doLogin,
                  child: context.watch<LoginViewModel>().loading
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
      ),
    );
  }

  void _mostrarDialogCriarConta() {
    final formKey = GlobalKey<FormState>();
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    final confirmarSenhaCtrl = TextEditingController();
  String? dialogErro;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Criar Nova Conta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: ValidationChains.nameValidation.validate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationChains.emailValidation.validate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senhaCtrl,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: ValidationChains.passwordValidation.validate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmarSenhaCtrl,
                  decoration: const InputDecoration(labelText: 'Confirmar Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value != senhaCtrl.text) {
                      return 'Senhas não conferem';
                    }
                    return null;
                  },
                ),
                if (dialogErro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(dialogErro!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validar com ValidationChains
                if (!formKey.currentState!.validate()) {
                  return;
                }

                try {
                  // Sanitizar dados antes de criar
                  final nome = ValidationChains.nameSanitization.sanitize(nomeCtrl.text) ?? '';
                  final email = ValidationChains.emailSanitization.sanitize(emailCtrl.text) ?? '';
                  final senha = senhaCtrl.text;
                  final vm = context.read<LoginViewModel>();
                  final ok = await vm.createAccount(nome: nome, email: email, senha: senha);
                  if (!ok) {
                    setState(() => dialogErro = vm.error);
                    return;
                  }
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Conta criada com sucesso! Faça login para continuar.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  setState(() => dialogErro = e.toString());
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
