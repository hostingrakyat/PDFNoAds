import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_credits.dart';
import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final String locale;
  const SplashScreen({super.key, required this.locale});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _selectedLocale = 'en';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.locale;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _selectedLocale);
    if (!mounted) return;
    PDFNoAdsApp.setLocale(context, _selectedLocale);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(locale: _selectedLocale),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              cs.primary.withOpacity(0.85),
              const Color(0xFF0D1B3E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // App name
                          const Text(
                            'PDF No Ads',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedLocale == 'id'
                                ? 'Gratis • Tanpa Iklan • Selamanya'
                                : 'Free • No Ads • Forever',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 56),
                          // Language selection label
                          Text(
                            _selectedLocale == 'id'
                                ? 'Pilih Bahasa'
                                : 'Select Language',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Language buttons
                          Row(
                            children: [
                              Expanded(
                                child: _LangButton(
                                  label: '🇺🇸  English',
                                  selected: _selectedLocale == 'en',
                                  onTap: () =>
                                      setState(() => _selectedLocale = 'en'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LangButton(
                                  label: '🇮🇩  Indonesia',
                                  selected: _selectedLocale == 'id',
                                  onTap: () =>
                                      setState(() => _selectedLocale = 'id'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _continue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: cs.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _selectedLocale == 'id'
                                    ? 'Lanjutkan'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 365 challenge badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              _selectedLocale == 'id'
                                  ? '🚀  365 Hari Tantangan Aplikasi  •  Hari 1'
                                  : '🚀  365 Days App Challenge  •  Day 1',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom credits
              BottomCredits(locale: _selectedLocale, dark: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
