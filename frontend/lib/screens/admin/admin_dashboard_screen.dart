import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  late AnimationController _fadeCtrl;

  List<dynamic> _patients = [];
  List<dynamic> _admins = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  // ── Enterprise medical palette ──────────────────────────────────
  static const _bg        = Color(0xFF08090F);
  static const _surface   = Color(0xFF111318);
  static const _surfaceHi = Color(0xFF1A1D27);
  static const _border    = Color(0xFF222533);
  static const _accent    = Color(0xFF4F8EF7);
  static const _accentGlow= Color(0xFF2D5FCC);
  static const _green     = Color(0xFF22C55E);
  static const _amber     = Color(0xFFF59E0B);
  static const _red       = Color(0xFFEF4444);
  static const _textPri   = Color(0xFFE8EAF0);
  static const _textSec   = Color(0xFF8B90A0);
  static const _textMut   = Color(0xFF4A4F62);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final patients = await _api.getAdminPatients();
      final stats    = await _api.getAdminStats();
      final admins   = await _api.getAdmins();
      setState(() {
        _patients = patients;
        _stats    = stats;
        _admins   = admins;
        _loading  = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(authState.user?.fullName ?? 'Admin'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fadeCtrl,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildPatientsTab(), _buildAdminsTab()],
                  ),
                ),
    );
  }

  AppBar _buildAppBar(String adminName) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _accent.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withAlpha(60)),
          ),
          child: const Icon(Icons.admin_panel_settings_rounded, color: _accent, size: 18),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panel Administrativo',
              style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 15)),
          Text('NeuroScan AI · Control total',
              style: TextStyle(color: _textMut, fontSize: 10)),
        ]),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentGlow.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withAlpha(50)),
          ),
          child: Row(children: [
            const Icon(Icons.shield_rounded, color: _accent, size: 12),
            const SizedBox(width: 5),
            Text(adminName,
                style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: _textSec, size: 19),
          onPressed: _logout,
          tooltip: 'Cerrar sesión',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(49),
        child: Column(children: [
          Container(height: 1, color: _border),
          TabBar(
            controller: _tabController,
            labelColor: _accent,
            unselectedLabelColor: _textMut,
            indicatorColor: _accent,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Pacientes'),
              Tab(icon: Icon(Icons.manage_accounts_rounded, size: 18), text: 'Admins'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _red.withAlpha(22),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.error_outline_rounded, color: _red, size: 42),
      ),
      const SizedBox(height: 18),
      Text(_error ?? 'Error desconocido',
          style: const TextStyle(color: _textSec, fontSize: 13), textAlign: TextAlign.center),
      const SizedBox(height: 18),
      ElevatedButton.icon(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]));
  }

  // ─────────────────────────────────────────────────────────────────
  // PATIENTS TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPatientsTab() {
    final risk   = _stats['risk_distribution'] ?? {};
    final high   = (risk['high']   ?? 0) as int;
    final medium = (risk['medium'] ?? 0) as int;
    final low    = (risk['low']    ?? 0) as int;

    return RefreshIndicator(
      onRefresh: _loadData, color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── KPI strip ──────────────────────────────────────────
          Row(children: [
            _kpiCard('${_stats['total_patients'] ?? 0}', 'Pacientes', Icons.people_alt_rounded, _accent),
            const SizedBox(width: 10),
            _kpiCard('${_stats['total_analyses'] ?? 0}', 'Análisis', Icons.analytics_rounded, _green),
            const SizedBox(width: 10),
            _kpiCard('${_stats['completed_analyses'] ?? 0}', 'Completos', Icons.check_circle_outline_rounded, _amber),
            const SizedBox(width: 10),
            _kpiCard('$high', 'Alto Riesgo', Icons.warning_amber_rounded, _red),
          ]),
          const SizedBox(height: 18),

          // ── Risk distribution bar ───────────────────────────────
          if (high + medium + low > 0) ...[
            _sectionLabel('Distribución global de riesgo'),
            const SizedBox(height: 10),
            _riskDistributionCard(high, medium, low),
            const SizedBox(height: 20),
          ],

          // ── Patients list ───────────────────────────────────────
          _sectionLabel('Pacientes registrados (${_patients.length})'),
          const SizedBox(height: 10),
          if (_patients.isEmpty)
            _emptyState(Icons.people_outline_rounded, 'No hay pacientes registrados')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length,
              itemBuilder: (ctx, i) => _patientCard(_patients[i] as Map<String, dynamic>),
            ),
        ]),
      ),
    );
  }

  Widget _riskDistributionCard(int high, int medium, int low) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(children: [
            if (high > 0) Expanded(flex: high, child: Container(height: 16, color: _red)),
            if (medium > 0) Expanded(flex: medium, child: Container(height: 16, color: _amber)),
            if (low > 0) Expanded(flex: low, child: Container(height: 16, color: _green)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _riskLegend('Alto',    high,   _red),
          _riskLegend('Moderado', medium, _amber),
          _riskLegend('Bajo',    low,    _green),
        ]),
      ]),
    );
  }

  Widget _riskLegend(String label, int count, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label: $count', style: const TextStyle(color: _textSec, fontSize: 11)),
    ]);
  }

  Widget _patientCard(Map<String, dynamic> patient) {
    final last       = patient['last_analysis'] as Map<String, dynamic>?;
    final prediction = last?['prediction'] as String? ?? '—';
    final riskScore  = last?['risk_score'];
    final uploads    = patient['total_uploads'] ?? 0;
    final completed  = patient['completed_analyses'] ?? 0;
    final (riskColor, _, _) = _riskStyle(prediction);

    return GestureDetector(
      onTap: () => _showPatientModal(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent.withAlpha(50), _accentGlow.withAlpha(50)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withAlpha(60)),
            ),
            child: Center(
              child: Text(
                (patient['full_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(patient['full_name'] as String? ?? 'Sin nombre',
                style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('@${patient['username']} · ${patient['email']}',
                style: const TextStyle(color: _textMut, fontSize: 11),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.folder_open_rounded, size: 11, color: _textMut),
              const SizedBox(width: 4),
              Text('$uploads subidos · $completed analizados',
                  style: const TextStyle(color: _textMut, fontSize: 10)),
            ]),
          ])),
          const SizedBox(width: 8),
          // Risk badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (riskScore != null)
              _pill('${(riskScore as num).toStringAsFixed(0)}%', riskColor),
            if (last != null) ...[
              const SizedBox(height: 4),
              Text(prediction, style: TextStyle(color: riskColor, fontSize: 10)),
            ],
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: _textMut, size: 17),
        ]),
      ),
    );
  }

  void _showPatientModal(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => _PatientDetailSheet(
        patient: patient,
        api: _api,
        onDeleted: _loadData,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ADMINS TAB
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAdminsTab() {
    return RefreshIndicator(
      onRefresh: _loadData, color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('Administradores del sistema (${_admins.length})'),
          const SizedBox(height: 10),
          if (_admins.isEmpty)
            _emptyState(Icons.manage_accounts_outlined, 'No hay administradores cargados')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _admins.length,
              itemBuilder: (ctx, i) => _adminCard(_admins[i] as Map<String, dynamic>),
            ),
          const SizedBox(height: 24),
          _CreateAdminForm(onAdminCreated: _loadData),
        ]),
      ),
    );
  }

  Widget _adminCard(Map<String, dynamic> admin) {
    final initial = (admin['full_name'] as String? ?? '?')[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _green.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: _green.withAlpha(60)),
          ),
          child: Center(child: Text(initial,
              style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 17))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(admin['full_name'] as String? ?? 'Sin nombre',
              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text('@${admin['username']} · ${admin['email']}',
              style: const TextStyle(color: _textMut, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('Añadido: ${_fmtDate(admin['created_at'] as String?)}',
              style: const TextStyle(color: _textMut, fontSize: 10)),
        ])),
        GestureDetector(
          onTap: () => _deleteAdminDialog(admin),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _red.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: _red, size: 17),
          ),
        ),
      ]),
    );
  }

  Future<void> _deleteAdminDialog(Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: _surfaceHi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _red.withAlpha(28), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_forever_rounded, color: _red, size: 22),
              ),
              const SizedBox(width: 14),
              const Text('Eliminar admin', style: TextStyle(color: _textPri, fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            Text('¿Eliminar a "${admin['full_name']}"? Esto no se puede deshacer.',
                style: const TextStyle(color: _textSec, fontSize: 13, height: 1.55)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border), foregroundColor: _textSec,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _loading = true);
        await _api.deleteAdmin(admin['id']);
        await _loadData();
      } catch (e) {
        setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
      }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  Widget _kpiCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: _textMut, fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14));

  Widget _emptyState(IconData icon, String msg) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(child: Column(children: [
      Icon(icon, size: 52, color: _textMut),
      const SizedBox(height: 14),
      Text(msg, style: const TextStyle(color: _textMut, fontSize: 13)),
    ])),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(25), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(70)),
    ),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
  );

  (Color, IconData, String) _riskStyle(String prediction) => switch (prediction) {
    'Alto Riesgo'    => (_red,   Icons.warning_rounded,       'Alto Riesgo'),
    'Riesgo Moderado'=> (_amber, Icons.info_rounded,          'Riesgo Moderado'),
    _                => (_green, Icons.check_circle_rounded,  prediction.isEmpty ? 'Bajo Riesgo' : prediction),
  };

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return iso; }
  }
}

// ═══════════════════════════════════════════════════════════════════
// PATIENT DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
class _PatientDetailSheet extends StatefulWidget {
  final Map<String, dynamic> patient;
  final ApiService api;
  final VoidCallback onDeleted;

  const _PatientDetailSheet({required this.patient, required this.api, required this.onDeleted});

  @override
  State<_PatientDetailSheet> createState() => _PatientDetailSheetState();
}

class _PatientDetailSheetState extends State<_PatientDetailSheet> {
  static const _bg        = Color(0xFF08090F);
  static const _surface   = Color(0xFF111318);
  static const _surfaceHi = Color(0xFF1A1D27);
  static const _border    = Color(0xFF222533);
  static const _accent    = Color(0xFF4F8EF7);
  static const _green     = Color(0xFF22C55E);
  static const _amber     = Color(0xFFF59E0B);
  static const _red       = Color(0xFFEF4444);
  static const _textPri   = Color(0xFFE8EAF0);
  static const _textSec   = Color(0xFF8B90A0);
  static const _textMut   = Color(0xFF4A4F62);

  List<dynamic> _analyses = [];
  bool _loadingAnalyses = false;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() => _loadingAnalyses = true);
    try {
      final data = await widget.api.getAdminAllAnalyses(widget.patient['id'] as int);
      if (mounted) setState(() { _analyses = data; _loadingAnalyses = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAnalyses = false);
    }
  }

  Future<void> _deleteAnalysis(Map<String, dynamic> analysis) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: _surfaceHi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _red.withAlpha(28), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_forever_rounded, color: _red, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Eliminar análisis', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 14),
            Text('¿Eliminar "${analysis['file_name']}"? Esta acción no se puede deshacer.',
                style: const TextStyle(color: _textSec, fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border), foregroundColor: _textSec,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: const Text('Cancelar'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        await widget.api.deleteAnalysis(analysis['id'] as int);
        await _loadAnalyses();
        widget.onDeleted();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Análisis eliminado', style: TextStyle(color: _textPri)),
            backgroundColor: _surfaceHi,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    }
  }

  (Color, String) _riskStyle(String? prediction) => switch (prediction ?? '') {
    'Alto Riesgo'    => (_red,   'Alto Riesgo'),
    'Riesgo Moderado'=> (_amber, 'Moderado'),
    _                => (_green, 'Bajo Riesgo'),
  };

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final uploads   = patient['total_uploads'] ?? 0;
    final completed = patient['completed_analyses'] ?? 0;
    final initial   = (patient['full_name'] as String? ?? '?')[0].toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.93,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Column(children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 38, height: 3,
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          // Patient header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_accent, Color(0xFF2D5FCC)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _accent.withAlpha(80), blurRadius: 14, offset: const Offset(0,4))],
                ),
                child: Center(child: Text(initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(patient['full_name'] as String? ?? '—',
                    style: const TextStyle(color: _textPri, fontWeight: FontWeight.bold, fontSize: 17)),
                Text(patient['email'] as String? ?? '—',
                    style: const TextStyle(color: _textSec, fontSize: 12)),
                Text('Registrado: ${_fmtDate(patient['created_at'] as String?)}',
                    style: const TextStyle(color: _textMut, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          // Activity strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              _infoChip(Icons.folder_open_rounded, '$uploads subidos', _accent),
              const SizedBox(width: 8),
              _infoChip(Icons.check_circle_outline_rounded, '$completed completos', _green),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Historial de análisis (${_analyses.length})',
                  style: const TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
              if (_loadingAnalyses)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
            ]),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _border),
          // Analyses list
          Expanded(
            child: _loadingAnalyses
                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                : _analyses.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.analytics_outlined, color: _textMut, size: 40),
                        const SizedBox(height: 12),
                        const Text('Sin análisis realizados', style: TextStyle(color: _textMut, fontSize: 13)),
                      ]))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount: _analyses.length,
                        itemBuilder: (ctx, i) => _analysisRow(_analyses[i] as Map<String, dynamic>),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _analysisRow(Map<String, dynamic> analysis) {
    final (riskColor, riskLabel) = _riskStyle(analysis['status'] == 'completed' ? analysis['prediction'] as String? : null);
    final score = analysis['risk_score'];
    final statusStr = analysis['status'] as String? ?? '';
    final isCompleted = statusStr == 'completed';

    Color statusColor = isCompleted ? riskColor : (statusStr == 'processing' ? _accent : _red);
    String statusLabel = isCompleted ? riskLabel : (statusStr == 'processing' ? 'Procesando' : statusStr.isEmpty ? '—' : statusStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surfaceHi, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(22), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withAlpha(50)),
          ),
          child: Icon(Icons.insert_drive_file_rounded, color: statusColor, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(analysis['file_name'] as String? ?? '—',
              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(_fmtDate(analysis['created_at'] as String?),
              style: const TextStyle(color: _textMut, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          if (score != null) ...[
            const SizedBox(height: 3),
            Text('${(score as num).toStringAsFixed(0)}%',
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ]),
        const SizedBox(width: 8),
        // Delete button
        GestureDetector(
          onTap: () => _deleteAnalysis(analysis),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _red.withAlpha(18), borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: _red, size: 15),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CREATE ADMIN FORM
// ═══════════════════════════════════════════════════════════════════
class _CreateAdminForm extends StatefulWidget {
  final VoidCallback onAdminCreated;
  const _CreateAdminForm({required this.onAdminCreated});

  @override
  State<_CreateAdminForm> createState() => _CreateAdminFormState();
}

class _CreateAdminFormState extends State<_CreateAdminForm> {
  static const _surface   = Color(0xFF111318);
  static const _surfaceHi = Color(0xFF1A1D27);
  static const _border    = Color(0xFF222533);
  static const _accent    = Color(0xFF4F8EF7);
  static const _green     = Color(0xFF22C55E);
  static const _red       = Color(0xFFEF4444);
  static const _textPri   = Color(0xFFE8EAF0);
  static const _textSec   = Color(0xFF8B90A0);
  static const _textMut   = Color(0xFF4A4F62);

  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  String? _successMsg;
  String? _errorMsg;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _usernameCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _successMsg = null; _errorMsg = null; });
    try {
      await _api.createAdmin({
        'full_name': _nameCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'username':  _usernameCtrl.text.trim(),
        'password':  _passwordCtrl.text,
      });
      setState(() {
        _loading = false;
        _successMsg = 'Administrador "${_nameCtrl.text.trim()}" creado exitosamente.';
      });
      _nameCtrl.clear(); _emailCtrl.clear(); _usernameCtrl.clear(); _passwordCtrl.clear();
      widget.onAdminCreated();
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _accent.withAlpha(12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: _accent.withAlpha(40)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _accent.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_add_rounded, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Crear nuevo administrador',
                style: TextStyle(color: _textPri, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Tendrá acceso completo al sistema',
                style: TextStyle(color: _textMut, fontSize: 11)),
          ]),
        ]),
      ),

      // Form body
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
          border: Border.all(color: _border),
        ),
        child: Form(
          key: _formKey,
          child: Column(children: [
            if (_successMsg != null)
              _alert(_successMsg!, _green),
            if (_errorMsg != null)
              _alert(_errorMsg!, _red),

            _field(_nameCtrl, 'Nombre completo', Icons.badge_rounded),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Correo electrónico', Icons.email_rounded, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_usernameCtrl, 'Nombre de usuario', Icons.person_rounded),
            const SizedBox(height: 12),
            _field(_passwordCtrl, 'Contraseña', Icons.lock_rounded, obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: _textMut, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: Text(_loading ? 'Creando...' : 'Crear administrador',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _alert(String msg, Color color) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: color.withAlpha(22), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(70)),
    ),
    child: Row(children: [
      Icon(color == _green ? Icons.check_circle_outline : Icons.error_outline, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 12))),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: _textPri, fontSize: 13),
      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMut, fontSize: 13),
        prefixIcon: Icon(icon, color: _textMut, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surfaceHi,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red)),
        errorStyle: const TextStyle(color: _red, fontSize: 11),
      ),
    );
  }
}
