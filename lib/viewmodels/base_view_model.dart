import 'package:flutter/foundation.dart';

/// Base class for ViewModels using ChangeNotifier (MVVM)
class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  @protected
  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
  }

  @protected
  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() => setError(null);
}
