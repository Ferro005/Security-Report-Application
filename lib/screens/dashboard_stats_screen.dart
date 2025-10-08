import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/incidente.dart';
import '../services/incidentes_service.dart';

class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  bool loading = true;
  List<Incidente> incidentes = [];
  Map<String, int> porStatus = {};
  Map<String, int> porCategoria = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await IncidentesService.listar();
    final statusCount = <String, int>{};
    final categoriaCount = <String, int>{};

    for (var i in lista) {
      statusCount[i.status] = (statusCount[i.status] ?? 0) + 1;
      categoriaCount[i.categoria] = (categoriaCount[i.categoria] ?? 0) + 1;
    }

    setState(() {
      incidentes = lista;
      porStatus = statusCount;
      porCategoria = categoriaCount;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Estatísticas de Incidentes")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text("Distribuição por Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Expanded(child: _buildPieChart(porStatus)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text("Incidentes por Categoria", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Expanded(child: _buildBarChart(porCategoria)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    if (data.isEmpty) return const Center(child: Text("Sem dados"));

    final colors = [Colors.orange, Colors.blue, Colors.teal, Colors.green, Colors.grey];
    final entries = data.entries.toList();

    return PieChart(
      PieChartData(
        sections: List.generate(entries.length, (i) {
          final e = entries[i];
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: e.value.toDouble(),
            title: "${e.key}\n(${e.value})",
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) return const Center(child: Text("Sem dados"));

    final entries = data.entries.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(entries.length, (i) {
          final e = entries[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: e.value.toDouble(), color: Colors.blueAccent, width: 20),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(entries[idx].key, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
