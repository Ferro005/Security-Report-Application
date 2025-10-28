import 'base_view_model.dart';
import '../services/tecnicos_service.dart';

class TecnicosViewModel extends BaseViewModel {
  List<Map<String, dynamic>> _tecnicos = [];
  List<Map<String, dynamic>> get tecnicos => _tecnicos;

  Future<void> carregar() async {
    try {
      setLoading(true);
      _tecnicos = await TecnicosService.listar();
      notifyListeners();
    } catch (e) {
      setError('Erro ao carregar técnicos: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> pesquisar(String termo) async {
    try {
      if (termo.isEmpty) {
        await carregar();
      } else {
        setLoading(true);
        _tecnicos = await TecnicosService.pesquisar(termo);
        notifyListeners();
      }
    } catch (e) {
      setError('Erro na pesquisa: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> adicionar(String nome) async {
    try {
      setLoading(true);
      await TecnicosService.adicionar(nome);
      await carregar();
    } catch (e) {
      setError('Erro ao adicionar técnico: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> atualizar(int id, String nome) async {
    try {
      setLoading(true);
      await TecnicosService.atualizar(id, nome);
      await carregar();
    } catch (e) {
      setError('Erro ao editar técnico: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> apagar(int id) async {
    try {
      setLoading(true);
      await TecnicosService.apagar(id);
      await carregar();
    } catch (e) {
      setError('Erro ao apagar técnico: $e');
    } finally {
      setLoading(false);
    }
  }
}
