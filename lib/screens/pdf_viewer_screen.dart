import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/bottom_credits.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String locale;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.locale,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const _intentChannel = MethodChannel('com.pdfnoads.app/intent');

  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _showUi = true;
  bool _nightMode = false;
  String? _localPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  /// For content:// URIs we must copy the file to a local temp path first.
  Future<void> _prepareFile() async {
    final path = widget.filePath;
    if (path.startsWith('content://')) {
      try {
        final bytes =
            await _intentChannel.invokeMethod<Uint8List>('readUri', {'uri': path});
        if (bytes == null) throw Exception('Could not read file');
        final dir = await getTemporaryDirectory();
        final name = _extractName(path);
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        if (mounted) setState(() => _localPath = file.path);
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
      }
    } else {
      final resolved = path.startsWith('file://')
          ? Uri.parse(path).toFilePath()
          : path;
      setState(() => _localPath = resolved);
    }
  }

  String _extractName(String path) {
    final decoded = Uri.decodeFull(path);
    final parts = decoded.split('/');
    var name = parts.isNotEmpty ? parts.last : 'document.pdf';
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
    return name;
  }

  String get _displayName => _extractName(widget.filePath);

  void _toggleUi() => setState(() => _showUi = !_showUi);

  void _prevPage() {
    if (_currentPage > 0) {
      _pdfController?.setPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pdfController?.setPage(_currentPage + 1);
    }
  }

  void _showSetDefault() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _SetDefaultSheet(locale: widget.locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _nightMode ? const Color(0xFF121212) : cs.surface,
      body: Stack(
        children: [
          // GestureDetector only covers the PDF area so bar buttons stay tappable
          GestureDetector(
            onTap: _toggleUi,
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 56, color: cs.error),
                            const SizedBox(height: 16),
                            Text(
                              widget.locale == 'id'
                                  ? 'Gagal membuka file'
                                  : 'Failed to open file',
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style:
                                  TextStyle(fontSize: 12, color: cs.outline),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _localPath != null
                      ? PDFView(
                          filePath: _localPath!,
                          nightMode: _nightMode,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          defaultPage: 0,
                          onRender: (pages) {
                            setState(() {
                              _totalPages = pages ?? 0;
                              _isLoading = false;
                            });
                            // flutter_pdfview shows blank until a setPage call
                            // triggers the native view to paint the first page.
                            Future.microtask(
                                () => _pdfController?.setPage(0));
                          },
                          onViewCreated: (ctrl) => _pdfController = ctrl,
                          onPageChanged: (page, total) {
                            setState(() {
                              _currentPage = page ?? 0;
                              _totalPages = total ?? 0;
                            });
                          },
                          onError: (e) =>
                              setState(() => _error = e.toString()),
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),

          // Loading overlay
          if (_isLoading && _localPath != null && _error == null)
            const Center(child: CircularProgressIndicator()),

          // Top AppBar (slides in/out)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showUi ? 0 : -120,
            left: 0,
            right: 0,
            child: _TopBar(
              name: _displayName,
              nightMode: _nightMode,
              locale: widget.locale,
              onBack: () => Navigator.pop(context),
              onNightMode: () => setState(() => _nightMode = !_nightMode),
              onSetDefault: _showSetDefault,
            ),
          ),

          // Bottom page bar (slides in/out)
          if (_totalPages > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showUi ? 0 : -120,
              left: 0,
              right: 0,
              child: _BottomPageBar(
                currentPage: _currentPage,
                totalPages: _totalPages,
                locale: widget.locale,
                onPrev: _prevPage,
                onNext: _nextPage,
                credits: BottomCredits(
                  locale: widget.locale,
                  dark: _nightMode,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final bool nightMode;
  final String locale;
  final VoidCallback onBack;
  final VoidCallback onNightMode;
  final VoidCallback onSetDefault;

  const _TopBar({
    required this.name,
    required this.nightMode,
    required this.locale,
    required this.onBack,
    required this.onNightMode,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: nightMode
            ? const Color(0xFF1E1E1E)
            : cs.surface.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: nightMode ? Colors.white : cs.onSurface,
              ),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: nightMode ? Colors.white : cs.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                nightMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: nightMode ? Colors.white : cs.onSurface,
              ),
              onPressed: onNightMode,
            ),
            IconButton(
              icon: Icon(
                Icons.open_in_new_rounded,
                color: nightMode ? Colors.white : cs.onSurface,
              ),
              tooltip: locale == 'id'
                  ? 'Jadikan Default'
                  : 'Set as Default',
              onPressed: onSetDefault,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPageBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String locale;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Widget credits;

  const _BottomPageBar({
    required this.currentPage,
    required this.totalPages,
    required this.locale,
    required this.onPrev,
    required this.onNext,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: currentPage > 0 ? onPrev : null,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHigh,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${locale == 'id' ? 'Hal' : 'Page'} ${currentPage + 1} / $totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: currentPage < totalPages - 1 ? onNext : null,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
            ),
            credits,
          ],
        ),
      ),
    );
  }
}

class _SetDefaultSheet extends StatelessWidget {
  final String locale;
  const _SetDefaultSheet({required this.locale});

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
          Icon(Icons.verified_rounded, color: cs.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            locale == 'id'
                ? 'Jadikan Aplikasi PDF Default'
                : 'Set as Default PDF App',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            locale == 'id'
                ? '1. Buka Pengaturan → Aplikasi\n2. Pilih "PDF No Ads"\n3. Ketuk "Buka secara default"\n4. Aktifkan sebagai default'
                : '1. Open Settings → Apps\n2. Find "PDF No Ads"\n3. Tap "Open by default"\n4. Enable as default',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                const ch = MethodChannel('com.pdfnoads.app/intent');
                ch.invokeMethod('openDefaultApps').catchError((_) {});
              },
              icon: const Icon(Icons.settings_rounded),
              label: Text(locale == 'id' ? 'Buka Pengaturan' : 'Open Settings'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
