import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../models/user_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    Future.microtask(
        () => ref.read(analysisProvider.notifier).loadAnalyses());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _goUpload() async {
    await Navigator.pushNamed(context, '/upload');
    if (mounted) ref.read(analysisProvider.notifier).loadAnalyses();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final analysisState = ref.watch(analysisProvider);
    final user = authState.user;
    final analyses = analysisState.analyses;
    final completed = analyses.where((a) => a.status == 'completed').toList();
    final lastAnalysis = completed.isNotEmpty ? completed.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1A1D2E),
          onRefresh: () =>
              ref.read(analysisProvider.notifier).loadAnalyses(),
          child: CustomScrollView(
            slivers: [
              // ── APP BAR ───────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF1A1D2E),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                          Color(0xFF0F1117),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(38),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (user?.fullName ?? 'U')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bienvenido de vuelta',
                                          style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12),
                                        ),
                                        Text(
                                          user?.fullName ?? 'Usuario',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout_rounded,
                                      color: Colors.white60),
                                  tooltip: 'Cerrar sesión',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'NeuroScan AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Tu historial de análisis EEG',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: const [SizedBox()],
              ),

              // ── CONTENT ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── STAT CARDS ───────────────────────────────
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.biotech_rounded,
                            label: 'Total',
                            value: '${analyses.length}',
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Completados',
                            value: '${completed.length}',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),

                      // ── LAST RESULT CARD ─────────────────────────
                      if (lastAnalysis != null) ...[
                        const SizedBox(height: 24),
                        _buildLastResultCard(lastAnalysis),
                      ],

                      // ── UPLOAD BANNER ─────────────────────────────
                      const SizedBox(height: 24),
                      _buildUploadBanner(),

                      // ── ANALYSIS LIST ─────────────────────────────
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (analyses.isNotEmpty)
                            Text(
                              '${analyses.length} archivos',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (analysisState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                                color: Color(0xFF6366F1)),
                          ),
                        )
                      else if (analyses.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: analyses.length,
                          itemBuilder: (ctx, i) =>
                              _buildAnalysisCard(analyses[i]),
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _goUpload,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
          label: const Text(
            'Subir EEG',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ── WIDGETS HELPERS ────────────────────────────────────────────────

  Widget _buildStatCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastResultCard(AnalysisModel analysis) {
    Color riskColor = const Color(0xFF10B981);
    IconData riskIcon = Icons.check_circle_rounded;
    String riskLabel = 'Bajo Riesgo';

    if (analysis.prediction == 'Alto Riesgo') {
      riskColor = const Color(0xFFEF4444);
      riskIcon = Icons.warning_rounded;
      riskLabel = 'Alto Riesgo';
    } else if (analysis.prediction == 'Riesgo Moderado') {
      riskColor = const Color(0xFFF59E0B);
      riskIcon = Icons.info_rounded;
      riskLabel = 'Riesgo Moderado';
    }

    final score = analysis.riskScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withAlpha(38),
            const Color(0xFF1A1D2E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Último Resultado',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: riskColor.withAlpha(102)),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Risk score progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Índice de Riesgo',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniMetric(Icons.electrical_services_rounded,
                  'Canal anómalo',
                  analysis.mostAnomalousChannel ?? '—'),
              const SizedBox(width: 16),
              _miniMetric(Icons.window_rounded, 'Ventanas',
                  '${analysis.nWindowsAnalyzed ?? '—'}'),
              const SizedBox(width: 16),
              _miniMetric(Icons.speed_rounded, 'Hz',
                  '${analysis.samplingRate ?? '—'}'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/analysis-detail',
                arguments: analysis.id,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: riskColor.withAlpha(102)),
                foregroundColor: riskColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Ver reporte completo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUploadBanner() {
    return GestureDetector(
      onTap: _goUpload,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF6366F1).withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: Color(0xFF6366F1), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuevo Análisis EEG',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sube un archivo .edf o .csv para análisis',
                    style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF6366F1), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.biotech_rounded,
                color: Color(0xFF6366F1), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin análisis aún',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sube tu primer archivo EEG\npara comenzar el análisis',
            style: TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Subir primer archivo',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(AnalysisModel analysis) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (analysis.status) {
      case 'completed':
        final p = analysis.prediction ?? '';
        if (p == 'Alto Riesgo') {
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.warning_rounded;
          statusLabel = p;
        } else if (p == 'Riesgo Moderado') {
          statusColor = const Color(0xFFF59E0B);
          statusIcon = Icons.info_rounded;
          statusLabel = p;
        } else {
          statusColor = const Color(0xFF10B981);
          statusIcon = Icons.check_circle_rounded;
          statusLabel = p.isEmpty ? 'Bajo Riesgo' : p;
        }
        break;
      case 'processing':
        statusColor = const Color(0xFF0EA5E9);
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Procesando...';
        break;
      case 'failed':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_rounded;
        statusLabel = 'Error';
        break;
      default:
        statusColor = Colors.white54;
        statusIcon = Icons.circle_outlined;
        statusLabel = analysis.status;
    }

    final date = _formatDate(analysis.createdAt.toIso8601String());

    return GestureDetector(
      onTap: analysis.status == 'completed'
          ? () => Navigator.pushNamed(context, '/analysis-detail',
              arguments: analysis.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(13)),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.insert_drive_file_rounded,
                  color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.fileName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon,
                          color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (analysis.riskScore != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${analysis.riskScore!.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            if (analysis.status == 'completed')
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right,
                    color: Colors.white24, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
