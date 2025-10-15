import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/incidente.dart';
import 'detalhes_service.dart';
import 'crypto_service.dart';
import '../utils/secure_logger.dart';

class ExportService {
  /// 📤 Exporta lista de incidentes em CSV (criptografado)
  static Future<File> exportarCSV(List<Incidente> incidentes) async {
    try {
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
      
      // Security: Encrypt CSV data before saving
      final encryptedData = await CryptoService.encrypt(csv);
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/relatorio_incidentes.csv.encrypted');
      
      SecureLogger.audit('export_csv', 'CSV export created with ${incidentes.length} incidents');
      
      return file.writeAsString(encryptedData);
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to export CSV', e, stackTrace);
      rethrow;
    }
  }

  /// 📄 Exporta lista em PDF com detalhes e histórico (criptografado)
  static Future<File> exportarPDF(List<Incidente> incidentes) async {
    try {
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

      final pdfBytes = await pdf.save();
      
      // Security: Encrypt PDF data before saving
      final base64Pdf = String.fromCharCodes(pdfBytes);
      final encryptedData = await CryptoService.encrypt(base64Pdf);
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/relatorio_incidentes.pdf.encrypted');
      
      SecureLogger.audit('export_pdf', 'PDF export created with ${incidentes.length} incidents');
      
      await file.writeAsString(encryptedData);
      return file;
    } catch (e, stackTrace) {
      SecureLogger.error('Failed to export PDF', e, stackTrace);
      rethrow;
    }
  }
}
