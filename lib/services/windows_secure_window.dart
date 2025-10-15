import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';

class WindowsSecureWindow {
  static bool _initialized = false;
  static int _hwnd = 0;
  static const int WDA_NONE = 0x00000000;
  static const int WDA_MONITOR = 0x00000001;
  static const int WDA_EXCLUDEFROMCAPTURE = 0x00000011;

  /// Inicializa a proteção da janela
  static void initialize(int hwnd) {
    if (_initialized) return;
    _hwnd = hwnd;
    _initialized = true;
    enableProtection();
  }

  /// Ativa a proteção da janela contra capturas de tela
  static void enableProtection() {
    if (!_initialized) return;
    try {
      final result = SetWindowDisplayAffinity(_hwnd, WDA_EXCLUDEFROMCAPTURE);
      if (result == 0) {
        debugPrint('Falha ao ativar proteção da janela: ${GetLastError()}');
      } else {
        debugPrint('Proteção da janela ativada com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao ativar proteção da janela: $e');
    }
  }

  /// Desativa a proteção da janela contra capturas de tela
  static void disableProtection() {
    if (!_initialized) return;
    try {
      final result = SetWindowDisplayAffinity(_hwnd, WDA_NONE);
      if (result == 0) {
        debugPrint('Falha ao desativar proteção da janela: ${GetLastError()}');
      } else {
        debugPrint('Proteção da janela desativada com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao desativar proteção da janela: $e');
    }
  }

  /// Limpa os recursos da janela
  static void dispose() {
    if (_initialized) {
      disableProtection();
      _initialized = false;
      _hwnd = 0;
    }
  }
}