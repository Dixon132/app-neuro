// Onboarding screen with 3 slides + medical disclaimer

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _disclaimerAccepted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      icon: Icons.psychology_rounded,
      title: 'NeuroScan AI',
      subtitle: 'Sistema de Análisis EEG',
      description:
          'Una plataforma inteligente diseñada para asistir en el estudio cuantitativo de señales cerebrales mediante algoritmos de Machine Learning avanzados.',
      gradientStart: Color(0xFF6366F1),
      gradientEnd: Color(0xFF8B5CF6),
    ),
    _OnboardSlide(
      icon: Icons.biotech_rounded,
      title: '¿Qué Analizamos?',
      subtitle: 'Procesamiento científico de señales EEG',
      description:
          'Estudiamos las amplitudes de las ondas cerebrales:\n\n'
          '🔵 Delta (0.5–4 Hz) · sueño profundo\n'
          '🟣 Theta (4–8 Hz) · somnolencia\n'
          '🟢 Alpha (8–13 Hz) · relajación\n'
          '🟡 Beta (13–30 Hz) · concentración\n'
          '🔴 Gamma (30–50 Hz) · cognición\n\n'
          'Detectamos picos anómalos (spikes) y patrones de alta energía asociados a actividad epiléptica.',
      gradientStart: Color(0xFF0EA5E9),
      gradientEnd: Color(0xFF6366F1),
    ),
    _OnboardSlide(
      icon: Icons.shield_rounded,
      title: 'Aviso Médico',
      subtitle: 'Antes de continuar, lea con atención',
      description: '',
      gradientStart: Color(0xFF8B5CF6),
      gradientEnd: Color(0xFFEC4899),
      isDisclaimer: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  bool get _canProceed {
    if (_currentPage == _slides.length - 1) return _disclaimerAccepted;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [slide.gradientStart, slide.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_currentPage < _slides.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Saltar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 56),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (ctx, i) {
                    final s = _slides[i];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: s.isDisclaimer
                          ? _buildDisclaimerPage()
                          : _buildInfoPage(s),
                    );
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            i == _currentPage ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Action button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: AnimatedOpacity(
                  opacity: _canProceed ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: slide.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _canProceed
                          ? (_currentPage == _slides.length - 1
                              ? _goToLogin
                              : _nextPage)
                          : null,
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Iniciar Sesión'
                            : 'Siguiente →',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPage(_OnboardSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              slide.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.7,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded,
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aviso Legal y Médico',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Por favor, lea este aviso con atención antes de usar la aplicación.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(33),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _disclaimerPoint(
                  Icons.warning_amber_rounded,
                  'Solo Asistencia Tecnológica',
                  'Esta aplicación es una herramienta de análisis cuantitativo basada en Machine Learning. NO diagnostica patologías de ningún tipo.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _disclaimerPoint(
                  Icons.local_hospital_rounded,
                  'No Sustituye al Médico',
                  'Los resultados mostrados NO reemplazan la evaluación de un médico neurólogo o especialista calificado. Siempre consulte a un profesional.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _disclaimerPoint(
                  Icons.bar_chart_rounded,
                  'Naturaleza de los Resultados',
                  'Los valores de riesgo (Bajo / Moderado / Alto) son estimaciones estadísticas basadas en patrones matemáticos, no conclusiones clínicas definitivas.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _disclaimerPoint(
                  Icons.gavel_rounded,
                  'Responsabilidad',
                  'El uso de esta aplicación para tomar decisiones médicas autónomas es responsabilidad exclusiva del usuario.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () =>
                setState(() => _disclaimerAccepted = !_disclaimerAccepted),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _disclaimerAccepted
                    ? Colors.white.withAlpha(64)
                    : Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _disclaimerAccepted ? Colors.white : Colors.white38,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _disclaimerAccepted
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _disclaimerAccepted
                        ? const Icon(Icons.check,
                            size: 16, color: Color(0xFF8B5CF6))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'He leído y comprendo que esta aplicación no diagnostica ni sustituye la evaluación médica profesional.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _disclaimerPoint(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isDisclaimer;

  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradientStart,
    required this.gradientEnd,
    this.isDisclaimer = false,
  });
}
