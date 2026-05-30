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

class _AnalysisDetailScreenState extends ConsumerState<AnalysisDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    Future.microtask(
      () => ref
          .read(analysisProvider.notifier)
          .loadAnalysisDetail(widget.analysisId),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // NO TOCAR LA LÓGICA DEL PDF ───────────────────────────────────────────
  Future<void> _downloadReport() async {
    final analysisState = ref.read(analysisProvider);
    final analysis = analysisState.currentAnalysis;

    if (analysis == null || analysis.status != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El análisis aún no está listo para descargar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Descargando reporte...')));

    try {
      final bytes = await _apiService.downloadReport(widget.analysisId);

      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final a = html.AnchorElement(href: url)
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
  // ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final analysis = analysisState.currentAnalysis;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // bgDark
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E), // surfaceDark
        elevation: 0,
        title: const Text('Reporte de Análisis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: analysisState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : analysis == null
              ? const Center(
                  child: Text('No se encontró el análisis',
                      style: TextStyle(color: Colors.white54)))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── HEADER CARD ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF6366F1).withAlpha(51)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withAlpha(51),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.insert_drive_file_rounded,
                                        color: Color(0xFF6366F1), size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          analysis.fileName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(analysis.createdAt
                                              .toIso8601String()),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(analysis.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── DIAGNOSTIC DETAILS ────────────────────────
                        if (analysis.status == 'completed') ...[
                          const Text(
                            'Resultados del Diagnóstico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                if (analysis.prediction != null)
                                  _buildResultRow(
                                    icon: Icons.analytics_rounded,
                                    label: 'Predicción principal',
                                    value: analysis.prediction!,
                                    valueColor: _getRiskColor(analysis.prediction),
                                    isFirst: true,
                                  ),
                                if (analysis.riskScore != null)
                                  _buildResultRow(
                                    icon: Icons.speed_rounded,
                                    label: 'Índice de riesgo',
                                    value: '${analysis.riskScore!.toStringAsFixed(1)}%',
                                    valueColor: _getRiskColor(analysis.prediction),
                                  ),
                                if (analysis.confidence != null)
                                  _buildResultRow(
                                    icon: Icons.percent_rounded,
                                    label: 'Nivel de confianza',
                                    value: '${(analysis.confidence! * 100).toStringAsFixed(1)}%',
                                  ),
                                if (analysis.mostAnomalousChannel != null)
                                  _buildResultRow(
                                    icon: Icons.electrical_services_rounded,
                                    label: 'Canal más anómalo',
                                    value: analysis.mostAnomalousChannel!,
                                    valueColor: const Color(0xFFF59E0B),
                                  ),
                                if (analysis.samplingRate != null)
                                  _buildResultRow(
                                    icon: Icons.graphic_eq_rounded,
                                    label: 'Frecuencia de muestreo',
                                    value: '${analysis.samplingRate} Hz',
                                  ),
                                if (analysis.nWindowsAnalyzed != null)
                                  _buildResultRow(
                                    icon: Icons.view_timeline_rounded,
                                    label: 'Ventanas analizadas',
                                    value: '${analysis.nWindowsAnalyzed}',
                                    isLast: true,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── VISUALIZER BUTTON ───────────────────────
                          GestureDetector(
                            onTap: () {
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
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF6366F1).withAlpha(77)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withAlpha(51),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.show_chart_rounded,
                                        color: Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Visualizador Interactivo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Explora las ondas cerebrales en tiempo real',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: Colors.white54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── RECOMMENDATIONS ─────────────────────────
                          const Text(
                            'Recomendaciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Column(
                              children: [
                                _RecommendationItem(
                                    icon: Icons.medical_services_rounded,
                                    text: 'Consulte con un especialista neurólogo'),
                                SizedBox(height: 16),
                                _RecommendationItem(
                                    icon: Icons.monitor_heart_rounded,
                                    text: 'Monitoreo continuo recomendado'),
                                SizedBox(height: 16),
                                _RecommendationItem(
                                    icon: Icons.download_rounded,
                                    text: 'Descargue el reporte PDF para su médico'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100), // padding bottom
                        ] else ...[
                          // En proceso o fallido
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    analysis.status == 'failed'
                                        ? Icons.error_outline_rounded
                                        : Icons.hourglass_empty_rounded,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    analysis.status == 'failed'
                                        ? 'Error procesando el archivo'
                                        : 'El análisis está en proceso...',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
      floatingActionButton: analysis != null && analysis.status == 'completed'
          ? FloatingActionButton.extended(
              onPressed: _downloadReport,
              backgroundColor: const Color(0xFF6366F1),
              elevation: 4,
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: const Text('Descargar Reporte',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    if (status == 'completed') {
      color = const Color(0xFF10B981);
      text = 'Completado';
    } else if (status == 'processing') {
      color = const Color(0xFF0EA5E9);
      text = 'Procesando';
    } else {
      color = const Color(0xFFEF4444);
      text = 'Fallido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white38, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: Colors.white10, height: 1),
      ],
    );
  }

  Color _getRiskColor(String? prediction) {
    if (prediction == 'Alto Riesgo') return const Color(0xFFEF4444);
    if (prediction == 'Riesgo Moderado') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecommendationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }
}
