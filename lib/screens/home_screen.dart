import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../widgets/bottom_credits.dart';
import '../l10n/strings.dart';
import 'pdf_viewer_screen.dart';
import 'splash_screen.dart';

class HomeScreen extends StatefulWidget {
  final String locale;
  const HomeScreen({super.key, required this.locale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _intentChannel = MethodChannel('com.pdfnoads.app/intent');
  late AppStrings _s;
  List<String> _recentFiles = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _s = AppStrings(widget.locale);
    _loadRecent();
    _checkIncomingIntent();
  }

  Future<void> _checkIncomingIntent() async {
    try {
      final uri = await _intentChannel.invokeMethod<String>('getInitialUri');
      if (uri != null && mounted) {
        _openFromUri(uri);
      }
    } catch (_) {}
  }

  Future<void> _openFromUri(String uri) async {
    await _saveRecent(uri);
    if (!mounted) return;
    _navigateToPdf(uri);
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_files') ?? [];
    // Filter to only existing files
    final valid = list.where((f) {
      if (f.startsWith('content://') || f.startsWith('file://')) return true;
      return File(f).existsSync();
    }).toList();
    if (mounted) setState(() => _recentFiles = valid);
  }

  Future<void> _saveRecent(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_files') ?? [];
    list.remove(path);
    list.insert(0, path);
    if (list.length > 20) list.removeLast();
    await prefs.setStringList('recent_files', list);
    if (mounted) setState(() => _recentFiles = list);
  }

  Future<void> _pickFile() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path ?? file.identifier;
        if (path != null) {
          await _saveRecent(path);
          if (mounted) _navigateToPdf(path);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToPdf(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: path, locale: widget.locale),
      ),
    );
  }

  String _displayName(String path) {
    if (path.startsWith('content://')) {
      final decoded = Uri.decodeFull(path);
      final parts = decoded.split('/');
      return parts.isNotEmpty ? parts.last : path;
    }
    return p.basename(path);
  }

  void _removeRecent(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_files') ?? [];
    list.remove(path);
    await prefs.setStringList('recent_files', list);
    setState(() => _recentFiles.remove(path));
  }

  void _changeLanguage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SplashScreen(locale: widget.locale),
      ),
    );
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AboutSheet(locale: widget.locale),
    );
  }

  void _showSetDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.get('setDefault')),
        content: Text(_s.get('setDefaultDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_s.get('defaultSet')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _intentChannel.invokeMethod('openDefaultApps').catchError((_) {});
            },
            child: Text(_s.get('settings')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.picture_as_pdf_rounded,
                  color: cs.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'PDF No Ads',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: widget.locale == 'id' ? 'Bahasa' : 'Language',
            onPressed: _changeLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: _s.get('about'),
            onPressed: _showAbout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Set as default banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: _showSetDefault,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer,
                        cs.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: cs.onPrimaryContainer, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _s.get('setDefault'),
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: cs.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Recent files header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _s.get('recentFiles'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_recentFiles.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('recent_files', []);
                        setState(() => _recentFiles.clear());
                      },
                      child: Text(
                        widget.locale == 'id' ? 'Hapus Semua' : 'Clear All',
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _recentFiles.isEmpty
                  ? _EmptyState(locale: widget.locale)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recentFiles.length,
                      itemBuilder: (ctx, i) {
                        final path = _recentFiles[i];
                        return _RecentFileCard(
                          name: _displayName(path),
                          path: path,
                          locale: widget.locale,
                          onTap: () {
                            _saveRecent(path);
                            _navigateToPdf(path);
                          },
                          onDelete: () => _removeRecent(path),
                        );
                      },
                    ),
            ),
            BottomCredits(locale: widget.locale),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _pickFile,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.folder_open_rounded),
        label: Text(_s.get('openPdf')),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String locale;
  const _EmptyState({required this.locale});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 72, color: cs.outline.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            locale == 'id'
                ? 'Belum ada file.\nKetuk tombol di bawah untuk membuka PDF.'
                : 'No recent files.\nTap the button below to open a PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.outline,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  final String name;
  final String path;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentFileCard({
    required this.name,
    required this.path,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.picture_as_pdf_rounded,
                    color: cs.error, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale == 'id' ? 'Ketuk untuk membuka' : 'Tap to open',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  final String locale;
  const _AboutSheet({required this.locale});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.picture_as_pdf_rounded,
                color: cs.onPrimaryContainer, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'PDF No Ads',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.1',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            locale == 'id'
                ? 'Gratis. Tanpa Iklan. Selamanya.\n\nBagian dari 365 Hari Tantangan Aplikasi\n1 hari · 1 aplikasi · Tanpa iklan'
                : 'Free. No Ads. Forever.\n\nPart of the 365 Days App Challenge\n1 day · 1 app · No ads',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          BottomCredits(locale: locale),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
