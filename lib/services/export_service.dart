import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/incidente.dart';
import 'detalhes_service.dart';

class ExportService {
  /// 📤 Exporta lista de incidentes em CSV
  static Future<File> exportarCSV(List<Incidente> incidentes) async {
    final rows = [
      ['ID', 'Título', 'Categoria', 'Status', 'Risco', 'Data']
    ];

    for (final i in incidentes) {
      rows.add([
        i.id.toString(),
        i.titulo.toString(),
        i.categoria.toString(),
        i.status.toString(),
        i.grauRisco.toString(),
        i.dataReportado.toString(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/relatorio_incidentes.csv');
    return file.writeAsString(csv);
  }

  /// 📄 Exporta lista em PDF com detalhes e histórico
  static Future<File> exportarPDF(List<Incidente> incidentes) async {
    final pdf = pw.Document();

    for (final i in incidentes) {
      final historico = await DetalhesService.listarHistorico(i.id);
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(i.titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Categoria: ${i.categoria} | Status: ${i.status} | Risco: ${i.grauRisco}'),
              pw.Text('Data: ${i.dataReportado}\n'),
              pw.Text('Histórico de Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...historico.map((h) => pw.Text('- ${h['status']} (${h['data_alteracao']})')),
              pw.Divider(),
            ],
          ),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/relatorio_incidentes.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
