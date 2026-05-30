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
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<dynamic> _patients = [];
  List<dynamic> _admins = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final patients = await _api.getAdminPatients();
      final stats = await _api.getAdminStats();
      final admins = await _api.getAdmins();
      setState(() {
        _patients = patients;
        _stats = stats;
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Panel Administrativo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withAlpha(77)),
                ),
                child: Text(
                  authState.user?.fullName ?? 'Admin',
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF6366F1),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Pacientes'),
            Tab(
                icon: Icon(Icons.manage_accounts_rounded),
                text: 'Admins'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPatientsTab(),
                    _buildAdminsTab(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? 'Error',
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  // ─── PATIENTS TAB ──────────────────────────────────────────
  Widget _buildPatientsTab() {
    final risk = _stats['risk_distribution'] ?? {};
    final high = (risk['high'] ?? 0) as int;
    final medium = (risk['medium'] ?? 0) as int;
    final low = (risk['low'] ?? 0) as int;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _statCard('Pacientes', '${_stats['total_patients'] ?? 0}',
                    Icons.people_alt_rounded, const Color(0xFF6366F1)),
                const SizedBox(width: 12),
                _statCard('Análisis', '${_stats['total_analyses'] ?? 0}',
                    Icons.analytics_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _statCard('Completados',
                    '${_stats['completed_analyses'] ?? 0}',
                    Icons.check_circle_rounded, const Color(0xFF0EA5E9)),
              ],
            ),
            const SizedBox(height: 20),

            // Risk distribution bar
            if (high + medium + low > 0) ...[
              const Text(
                'Distribución de Riesgo Global',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          if (high > 0)
                            Expanded(
                                flex: high,
                                child: Container(
                                    height: 20,
                                    color: const Color(0xFFEF4444))),
                          if (medium > 0)
                            Expanded(
                                flex: medium,
                                child: Container(
                                    height: 20,
                                    color: const Color(0xFFF59E0B))),
                          if (low > 0)
                            Expanded(
                                flex: low,
                                child: Container(
                                    height: 20,
                                    color: const Color(0xFF10B981))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _riskLegend('Alto', high, const Color(0xFFEF4444)),
                        _riskLegend(
                            'Moderado', medium, const Color(0xFFF59E0B)),
                        _riskLegend('Bajo', low, const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'Pacientes Registrados (${_patients.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (_patients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No hay pacientes registrados',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _patients.length,
                itemBuilder: (ctx, i) =>
                    _patientCard(_patients[i] as Map<String, dynamic>),
              ),
          ],
        ),
      ),
    );
  }

  Widget _riskLegend(String label, int count, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count',
            style:
                const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(Map<String, dynamic> patient) {
    final last = patient['last_analysis'] as Map<String, dynamic>?;
    final prediction = last?['prediction'] as String? ?? '—';
    final riskScore = last?['risk_score'];
    final uploads = patient['total_uploads'] ?? 0;
    final completed = patient['completed_analyses'] ?? 0;

    Color riskColor = Colors.white54;
    if (prediction == 'Alto Riesgo') riskColor = const Color(0xFFEF4444);
    if (prediction == 'Riesgo Moderado')
      riskColor = const Color(0xFFF59E0B);
    if (prediction == 'Bajo Riesgo') riskColor = const Color(0xFF10B981);

    return GestureDetector(
      onTap: () => _showPatientModal(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (patient['full_name'] as String? ?? '?')[0]
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['full_name'] as String? ?? 'Sin nombre',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Text(
                    '@${patient['username']} · ${patient['email']}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.upload_file,
                          size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                          '$uploads subidos · $completed analizados',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (riskScore != null)
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
                      '${(riskScore as num).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                if (last != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      prediction,
                      style: TextStyle(color: riskColor, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  void _showPatientModal(Map<String, dynamic> patient) {
    final last = patient['last_analysis'] as Map<String, dynamic>?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (patient['full_name'] as String? ??
                                    '?')[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient['full_name'] as String? ?? '—',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                Text(
                                  patient['email'] as String? ?? '—',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12),
                                ),
                                Text(
                                  'Registrado: ${_formatDate(patient['created_at'] as String?)}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _modalSection('Actividad', [
                        _modalRow(Icons.upload_file_rounded,
                            'Archivos subidos',
                            '${patient['total_uploads'] ?? 0}'),
                        _modalRow(Icons.check_circle_rounded,
                            'Análisis completados',
                            '${patient['completed_analyses'] ?? 0}'),
                      ]),
                      const SizedBox(height: 20),
                      if (last != null) ...[
                        _modalSection(
                            'Último Análisis — ${_formatDate(last['created_at'] as String?)}',
                            [
                              _modalRow(Icons.insert_drive_file_rounded,
                                  'Archivo',
                                  last['file_name'] as String? ?? '—'),
                              _riskRow(last['prediction'] as String?,
                                  last['risk_score']),
                              _modalRow(
                                  Icons.percent_rounded,
                                  'Confianza',
                                  last['confidence'] != null
                                      ? '${((last['confidence'] as num) * 100).toStringAsFixed(0)}%'
                                      : '—'),
                              _modalRow(
                                  Icons.electrical_services_rounded,
                                  'Canal más anómalo',
                                  last['most_anomalous_channel']
                                          as String? ??
                                      '—'),
                              _modalRow(
                                  Icons.window_rounded,
                                  'Ventanas analizadas',
                                  '${last['n_windows_analyzed'] ?? '—'}'),
                              _modalRow(
                                  Icons.speed_rounded,
                                  'Frecuencia de muestreo',
                                  last['sampling_rate'] != null
                                      ? '${last['sampling_rate']} Hz'
                                      : '—'),
                            ]),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.white38),
                              SizedBox(width: 12),
                              Text('Sin análisis realizados aún',
                                  style:
                                      TextStyle(color: Colors.white38)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          const Divider(color: Colors.white10, height: 1),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _modalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _riskRow(String? prediction, dynamic riskScore) {
    Color color = Colors.white54;
    if (prediction == 'Alto Riesgo') color = const Color(0xFFEF4444);
    if (prediction == 'Riesgo Moderado') color = const Color(0xFFF59E0B);
    if (prediction == 'Bajo Riesgo') color = const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.assessment_rounded,
              color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Diagnóstico',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(102)),
            ),
            child: Text(
              '${prediction ?? '—'}${riskScore != null ? '  ${(riskScore as num).toStringAsFixed(0)}%' : ''}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildAdminsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administradores del Sistema',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_admins.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay administradores cargados',
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _admins.length,
                itemBuilder: (ctx, i) => _adminCard(_admins[i] as Map<String, dynamic>),
              ),
            const SizedBox(height: 24),
            _CreateAdminForm(onAdminCreated: _loadData),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(Map<String, dynamic> admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (admin['full_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['full_name'] as String? ?? 'Sin nombre',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                Text(
                  '@${admin['username']} · ${admin['email']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Añadido: ${_formatDate(admin['created_at'] as String?)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
            onPressed: () => _deleteAdminDialog(admin),
            tooltip: 'Eliminar administrador',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdminDialog(Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2E),
        title: const Text('Eliminar Administrador', style: TextStyle(color: Colors.white)),
        content: Text('¿Seguro que deseas eliminar a ${admin['full_name']}? Esta acción no se puede deshacer.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _loading = true);
        await _api.deleteAdmin(admin['id']);
        await _loadData();
      } catch (e) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
}

// ─── Create Admin Form ──────────────────────────────────────────────────────
class _CreateAdminForm extends StatefulWidget {
  final VoidCallback onAdminCreated;
  const _CreateAdminForm({required this.onAdminCreated});

  @override
  State<_CreateAdminForm> createState() => _CreateAdminFormState();
}

class _CreateAdminFormState extends State<_CreateAdminForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _successMsg;
  String? _errorMsg;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _successMsg = null;
      _errorMsg = null;
    });
    try {
      await _api.createAdmin({
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      setState(() {
        _loading = false;
        _successMsg =
            '✅ Administrador "${_nameCtrl.text.trim()}" creado exitosamente.';
      });
      _nameCtrl.clear();
      _emailCtrl.clear();
      _usernameCtrl.clear();
      _passwordCtrl.clear();
      widget.onAdminCreated();
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crear Nuevo Administrador',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'El nuevo administrador tendrá acceso completo al panel de gestión.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_successMsg != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(102)),
              ),
              child: Text(_successMsg!,
                  style: const TextStyle(color: Color(0xFF10B981))),
            ),

          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withAlpha(102)),
              ),
              child: Text(_errorMsg!,
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_nameCtrl, 'Nombre completo', Icons.badge_rounded),
                  const SizedBox(height: 14),
                  _field(_emailCtrl, 'Correo electrónico', Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _field(_usernameCtrl, 'Nombre de usuario',
                      Icons.person_rounded),
                  const SizedBox(height: 14),
                  _field(_passwordCtrl, 'Contraseña', Icons.lock_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      )),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(
                              Icons.admin_panel_settings_rounded),
                      label: Text(
                        _loading ? 'Creando...' : 'Crear Administrador',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withAlpha(15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}
