import '../models/user.dart';
import '../services/auth_service.dart';
import 'base_view_model.dart';

class LoginViewModel extends BaseViewModel {
  Future<User?> login(String email, String senha) async {
    try {
      clearError();
      setLoading(true);
      final user = await AuthService.login(email, senha);
      if (user == null) {
        setError('Credenciais inválidas.');
      }
      return user;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createAccount({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      clearError();
      setLoading(true);
      await AuthService.criarUsuario(nome, email, senha);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }
}
