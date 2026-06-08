import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'services/intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final locale = prefs.getString('locale') ?? '';
  final hasLaunchedBefore = prefs.getBool('has_launched') ?? false;

  // If the app was launched by opening a PDF in another app (file manager,
  // WhatsApp, share sheet), go straight to the viewer instead of the home
  // screen, so the document opens immediately and "back" returns to that app.
  final initialUri = await IntentService.getInitialUri();

  runApp(PDFNoAdsApp(
    initialLocale: locale.isNotEmpty ? locale : 'en',
    showSplash: !hasLaunchedBefore || locale.isEmpty,
    initialUri: initialUri,
  ));
}

class PDFNoAdsApp extends StatefulWidget {
  final String initialLocale;
  final bool showSplash;
  final String? initialUri;

  const PDFNoAdsApp({
    super.key,
    required this.initialLocale,
    required this.showSplash,
    this.initialUri,
  });

  static void setLocale(BuildContext context, String locale) {
    final state = context.findAncestorStateOfType<_PDFNoAdsAppState>();
    state?.setLocale(locale);
  }

  @override
  State<PDFNoAdsApp> createState() => _PDFNoAdsAppState();
}

class _PDFNoAdsAppState extends State<PDFNoAdsApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catches PDFs opened from another app while we are already running.
    if (state == AppLifecycleState.resumed) {
      _handleWarmIntent();
    }
  }

  Future<void> _handleWarmIntent() async {
    final uri = await IntentService.getInitialUri();
    if (uri == null) return;
    _navKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: uri, locale: _locale),
      ),
    );
  }

  void setLocale(String locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then((p) {
      p.setString('locale', locale);
      p.setBool('has_launched', true);
    });
  }

  Widget _buildHome() {
    if (widget.initialUri != null) {
      return PdfViewerScreen(
        filePath: widget.initialUri!,
        locale: _locale,
        fromExternal: true,
      );
    }
    return widget.showSplash
        ? SplashScreen(locale: _locale)
        : HomeScreen(locale: _locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF No Ads',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: _buildHome(),
    );
  }
}
