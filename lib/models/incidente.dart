class Incidente {
  final int id;
  final String titulo;
  final String descricao;
  final String categoria;
  final String status;
  final String grauRisco;
  final String dataReportado;
  final int? tecnicoId; // ✅ adicionada
  final int? usuarioId; // ✅ opcional: quem criou o incidente

  Incidente({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.status,
    required this.grauRisco,
    required this.dataReportado,
    this.tecnicoId,
    this.usuarioId,
  });

  factory Incidente.fromMap(Map<String, dynamic> map) {
    return Incidente(
      id: map['id'] ?? 0,
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      categoria: map['categoria'] ?? '',
      status: map['status'] ?? '',
      grauRisco: map['grau_risco'] ?? '',
      dataReportado: map['data_reportado'] ?? '',
      tecnicoId: map['tecnico_responsavel'], // ✅ campo MySQL
      usuarioId: map['usuario_id'], // ✅ opcional
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'status': status,
      'grau_risco': grauRisco,
      'data_reportado': dataReportado,
      'tecnico_responsavel': tecnicoId,
      'usuario_id': usuarioId,
    };
  }
}
