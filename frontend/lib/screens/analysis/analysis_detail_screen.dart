import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analysis_provider.dart';
import '../../config/theme.dart';
import '../../widgets/charts/risk_gauge_chart.dart';
import '../../services/api_service.dart';
import 'eeg_signal_viewer_screen.dart';

class AnalysisDetailScreen extends ConsumerStatefulWidget {
  final int analysisId;

  const AnalysisDetailScreen({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailScreen> createState() =>
      _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends ConsumerState<AnalysisDetailScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _downloadReport() async {
    final analysisState = ref.read(analysisProvider);
    final analysis = analysisState.currentAnalysis;

    // Verificar que el análisis esté completado antes de intentar descargar
    if (analysis == null || analysis.status != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El análisis aún no está listo para descargar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Descargando reporte...')));

    try {
      final bytes = await _apiService.downloadReport(widget.analysisId);

      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final a =
          html.AnchorElement(href: url)
            ..download = 'reporte_${widget.analysisId}.pdf'
            ..style.display = 'none';

      html.document.body?.append(a);
      a.click();
      a.remove();

      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte descargado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error descargando reporte: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(analysisProvider.notifier)
          .loadAnalysisDetail(widget.analysisId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final analysis = analysisState.currentAnalysis;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Análisis')),
      body:
          analysisState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : analysis == null
              ? const Center(child: Text('No se encontró el análisis'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        analysis.fileName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Fecha: ${analysis.createdAt.toString().split('.')[0]}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _InfoRow(
                              label: 'Estado',
                              value: analysis.status.toUpperCase(),
                              valueColor:
                                  analysis.status == 'completed'
                                      ? AppTheme.accentColor
                                      : AppTheme.warningColor,
                            ),
                            if (analysis.prediction != null)
                              _InfoRow(
                                label: 'Predicción',
                                value: analysis.prediction!,
                                valueColor:
                                    analysis.prediction == 'Alto Riesgo'
                                        ? AppTheme.errorColor
                                        : analysis.prediction == 'Riesgo Moderado'
                                            ? AppTheme.warningColor
                                            : AppTheme.accentColor,
                              ),
                            if (analysis.confidence != null)
                              _InfoRow(
                                label: 'Confianza',
                                value: '${(analysis.confidence! * 100).toStringAsFixed(1)}%',
                              ),
                            if (analysis.mostAnomalousChannel != null)
                              _InfoRow(
                                label: 'Canal anómalo',
                                value: analysis.mostAnomalousChannel!,
                                valueColor: AppTheme.warningColor,
                              ),
                            if (analysis.samplingRate != null)
                              _InfoRow(
                                label: 'Frec. muestreo',
                                value: '${analysis.samplingRate} Hz',
                              ),
                            if (analysis.nWindowsAnalyzed != null)
                              _InfoRow(
                                label: 'Ventanas analizadas',
                                value: '${analysis.nWindowsAnalyzed}',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (analysis.riskScore != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nivel de Riesgo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RiskGaugeChart(riskScore: analysis.riskScore!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recomendaciones',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RecommendationItem(
                              icon: Icons.medical_services,
                              text: 'Consulte con un especialista',
                            ),
                            _RecommendationItem(
                              icon: Icons.monitor_heart,
                              text: 'Monitoreo continuo recomendado',
                            ),
                            _RecommendationItem(
                              icon: Icons.description,
                              text: 'Descargue el reporte completo',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botón para visualizar ondas cerebrales
                    if (analysis.status == 'completed')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EEGSignalViewerScreen(
                                  analysisId: widget.analysisId,
                                  fileName: analysis.fileName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Ver Ondas Cerebrales'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.indigo,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton:
          analysis != null
              ? FloatingActionButton.extended(
                onPressed: analysis.status == 'completed' ? _downloadReport : null,
                icon: const Icon(Icons.download),
                label: Text(
                  analysis.status == 'completed'
                      ? 'Descargar Reporte'
                      : 'Procesando...',
                ),
              )
              : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecommendationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
