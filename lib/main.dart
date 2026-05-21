import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final locale = prefs.getString('locale') ?? '';
  final hasLaunchedBefore = prefs.getBool('has_launched') ?? false;
  runApp(PDFNoAdsApp(
    initialLocale: locale.isNotEmpty ? locale : 'en',
    showSplash: !hasLaunchedBefore || locale.isEmpty,
  ));
}

class PDFNoAdsApp extends StatefulWidget {
  final String initialLocale;
  final bool showSplash;

  const PDFNoAdsApp({
    super.key,
    required this.initialLocale,
    required this.showSplash,
  });

  static _PDFNoAdsAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_PDFNoAdsAppState>();

  @override
  State<PDFNoAdsApp> createState() => _PDFNoAdsAppState();
}

class _PDFNoAdsAppState extends State<PDFNoAdsApp> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void setLocale(String locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then((p) {
      p.setString('locale', locale);
      p.setBool('has_launched', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF No Ads',
      debugShowCheckedModeBanner: false,
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
      home: widget.showSplash
          ? SplashScreen(locale: _locale)
          : HomeScreen(locale: _locale),
    );
  }
}
