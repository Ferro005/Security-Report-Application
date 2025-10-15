import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:win32/win32.dart';
import 'windows_secure_window.dart';

class SecurityService {
  static Timer? _inactivityTimer;
  static const int _inactivityTimeout = 120; // 2 minutos em segundos
  
  /// Configura todas as medidas de segurança
  static Future<void> initSecurity(BuildContext context) async {
    await _secureScreen();
    _startInactivityTimer(context);
  }

  /// Protege a tela contra screenshots e gravação
  static Future<void> _secureScreen() async {
    try {
      if (!Platform.isWindows) {
        // Bloqueia screenshots e gravação de tela em dispositivos não-Windows
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
      
      // Proteção adicional para Windows
      if (Platform.isWindows) {
        await windowManager.ensureInitialized();
        await windowManager.setPreventClose(true);
        await windowManager.setResizable(false);
        await windowManager.focus();
        await windowManager.center();
        
        // Define o tamanho mínimo e máximo da janela
        await windowManager.setMinimumSize(const ui.Size(1024, 768));
        await windowManager.setMaximumSize(const ui.Size(1920, 1080));
        
        try {
          // Obtém o handle da janela do Flutter
          final hwnd = FindWindowEx(
            HWND_DESKTOP,
            HWND_DESKTOP,
            TEXT('FLUTTER_RUNNER_WIN32_WINDOW'),
            TEXT(''),
          );

          if (hwnd != 0) {
            // Inicializa e ativa a proteção da janela
            WindowsSecureWindow.initialize(hwnd);
          }
        } catch (e) {
          debugPrint('Erro ao configurar proteção de janela: $e');
        }
      }
      
      // Força orientação retrato
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      // Esconde a barra de status e navegação
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    } catch (e) {
      debugPrint('Erro ao configurar segurança da tela: $e');
    }
  }

  /// Inicia o timer de inatividade
  static void _startInactivityTimer(BuildContext context) {
    _resetInactivityTimer(context);

    // Adiciona detector de atividade em toda a aplicação
    GestureBinding.instance.pointerRouter.addGlobalRoute((PointerEvent event) {
      if (event is PointerDownEvent) {
        _resetInactivityTimer(context);
      }
    });
  }

  /// Reseta o timer de inatividade
  static void _resetInactivityTimer(BuildContext context) {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _inactivityTimeout), () {
      // Quando atingir o timeout, volta para a tela de login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  /// Limpa recursos ao fechar a aplicação
  static void dispose() {
    _inactivityTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }
}