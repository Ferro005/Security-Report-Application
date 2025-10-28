import 'base_view_model.dart';
import '../models/user.dart';
import '../models/incidente.dart';
import '../services/incidentes_service.dart';
import '../services/tecnicos_service.dart';
import '../utils/validation_chains.dart';

class FormIncidenteViewModel extends BaseViewModel {
  List<Map<String, dynamic>> _tecnicos = [];
  List<Map<String, dynamic>> get tecnicos => _tecnicos;

  Future<void> carregarTecnicos() async {
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

  Future<bool> salvar({
    required User user,
    Incidente? incidente,
    required String titulo,
    required String descricao,
    required String categoria,
    required String grauRisco,
    int? tecnicoId,
  }) async {
    try {
      setLoading(true);

    // Reusar mesma sanitização de descrição também para o título (consistente com a tela atual)
    final tituloSan =
      ValidationChains.incidentDescriptionSanitization.sanitize(titulo) ?? '';
      final descricaoSan = ValidationChains
              .incidentDescriptionSanitization
              .sanitize(descricao) ??
          '';

      final dados = {
        'titulo': tituloSan,
        'descricao': descricaoSan,
        'categoria': categoria,
        'grau_risco': grauRisco,
        'status': incidente?.status ?? 'Pendente',
        'usuario_id': user.id,
        'tecnico_responsavel': tecnicoId,
        'data_reportado': DateTime.now().toIso8601String(),
      };

      bool sucesso;
      if (incidente == null) {
        sucesso = await IncidentesService.criar(dados);
      } else {
        sucesso = await IncidentesService.atualizar(incidente.id, dados);
      }
      return sucesso;
    } catch (e) {
      setError('Erro ao guardar incidente: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
