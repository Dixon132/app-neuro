import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimCtrl;
  late AnimationController _cardsAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ApiService _api = ApiService();

  // ── Color palette enterprise médico ──────────────────────────────
  static const _bg         = Color(0xFF08090F);
  static const _surface    = Color(0xFF111318);
  static const _surfaceHi  = Color(0xFF1A1D27);
  static const _border     = Color(0xFF222533);
  static const _accent     = Color(0xFF4F8EF7);   // azul eléctrico (médico)
  static const _accentGlow = Color(0xFF2D5FCC);
  static const _green      = Color(0xFF22C55E);
  static const _amber      = Color(0xFFF59E0B);
  static const _red        = Color(0xFFEF4444);
  static const _textPri    = Color(0xFFE8EAF0);
  static const _textSec    = Color(0xFF8B90A0);
  static const _textMut    = Color(0xFF4A4F62);

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardsAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardsAnimCtrl, curve: Curves.easeOut));

    _headerAnimCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardsAnimCtrl.forward();
      Future.microtask(() => ref.read(analysisProvider.notifier).loadAnalyses());
    });
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    _cardsAnimCtrl.dispose();
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

  Future<void> _confirmDelete(AnalysisModel analysis) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: _surfaceHi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _red.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: _red, size: 22),
                ),
                const SizedBox(width: 14),
                const Text('Eliminar análisis',
                    style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              Text(
                'Se eliminará permanentemente el archivo "${analysis.fileName}" y su reporte PDF. Esta acción no se puede deshacer.',
                style: const TextStyle(color: _textSec, fontSize: 13, height: 1.55),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      foregroundColor: _textSec,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _api.deleteAnalysis(analysis.id);
        if (mounted) {
          ref.read(analysisProvider.notifier).loadAnalyses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_outline, color: _green, size: 18),
                SizedBox(width: 10),
                Text('Análisis eliminado correctamente', style: TextStyle(color: _textPri)),
              ]),
              backgroundColor: _surfaceHi,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: _red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final analysisState = ref.watch(analysisProvider);
    final user = authState.user;
    final analyses = analysisState.analyses;
    final completed = analyses.where((a) => a.status == 'completed').toList();
    final pending = analyses.where((a) => a.status == 'processing').toList();
    final lastAnalysis = completed.isNotEmpty ? completed.first : null;

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _surfaceHi,
          onRefresh: () => ref.read(analysisProvider.notifier).loadAnalyses(),
          child: CustomScrollView(
            slivers: [
              // ── HEADER ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: _surface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.blurBackground],
                  background: _buildHeader(user),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: Container(height: 1, color: _border),
                ),
                actions: [
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: _textSec, size: 20),
                    tooltip: 'Cerrar sesión',
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── CONTENT ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _cardsAnimCtrl,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── KPI STRIP ──────────────────────────────
                          _buildKpiStrip(analyses, completed, pending),
                          const SizedBox(height: 20),

                          // ── LAST RESULT CARD ───────────────────────
                          if (lastAnalysis != null) ...[
                            _buildLastResultCard(lastAnalysis),
                            const SizedBox(height: 20),
                          ],

                          // ── UPLOAD CARD ────────────────────────────
                          _buildUploadCard(),
                          const SizedBox(height: 28),

                          // ── HISTORY HEADER ─────────────────────────
                          _buildSectionHeader('Historial de análisis', '${analyses.length} archivos'),
                          const SizedBox(height: 12),

                          // ── LIST ───────────────────────────────────
                          if (analysisState.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(48),
                                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                              ),
                            )
                          else if (analyses.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: analyses.length,
                              itemBuilder: (ctx, i) => _buildAnalysisCard(analyses[i], i),
                            ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────
      floatingActionButton: _buildFab(),
    );
  }

  // ── WIDGETS ──────────────────────────────────────────────────────────

  Widget _buildHeader(UserModel? user) {
    final initials = (user?.fullName ?? 'U')
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join()
        .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B3E), Color(0xFF111318)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Decorative circle blur
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _accentGlow.withAlpha(60),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_accent, _accentGlow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: _accent.withAlpha(80),
                            blurRadius: 12, offset: const Offset(0, 4),
                          )],
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Bienvenido de vuelta',
                            style: TextStyle(color: _textSec, fontSize: 11)),
                        Text(user?.fullName ?? 'Usuario',
                            style: const TextStyle(
                                color: _textPri, fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
                      const Spacer(),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accent.withAlpha(60)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.person_rounded, color: _accent, size: 12),
                          SizedBox(width: 5),
                          Text('Paciente', style: TextStyle(
                              color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Container(
                      width: 3, height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [_accent, _accentGlow],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('NeuroScan AI',
                          style: TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      const Text('Sistema de Análisis EEG · Panel del Paciente',
                          style: TextStyle(color: _textSec, fontSize: 11)),
                    ]),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiStrip(List<AnalysisModel> analyses, List<AnalysisModel> completed, List<AnalysisModel> pending) {
    final highRisk = completed.where((a) => a.prediction == 'Alto Riesgo').length;
    return Row(children: [
      _kpiCard('${analyses.length}', 'Total', Icons.folder_open_rounded, _accent),
      const SizedBox(width: 10),
      _kpiCard('${completed.length}', 'Listos', Icons.check_circle_outline_rounded, _green),
      const SizedBox(width: 10),
      _kpiCard('${pending.length}', 'Proceso', Icons.hourglass_top_rounded, _amber),
      const SizedBox(width: 10),
      _kpiCard('$highRisk', 'Alto Riesgo', Icons.warning_amber_rounded, _red),
    ]);
  }

  Widget _kpiCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              color: color, fontSize: 19, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(
              color: _textMut, fontSize: 9, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildLastResultCard(AnalysisModel analysis) {
    final (riskColor, riskIcon, riskLabel) = _riskStyle(analysis.prediction ?? '');
    final score = analysis.riskScore ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withAlpha(80)),
        boxShadow: [BoxShadow(
          color: riskColor.withAlpha(20),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header strip
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: riskColor.withAlpha(18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: riskColor.withAlpha(40))),
          ),
          child: Row(children: [
            Icon(riskIcon, color: riskColor, size: 17),
            const SizedBox(width: 8),
            const Text('Último resultado',
                style: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            _pill(riskLabel, riskColor),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Risk bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Índice de riesgo', style: TextStyle(color: _textSec, fontSize: 12)),
              Text('${score.toStringAsFixed(1)}%',
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 7,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            const SizedBox(height: 16),
            // Metrics row
            Row(children: [
              _miniMetric(Icons.electrical_services_rounded, 'Canal', analysis.mostAnomalousChannel ?? '—'),
              _miniMetric(Icons.window_rounded, 'Ventanas', '${analysis.nWindowsAnalyzed ?? '—'}'),
              _miniMetric(Icons.speed_rounded, 'Frec.', '${analysis.samplingRate ?? '—'} Hz'),
            ]),
            const SizedBox(height: 16),
            // CTA button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/analysis-detail', arguments: analysis.id),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: riskColor.withAlpha(100)),
                  foregroundColor: riskColor,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Ver reporte completo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _goUpload,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B3E), Color(0xFF0F1F4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withAlpha(70)),
          boxShadow: [BoxShadow(
            color: _accent.withAlpha(25),
            blurRadius: 20, offset: const Offset(0, 6),
          )],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _accent.withAlpha(35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withAlpha(80)),
            ),
            child: const Icon(Icons.upload_file_rounded, color: _accent, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nuevo análisis EEG', style: TextStyle(
                color: _textPri, fontWeight: FontWeight.w700, fontSize: 14)),
            SizedBox(height: 3),
            Text('Sube un archivo .edf o .csv', style: TextStyle(color: _textSec, fontSize: 12)),
          ])),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _accent.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: _accent, size: 14),
          ),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(
          color: _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
      Text(sub, style: const TextStyle(color: _textMut, fontSize: 12)),
    ]);
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _accent.withAlpha(20),
            shape: BoxShape.circle,
            border: Border.all(color: _accent.withAlpha(50)),
          ),
          child: const Icon(Icons.biotech_rounded, color: _accent, size: 36),
        ),
        const SizedBox(height: 18),
        const Text('Sin análisis aún',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Sube tu primer archivo EEG para comenzar',
            style: TextStyle(color: _textSec, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _goUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Subir archivo', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildAnalysisCard(AnalysisModel analysis, int index) {
    final (statusColor, statusIcon, statusLabel) = _statusStyle(analysis);
    final date = _formatDate(analysis.createdAt.toIso8601String());
    final canOpen = analysis.status == 'completed';

    return AnimatedBuilder(
      animation: _cardsAnimCtrl,
      builder: (ctx, child) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1 * (index + 1).clamp(1, 4)),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _cardsAnimCtrl,
          curve: Interval(
            (index * 0.08).clamp(0, 0.6),
            ((index * 0.08) + 0.4).clamp(0, 1.0),
            curve: Curves.easeOut,
          ),
        )),
        child: FadeTransition(opacity: _cardsAnimCtrl, child: child),
      ),
      child: GestureDetector(
        onTap: canOpen
            ? () => Navigator.pushNamed(context, '/analysis-detail', arguments: analysis.id)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              // File icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withAlpha(50)),
                ),
                child: Icon(Icons.insert_drive_file_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(analysis.fileName,
                    style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(date, style: const TextStyle(color: _textMut, fontSize: 11)),
              ])),
              const SizedBox(width: 8),
              // Status + score
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _pill(statusLabel, statusColor),
                if (analysis.riskScore != null) ...[
                  const SizedBox(height: 4),
                  Text('${analysis.riskScore!.toStringAsFixed(0)}%',
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ]),
              const SizedBox(width: 8),
              // Action buttons
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (canOpen)
                  Icon(Icons.chevron_right_rounded, color: _textMut, size: 18),
                // Delete button
                GestureDetector(
                  onTap: () => _confirmDelete(analysis),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _red.withAlpha(18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: _red, size: 16),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [_accent, _accentGlow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: _accent.withAlpha(100),
          blurRadius: 24, offset: const Offset(0, 8),
        )],
      ),
      child: FloatingActionButton.extended(
        onPressed: _goUpload,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Subir EEG',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _miniMetric(IconData icon, String label, String value) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _textMut, size: 11),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _textMut, fontSize: 10)),
      ]),
      Text(value, style: const TextStyle(color: _textSec, fontWeight: FontWeight.w600, fontSize: 12)),
    ]));
  }

  (Color, IconData, String) _riskStyle(String prediction) {
    return switch (prediction) {
      'Alto Riesgo' => (_red, Icons.warning_rounded, 'Alto Riesgo'),
      'Riesgo Moderado' => (_amber, Icons.info_rounded, 'Riesgo Moderado'),
      _ => (_green, Icons.check_circle_rounded, prediction.isEmpty ? 'Bajo Riesgo' : prediction),
    };
  }

  (Color, IconData, String) _statusStyle(AnalysisModel a) {
    return switch (a.status) {
      'completed' => _riskStyle(a.prediction ?? ''),
      'processing' => (const Color(0xFF4F8EF7), Icons.hourglass_top_rounded, 'Procesando...'),
      'failed' => (_red, Icons.error_rounded, 'Error'),
      _ => (_textMut, Icons.circle_outlined, a.status),
    };
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${dt.day} ${months[dt.month]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
