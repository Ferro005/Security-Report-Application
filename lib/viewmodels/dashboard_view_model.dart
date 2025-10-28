import 'package:flutter/foundation.dart';
import '../models/incidente.dart';
import '../services/incidentes_service.dart';
import '../services/notifications_service.dart';
import 'base_view_model.dart';

class DashboardViewModel extends BaseViewModel {
  List<Incidente> _todos = [];
  List<Incidente> _filtrados = [];
  String _filtroTexto = '';
  String _filtroStatus = '';
  String _filtroCategoria = '';
  String _filtroRisco = '';
  int _unreadCount = 0;

  List<Incidente> get incidentes => _filtrados;
  int get unreadCount => _unreadCount;
  String get filtroStatus => _filtroStatus.isEmpty ? 'Todos' : _filtroStatus;
  String get filtroCategoria => _filtroCategoria.isEmpty ? 'Todas' : _filtroCategoria;
  String get filtroRisco => _filtroRisco.isEmpty ? 'Todos' : _filtroRisco;

  // Filters API
  void setFiltroTexto(String v) {
    _filtroTexto = v;
    _aplicarFiltro();
  }

  void setFiltroStatus(String v) {
    _filtroStatus = v;
    _aplicarFiltro();
  }

  void setFiltroCategoria(String v) {
    _filtroCategoria = v;
    _aplicarFiltro();
  }

  void setFiltroRisco(String v) {
    _filtroRisco = v;
    _aplicarFiltro();
  }

  Future<void> carregar() async {
    try {
      setLoading(true);
      final lista = await IncidentesService.listar();
      _todos = lista;
      _filtrados = lista;
      notifyListeners();
    } catch (e) {
      setError('Erro ao carregar incidentes: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> refreshUnread(int userId) async {
    try {
      final count = await NotificationsService.countUnreadNotifications(userId);
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (e) {
      // do not set global error for badge failures; keep silent
      if (kDebugMode) {
        // ignore
      }
    }
  }

  void _aplicarFiltro() {
    _filtrados = _todos.where((i) {
      final busca = _filtroTexto.isEmpty || i.titulo.toLowerCase().contains(_filtroTexto.toLowerCase());
      final st = _filtroStatus == 'Todos' || _filtroStatus.isEmpty || i.status == _filtroStatus;
      final cat = _filtroCategoria == 'Todas' || _filtroCategoria.isEmpty || i.categoria == _filtroCategoria;
      final risco = _filtroRisco == 'Todos' || _filtroRisco.isEmpty || i.grauRisco == _filtroRisco;
      return busca && st && cat && risco;
    }).toList();
    notifyListeners();
  }
}
