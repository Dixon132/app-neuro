import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class EEGSignalViewerScreen extends StatefulWidget {
  final int analysisId;
  final String fileName;

  const EEGSignalViewerScreen({
    Key? key,
    required this.analysisId,
    required this.fileName,
  }) : super(key: key);

  @override
  State<EEGSignalViewerScreen> createState() => _EEGSignalViewerScreenState();
}

class _EEGSignalViewerScreenState extends State<EEGSignalViewerScreen>
    with TickerProviderStateMixin {
  // ── estado lógico original SIN TOCAR ────────────────────────────
  bool _isLoading = true;
  String? _error;

  List<FlSpot> _signalData = [];
  int _currentChannel = 0;
  double _startTime = 0;
  double _duration = 10;

  String _channelName = '';
  double _samplingRate = 256;
  List<Map<String, dynamic>> _availableChannels = [];
  double _totalDuration = 0;
  Map<String, double> _statistics = {};

  // ── paleta enterprise ────────────────────────────────────────────
  static const _bg       = Color(0xFF08090F);
  static const _surface  = Color(0xFF111318);
  static const _surfHi   = Color(0xFF1A1D27);
  static const _border   = Color(0xFF222533);
  static const _accent   = Color(0xFF4F8EF7);
  static const _accentLo = Color(0xFF2D5FCC);
  static const _green    = Color(0xFF22C55E);
  static const _amber    = Color(0xFFF59E0B);
  static const _red      = Color(0xFFEF4444);
  static const _textPri  = Color(0xFFE8EAF0);
  static const _textSec  = Color(0xFF8B90A0);
  static const _textMut  = Color(0xFF4A4F62);

  // ── animaciones ──────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _loadingCtrl;
  late Animation<double> _entryAnim;
  late Animation<double> _chartAnim;

  // canal info map original SIN TOCAR ─────────────────────────────
  static const Map<String, Map<String, String>> channelInfo = {
    'FP1': {'region': 'Frontal Izquierdo', 'function': 'Pensamiento, planificación, personalidad'},
    'FP2': {'region': 'Frontal Derecho', 'function': 'Pensamiento, planificación, personalidad'},
    'F3': {'region': 'Frontal Izquierdo', 'function': 'Movimiento voluntario, habla (área de Broca)'},
    'F4': {'region': 'Frontal Derecho', 'function': 'Movimiento voluntario'},
    'F7': {'region': 'Frontal Lateral Izquierdo', 'function': 'Memoria verbal, emociones'},
    'F8': {'region': 'Frontal Lateral Derecho', 'function': 'Memoria visual, emociones'},
    'FZ': {'region': 'Frontal Central', 'function': 'Control motor, atención'},
    'C3': {'region': 'Central Izquierdo', 'function': 'Movimiento del lado derecho del cuerpo'},
    'C4': {'region': 'Central Derecho', 'function': 'Movimiento del lado izquierdo del cuerpo'},
    'CZ': {'region': 'Central Medio', 'function': 'Coordinación motora'},
    'T3': {'region': 'Temporal Izquierdo', 'function': 'Audición, comprensión del lenguaje'},
    'T4': {'region': 'Temporal Derecho', 'function': 'Audición, reconocimiento de caras'},
    'T5': {'region': 'Temporal Posterior Izquierdo', 'function': 'Memoria, lenguaje'},
    'T6': {'region': 'Temporal Posterior Derecho', 'function': 'Memoria visual'},
    'T7': {'region': 'Temporal Izquierdo', 'function': 'Audición, memoria auditiva'},
    'T8': {'region': 'Temporal Derecho', 'function': 'Audición, procesamiento musical'},
    'P3': {'region': 'Parietal Izquierdo', 'function': 'Sensación táctil, procesamiento espacial'},
    'P4': {'region': 'Parietal Derecho', 'function': 'Sensación táctil, orientación espacial'},
    'PZ': {'region': 'Parietal Central', 'function': 'Integración sensorial'},
    'O1': {'region': 'Occipital Izquierdo', 'function': 'Visión (campo visual derecho)'},
    'O2': {'region': 'Occipital Derecho', 'function': 'Visión (campo visual izquierdo)'},
    'OZ': {'region': 'Occipital Central', 'function': 'Procesamiento visual central'},
  };

  // lógica original SIN TOCAR ─────────────────────────────────────
  String _getChannelDescription() {
    final baseName = _channelName.split('-')[0].toUpperCase();
    if (channelInfo.containsKey(baseName)) {
      final info = channelInfo[baseName]!;
      return '${info['region']}  ·  ${info['function']}';
    }
    if (baseName.startsWith('F')) return 'Región Frontal  ·  Pensamiento, planificación, control motor';
    else if (baseName.startsWith('C')) return 'Región Central  ·  Movimiento y sensación del cuerpo';
    else if (baseName.startsWith('T')) return 'Región Temporal  ·  Audición, memoria, lenguaje';
    else if (baseName.startsWith('P')) return 'Región Parietal  ·  Sensación táctil, orientación espacial';
    else if (baseName.startsWith('O')) return 'Región Occipital  ·  Procesamiento visual';
    return 'Canal EEG  ·  Actividad eléctrica cerebral';
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _chartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _chartAnim = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOut);

    _entryCtrl.forward();
    _loadSignalData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _chartCtrl.dispose();
    _loadingCtrl.dispose();
    super.dispose();
  }

  // lógica original SIN TOCAR ─────────────────────────────────────
  Future<void> _loadSignalData() async {
    setState(() { _isLoading = true; _error = null; });
    _chartCtrl.reset();
    try {
      final response = await http.get(Uri.parse(
        'http://localhost:8000/api/analysis/${widget.analysisId}/signal'
        '?channel=$_currentChannel&start_sec=$_startTime&duration_sec=$_duration',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<double> timeList = List<double>.from(data['time']);
        final List<double> amplitudeList = List<double>.from(data['amplitude']);
        setState(() {
          _signalData = List.generate(
            timeList.length, (i) => FlSpot(timeList[i], amplitudeList[i]));
          _channelName = data['channel_name'];
          _samplingRate = data['sampling_rate'].toDouble();
          _availableChannels = List<Map<String, dynamic>>.from(data['available_channels']);
          _totalDuration = data['total_duration'].toDouble();
          _statistics = Map<String, double>.from(data['statistics']);
          _isLoading = false;
        });
        _chartCtrl.forward();
      } else {
        setState(() { _error = 'Error al cargar señal: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error de conexión: $e'; _isLoading = false; });
    }
  }

  void _changeChannel(int newChannel) {
    setState(() => _currentChannel = newChannel);
    _loadSignalData();
  }

  void _moveTimeWindow(double offset) {
    setState(() => _startTime = (_startTime + offset).clamp(0, _totalDuration - _duration));
    _loadSignalData();
  }

  void _changeDuration(double newDuration) {
    setState(() {
      _duration = newDuration.clamp(5, 30);
      if (_startTime + _duration > _totalDuration) {
        _startTime = (_totalDuration - _duration).clamp(0, _totalDuration);
      }
    });
    _loadSignalData();
  }

  // ── REGION color map ─────────────────────────────────────────────
  Color _regionColor(String name) {
    final b = name.split('-')[0].toUpperCase();
    if (b.startsWith('F')) return const Color(0xFF4F8EF7);
    if (b.startsWith('C')) return const Color(0xFF22C55E);
    if (b.startsWith('T')) return const Color(0xFFF59E0B);
    if (b.startsWith('P')) return const Color(0xFFEC4899);
    if (b.startsWith('O')) return const Color(0xFFEF4444);
    return const Color(0xFF8B5CF6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textSec, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Visualización de Ondas', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          Text(widget.fileName, style: const TextStyle(color: _textMut, fontSize: 10), overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSec, size: 20),
            onPressed: _loadSignalData,
            tooltip: 'Recargar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _entryAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                    child: Column(children: [
                      // ── Info strip ──────────────────────────────
                      _buildInfoStrip(),
                      const SizedBox(height: 14),
                      // ── Channel selector ────────────────────────
                      _buildChannelSelector(),
                      const SizedBox(height: 14),
                      // ── Main chart ──────────────────────────────
                      _buildChartCard(),
                      const SizedBox(height: 14),
                      // ── Time navigation ─────────────────────────
                      _buildNavigationCard(),
                      const SizedBox(height: 14),
                      // ── Statistics ──────────────────────────────
                      _buildStatsCard(),
                      const SizedBox(height: 14),
                      // ── Educational ─────────────────────────────
                      _buildEducationalCard(),
                      const SizedBox(height: 14),
                      // ── Brain regions guide ─────────────────────
                      _buildBrainGuideCard(),
                    ]),
                  ),
                ),
    );
  }

  // ── LOADING ──────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _loadingCtrl,
        builder: (ctx, _) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withAlpha(15),
            ),
          ),
          SizedBox(
            width: 70, height: 70,
            child: CircularProgressIndicator(
              value: null,
              strokeWidth: 2,
              color: _accent.withAlpha(200),
            ),
          ),
          const Icon(Icons.waves_rounded, color: _accent, size: 28),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Cargando señal EEG...', style: TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 6),
      const Text('Leyendo datos del canal cerebral', style: TextStyle(color: _textMut, fontSize: 12)),
    ]));
  }

  // ── ERROR ────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _red.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded, size: 44, color: _red),
        ),
        const SizedBox(height: 20),
        const Text('Error al cargar señal', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: _textSec, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadSignalData,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ));
  }

  // ── INFO STRIP ───────────────────────────────────────────────────
  Widget _buildInfoStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        _infoChip(Icons.speed_rounded, '${_samplingRate.toInt()} Hz', _accent),
        const SizedBox(width: 8),
        _infoChip(Icons.timer_rounded, '${_totalDuration.toStringAsFixed(1)}s', _green),
        const SizedBox(width: 8),
        _infoChip(Icons.hub_rounded, '${_availableChannels.length} canales', _amber),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(18), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center),
      ]),
    ));
  }

  // ── CHANNEL SELECTOR ─────────────────────────────────────────────
  Widget _buildChannelSelector() {
    final regionColor = _regionColor(_channelName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: regionColor.withAlpha(25), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: regionColor.withAlpha(70)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.electrical_services_rounded, color: regionColor, size: 13),
              const SizedBox(width: 5),
              Text('Canal activo', style: TextStyle(color: regionColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          Text(_channelName, style: TextStyle(color: regionColor, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 10),
        // Channel description
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: regionColor.withAlpha(12), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: regionColor.withAlpha(40)),
          ),
          child: Row(children: [
            Icon(Icons.place_rounded, color: regionColor, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(_getChannelDescription(),
                style: TextStyle(color: regionColor.withAlpha(200), fontSize: 12, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Seleccionar canal:', style: TextStyle(color: _textMut, fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: _availableChannels.take(12).map((ch) {
            final index = ch['index'] as int;
            final name  = ch['name'] as String;
            final isSel = index == _currentChannel;
            final c     = _regionColor(name);
            return GestureDetector(
              onTap: () { if (!isSel) _changeChannel(index); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? c.withAlpha(35) : _surfHi,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? c.withAlpha(120) : _border, width: isSel ? 1.5 : 1),
                ),
                child: Text(name, style: TextStyle(
                    color: isSel ? c : _textSec,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 11)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── CHART ────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    final regionColor = _regionColor(_channelName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: regionColor.withAlpha(15), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.show_chart_rounded, color: _accent, size: 16),
          const SizedBox(width: 8),
          const Text('Señal EEG', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: _surfHi, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${_startTime.toStringAsFixed(1)}s — ${(_startTime + _duration).toStringAsFixed(1)}s',
              style: const TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Amplitud en µV · Canal $_channelName', style: const TextStyle(color: _textMut, fontSize: 10)),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _chartAnim,
          builder: (ctx, _) => SizedBox(
            height: 240,
            child: Opacity(
              opacity: _chartAnim.value,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 0.5,
                    verticalInterval: _duration / 8,
                    getDrawingHorizontalLine: (_) => FlLine(color: _border, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) => FlLine(color: _border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                            style: const TextStyle(color: _textMut, fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: _duration / 5,
                        getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}s',
                            style: const TextStyle(color: _textMut, fontSize: 9)),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: _border, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _signalData,
                      isCurved: false,
                      gradient: LinearGradient(
                        colors: [regionColor.withAlpha(200), regionColor],
                      ),
                      barWidth: 1.3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [regionColor.withAlpha(40), regionColor.withAlpha(0)],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: _surfHi,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(2)} µV\n${s.x.toStringAsFixed(2)}s',
                          TextStyle(color: regionColor, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── NAVIGATION ───────────────────────────────────────────────────
  Widget _buildNavigationCard() {
    final progress = _totalDuration > 0 ? (_startTime / (_totalDuration - _duration)).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.timeline_rounded, color: _textSec, size: 15),
          SizedBox(width: 8),
          Text('Navegación temporal', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0s', style: const TextStyle(color: _textMut, fontSize: 10)),
          Text('${_totalDuration.toStringAsFixed(1)}s', style: const TextStyle(color: _textMut, fontSize: 10)),
        ]),
        const SizedBox(height: 14),
        // Nav buttons
        Row(children: [
          Expanded(child: _navBtn(
            icon: Icons.skip_previous_rounded,
            label: '← Anterior',
            onTap: _startTime > 0 ? () => _moveTimeWindow(-_duration) : null,
          )),
          const SizedBox(width: 10),
          Expanded(child: _navBtn(
            icon: Icons.skip_next_rounded,
            label: 'Siguiente →',
            onTap: _startTime + _duration < _totalDuration ? () => _moveTimeWindow(_duration) : null,
            right: true,
          )),
        ]),
        const SizedBox(height: 16),
        // Duration slider
        Row(children: [
          const Icon(Icons.open_in_full_rounded, color: _textMut, size: 14),
          const SizedBox(width: 8),
          Text('Ventana: ${_duration.toInt()}s', style: const TextStyle(color: _textSec, fontSize: 12)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: _accent,
            inactiveTrackColor: _border,
            thumbColor: _accent,
            overlayColor: _accent.withAlpha(30),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _duration, min: 5, max: 30, divisions: 5,
            label: '${_duration.toInt()}s',
            onChanged: _changeDuration,
          ),
        ),
      ]),
    );
  }

  Widget _navBtn({required IconData icon, required String label, VoidCallback? onTap, bool right = false}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? _accent.withAlpha(20) : _surfHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? _accent.withAlpha(80) : _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: right
              ? [Text(label, style: TextStyle(color: enabled ? _accent : _textMut, fontWeight: FontWeight.w600, fontSize: 12)),
                 const SizedBox(width: 6),
                 Icon(icon, color: enabled ? _accent : _textMut, size: 16)]
              : [Icon(icon, color: enabled ? _accent : _textMut, size: 16),
                 const SizedBox(width: 6),
                 Text(label, style: TextStyle(color: enabled ? _accent : _textMut, fontWeight: FontWeight.w600, fontSize: 12))],
        ),
      ),
    );
  }

  // ── STATS ────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    final stats = [
      ('Media', _statistics['mean'], _accent),
      ('Desv. Estándar', _statistics['std'], _amber),
      ('Mínimo', _statistics['min'], _green),
      ('Máximo', _statistics['max'], _red),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bar_chart_rounded, color: _textSec, size: 15),
          SizedBox(width: 8),
          Text('Estadísticas del segmento', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        Row(children: stats.map((s) => Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: s.$3.withAlpha(15), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: s.$3.withAlpha(40)),
          ),
          child: Column(children: [
            Text(
              s.$2 != null ? '${s.$2!.toStringAsFixed(1)}' : '—',
              style: TextStyle(color: s.$3, fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 3),
            Text('µV', style: TextStyle(color: s.$3.withAlpha(150), fontSize: 9)),
            const SizedBox(height: 4),
            Text(s.$1, style: const TextStyle(color: _textMut, fontSize: 9), textAlign: TextAlign.center),
          ]),
        ))).toList()),
      ]),
    );
  }

  // ── EDUCATIONAL ──────────────────────────────────────────────────
  Widget _buildEducationalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withAlpha(50)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _accent.withAlpha(25), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.info_outline_rounded, color: _accent, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('¿Qué estoy viendo?', style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Esta gráfica muestra la actividad eléctrica de tu cerebro medida en microvoltios (µV). '
          'Las ondas representan las "conversaciones" entre neuronas. '
          'Patrones normales muestran ondas suaves y rítmicas, mientras que actividad epiléptica '
          'puede mostrar picos bruscos (spikes) o descargas repetitivas.',
          style: TextStyle(color: _textSec, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }

  // ── BRAIN GUIDE ──────────────────────────────────────────────────
  Widget _buildBrainGuideCard() {
    final regions = [
      ('Frontal (F)', 'Pensamiento, planificación, movimiento voluntario', const Color(0xFF4F8EF7)),
      ('Central (C)', 'Movimiento y sensación del cuerpo', const Color(0xFF22C55E)),
      ('Temporal (T)', 'Audición, memoria, lenguaje', const Color(0xFFF59E0B)),
      ('Parietal (P)', 'Sensación táctil, orientación espacial', const Color(0xFFEC4899)),
      ('Occipital (O)', 'Visión y procesamiento visual', const Color(0xFFEF4444)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            const Icon(Icons.psychology_rounded, color: _textSec, size: 16),
            const SizedBox(width: 8),
            const Text('Guía de regiones cerebrales', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        Container(height: 1, color: _border),
        ...regions.map((r) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: r.$3.withAlpha(100), blurRadius: 6)]),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.$1, style: TextStyle(color: r.$3, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                Text(r.$2, style: const TextStyle(color: _textSec, fontSize: 11)),
              ]),
            ]),
          ),
          if (r.$1 != regions.last.$1) Container(height: 1, color: _border),
        ])),
      ]),
    );
  }
}
