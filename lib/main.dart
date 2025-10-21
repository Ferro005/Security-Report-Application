import 'dart:io';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/security_service.dart';
import 'services/windows_secure_window.dart';
import 'package:window_manager/window_manager.dart';
import 'services/auditoria_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o window_manager para Windows
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow();
  }
  
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SecurityService.initSecurity(context);
      // Iniciar limpeza automática de auditoria (semanal por padrão)
      AuditoriaService.startAutoCleanup();
    });
  }

  @override
  void dispose() {
    SecurityService.dispose();
    if (Platform.isWindows) {
      WindowsSecureWindow.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Incidentes',
      theme: AppTheme.theme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
