import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../providers/analysis_provider.dart';
import '../../services/api_service.dart';

class EEGUploadScreen extends ConsumerStatefulWidget {
  const EEGUploadScreen({super.key});

  @override
  ConsumerState<EEGUploadScreen> createState() => _EEGUploadScreenState();
}

class _EEGUploadScreenState extends ConsumerState<EEGUploadScreen>
    with TickerProviderStateMixin {
  // ── lógica original intacta ──────────────────────────────────────
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  // ── animaciones ──────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _entryAnim;
  late Animation<Offset> _slideAnim;

  // ── paleta enterprise ────────────────────────────────────────────
  static const _bg       = Color(0xFF08090F);
  static const _surface  = Color(0xFF111318);
  static const _surfHi   = Color(0xFF1A1D27);
  static const _border   = Color(0xFF222533);
  static const _accent   = Color(0xFF4F8EF7);
  static const _accentLo = Color(0xFF2D5FCC);
  static const _green    = Color(0xFF22C55E);
  static const _red      = Color(0xFFEF4444);
  static const _textPri  = Color(0xFFE8EAF0);
  static const _textSec  = Color(0xFF8B90A0);
  static const _textMut  = Color(0xFF4A4F62);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── lógica original sin tocar ────────────────────────────────────
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['edf', 'csv'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _fileBytes = result.files.single.bytes;
      });
      _entryCtrl.forward(from: 0);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seleccione un archivo primero'),
          backgroundColor: _surfHi,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.uploadEEGBytes(_fileBytes!, _selectedFile!.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: _green, size: 18),
            SizedBox(width: 10),
            Text('Análisis completado exitosamente', style: TextStyle(color: _textPri)),
          ]),
          backgroundColor: _surfHi,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        final analysisId = response['id'] as int;
        Navigator.pushReplacementNamed(context, '/analysis-detail', arguments: analysisId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.white)),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nuevo análisis', style: TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          Text('Subir archivo EEG', style: TextStyle(color: _textMut, fontSize: 10)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: FadeTransition(
        opacity: _entryAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: Column(children: [
              // ── Hero upload zone ─────────────────────────────────
              _buildUploadHero(),
              const SizedBox(height: 28),

              // ── File info card (si está seleccionado) ────────────
              if (_selectedFile != null) ...[
                _buildFileCard(),
                const SizedBox(height: 24),
              ],

              // ── Formats info strip ───────────────────────────────
              _buildFormatsStrip(),
              const SizedBox(height: 28),

              // ── Action buttons ───────────────────────────────────
              _buildButtons(),
              const SizedBox(height: 24),

              // ── Processing steps info ────────────────────────────
              if (_isUploading) _buildProcessingSteps(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadHero() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _selectedFile != null
                  ? _green.withAlpha(100)
                  : _accent.withAlpha((_isUploading ? 60 : 40).round()),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_selectedFile != null ? _green : _accent).withAlpha(18),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: [
            // Animated brain icon
            ScaleTransition(
              scale: _pulseAnim,
              child: Stack(alignment: Alignment.center, children: [
                // Outer glow ring
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_selectedFile != null ? _green : _accent).withAlpha(15),
                  ),
                ),
                // Middle ring
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_selectedFile != null ? _green : _accent).withAlpha(25),
                    border: Border.all(
                      color: (_selectedFile != null ? _green : _accent).withAlpha(60),
                      width: 1,
                    ),
                  ),
                ),
                // Icon core
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _selectedFile != null
                          ? [_green, const Color(0xFF16A34A)]
                          : [_accent, _accentLo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedFile != null ? _green : _accent).withAlpha(100),
                        blurRadius: 20, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _selectedFile != null
                        ? Icons.check_rounded
                        : (_isUploading ? Icons.hourglass_top_rounded : Icons.upload_file_rounded),
                    color: Colors.white, size: 30,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // Animated EEG waveform decoration
            _buildMiniWave(),
            const SizedBox(height: 20),
            Text(
              _selectedFile != null
                  ? 'Archivo listo para analizar'
                  : (_isUploading ? 'Procesando señales...' : 'Selecciona tu archivo EEG'),
              style: TextStyle(
                color: _selectedFile != null ? _green : _textPri,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFile != null
                  ? 'La IA analizará la señal cerebral completa'
                  : 'El sistema procesará automáticamente los canales cerebrales',
              style: const TextStyle(color: _textSec, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ]),
        );
      },
    );
  }

  Widget _buildMiniWave() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (ctx, _) {
        return SizedBox(
          width: 200, height: 32,
          child: CustomPaint(
            painter: _WavePainter(
              progress: _waveCtrl.value,
              color: _selectedFile != null ? _green : _accent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileCard() {
    final sizeKB = (_fileBytes!.length / 1024).toStringAsFixed(1);
    final ext = _selectedFile!.name.split('.').last.toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withAlpha(70)),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _green.withAlpha(28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withAlpha(60)),
          ),
          child: Center(child: Text(ext,
              style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 11))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_selectedFile!.name,
              style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('$sizeKB KB  ·  Formato $ext',
              style: const TextStyle(color: _textSec, fontSize: 11)),
        ])),
        GestureDetector(
          onTap: () => setState(() { _selectedFile = null; _fileBytes = null; }),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, color: _red, size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildFormatsStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: _textMut, size: 16),
        const SizedBox(width: 10),
        const Expanded(child: Text('Formatos soportados',
            style: TextStyle(color: _textSec, fontSize: 12))),
        _formatBadge('EDF', _accent),
        const SizedBox(width: 8),
        _formatBadge('CSV', const Color(0xFF8B5CF6)),
      ]),
    );
  }

  Widget _formatBadge(String ext, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(ext, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Widget _buildButtons() {
    return Column(children: [
      // Pick file button
      SizedBox(
        width: double.infinity, height: 52,
        child: OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickFile,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _accent.withAlpha(100)),
            foregroundColor: _accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.folder_open_rounded, size: 19),
          label: Text(
            _selectedFile == null ? 'Seleccionar archivo' : 'Cambiar archivo',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Upload button
      AnimatedOpacity(
        opacity: _selectedFile != null ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: _isUploading
                  ? [_textMut, _textMut]
                  : [_accent, _accentLo],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: _selectedFile != null && !_isUploading
                ? [BoxShadow(color: _accent.withAlpha(90), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: ElevatedButton.icon(
            onPressed: _isUploading || _selectedFile == null ? null : _uploadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isUploading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 19),
            label: Text(
              _isUploading ? 'Analizando señal EEG...' : 'Subir y analizar',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildProcessingSteps() {
    final steps = [
      (Icons.filter_alt_rounded, 'Aplicando filtros de señal', 'Notch 50 Hz · Butterworth 0.5–50 Hz'),
      (Icons.window_rounded, 'Segmentando en ventanas', 'Bloques de 5s con 50% solapamiento'),
      (Icons.analytics_rounded, 'Extrayendo biomarcadores', '138 características por canal'),
      (Icons.psychology_rounded, 'Modelo IA clasificando', 'Gradient Boosting · CHB-MIT calibrado'),
    ];

    return AnimatedOpacity(
      opacity: _isUploading ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withAlpha(50)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.memory_rounded, color: _accent, size: 16),
            SizedBox(width: 8),
            Text('Pipeline de procesamiento activo',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: _accent.withAlpha(20), borderRadius: BorderRadius.circular(9)),
                child: Icon(s.$1, color: _accent, size: 14),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: const TextStyle(color: _textPri, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(s.$3, style: const TextStyle(color: _textMut, fontSize: 10)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── Wave painter animado ─────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final amplitude = h * 0.38;

    path.moveTo(0, mid);
    for (double x = 0; x <= w; x++) {
      final phase = (x / w) * 4 * math.pi + (progress * 2 * math.pi);
      // Simulated EEG-like waveform: sum of two sine waves
      final y = mid - amplitude * (0.6 * math.sin(phase) + 0.25 * math.sin(phase * 2.3 + 0.7));
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Fade mask on edges
    final fadePaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF111318), Colors.transparent, Colors.transparent, const Color(0xFF111318)],
        stops: const [0, 0.08, 0.92, 1],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fadePaint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
