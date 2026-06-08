import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../services/intent_service.dart';
import '../services/pdf_loader.dart';
import '../services/recent_files.dart';
import '../widgets/bottom_credits.dart';

/// Inverts colours for night-mode reading (white pages → dark).
const ColorFilter _invertFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
]);

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String locale;

  /// True when the screen is the app's root because it was launched from
  /// another app (file manager, WhatsApp, share sheet). In that case "back"
  /// must return to the calling app, not to the PDF No Ads home screen.
  final bool fromExternal;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.locale,
    this.fromExternal = false,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();

  LoadedPdf? _pdf;
  String? _error;
  bool _ready = false;
  bool _nightMode = false;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final pdf = await PdfLoader.resolve(widget.filePath);
      if (!mounted) return;
      setState(() => _pdf = pdf);
      await RecentFiles.add(RecentFile(path: pdf.path, name: pdf.name));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  bool get _isId => widget.locale == 'id';

  void _back() {
    if (widget.fromExternal) {
      // Finish the activity → returns to whichever app launched us.
      SystemNavigator.pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevPage() {
    if (_ready && _currentPage > 1) {
      _controller.goToPage(pageNumber: _currentPage - 1);
    }
  }

  void _nextPage() {
    if (_ready && _currentPage < _totalPages) {
      _controller.goToPage(pageNumber: _currentPage + 1);
    }
  }

  Future<void> _share() async {
    final pdf = _pdf;
    if (pdf == null) return;
    try {
      await IntentService.shareFile(pdf.path, name: pdf.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isId ? 'Gagal membagikan file' : 'Could not share file'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _nightMode ? const Color(0xFF121212) : const Color(0xFFE9E9EE);

    return PopScope(
      // When launched externally we are the root route, so the framework can't
      // pop. Intercept and finish the activity to return to the calling app.
      canPop: !widget.fromExternal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.fromExternal) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor:
              _nightMode ? const Color(0xFF1E1E1E) : cs.surface,
          foregroundColor: _nightMode ? Colors.white : cs.onSurface,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _back,
          ),
          title: Text(
            _pdf?.name ?? (_isId ? 'Membuka…' : 'Opening…'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: _isId ? 'Mode Malam' : 'Night Mode',
              icon: Icon(_nightMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              onPressed: () => setState(() => _nightMode = !_nightMode),
            ),
            IconButton(
              tooltip: _isId ? 'Bagikan' : 'Share',
              icon: const Icon(Icons.share_rounded),
              onPressed: _pdf != null ? _share : null,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: (_ready && _totalPages > 0)
            ? _BottomPageBar(
                currentPage: _currentPage,
                totalPages: _totalPages,
                locale: widget.locale,
                onPrev: _currentPage > 1 ? _prevPage : null,
                onNext: _currentPage < _totalPages ? _nextPage : null,
                credits: BottomCredits(locale: widget.locale, dark: _nightMode),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorView(message: _error!, isId: _isId, onBack: _back);
    }
    final pdf = _pdf;
    if (pdf == null) {
      return _LoadingView(isId: _isId, nightMode: _nightMode);
    }

    Widget viewer = PdfViewer.file(
      pdf.path,
      controller: _controller,
      params: PdfViewerParams(
        // Real text layer → tap-and-hold to select, then copy.
        enableTextSelection: true,
        backgroundColor:
            _nightMode ? const Color(0xFF121212) : const Color(0xFFE9E9EE),
        margin: 8,
        maxScale: 8,
        onViewerReady: (document, controller) {
          if (!mounted) return;
          setState(() {
            _ready = true;
            _totalPages = controller.pageCount;
            _currentPage = controller.pageNumber ?? 1;
          });
        },
        onPageChanged: (pageNumber) {
          if (!mounted || pageNumber == null) return;
          setState(() => _currentPage = pageNumber);
        },
      ),
    );

    if (_nightMode) {
      viewer = ColorFiltered(colorFilter: _invertFilter, child: viewer);
    }

    return Stack(
      children: [
        Positioned.fill(child: viewer),
        if (!_ready)
          Positioned.fill(
            child: _LoadingView(isId: _isId, nightMode: _nightMode),
          ),
      ],
    );
  }
}

// ─── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final bool isId;
  final bool nightMode;

  const _LoadingView({required this.isId, required this.nightMode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = nightMode ? const Color(0xFF121212) : cs.surface;
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.picture_as_pdf_rounded,
                  size: 44, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
            ),
            const SizedBox(height: 18),
            Text(
              isId ? 'Membuka PDF…' : 'Opening PDF…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: nightMode ? Colors.white70 : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final bool isId;
  final VoidCallback onBack;

  const _ErrorView({
    required this.message,
    required this.isId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(
              isId ? 'Gagal membuka file' : 'Failed to open file',
              style: TextStyle(
                fontSize: 16,
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              child: Text(isId ? 'Kembali' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom page bar ──────────────────────────────────────────────────────────

class _BottomPageBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String locale;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
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
                    onPressed: onPrev,
                    style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHigh),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${locale == 'id' ? 'Hal' : 'Page'} $currentPage / $totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: onNext,
                    style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHigh),
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
