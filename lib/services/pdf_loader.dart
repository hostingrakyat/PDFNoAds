import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'intent_service.dart';

/// A PDF resolved to a concrete local file path plus its display name.
class LoadedPdf {
  final String path;
  final String name;

  const LoadedPdf({required this.path, required this.name});
}

/// Resolves an incoming PDF reference into a real, readable local file.
///
/// `content://` URIs (from file managers, WhatsApp, the share sheet, …) carry
/// a random document id as their last path segment and their read permission
/// is tied to the originating intent. We therefore query the real display name
/// and copy the bytes into the app's documents directory, so the file keeps a
/// correct name and stays openable later from Recents.
class PdfLoader {
  PdfLoader._();

  static Future<LoadedPdf> resolve(String source) async {
    if (source.startsWith('content://')) {
      final name = _ensurePdfExtension(
        await IntentService.getDisplayName(source) ?? _lastSegment(source),
      );
      final bytes = await IntentService.readUri(source);
      if (bytes == null) {
        throw Exception('Could not read the file');
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _uniqueName(dir, name)));
      await file.writeAsBytes(bytes, flush: true);
      return LoadedPdf(path: file.path, name: name);
    }

    final path =
        source.startsWith('file://') ? Uri.parse(source).toFilePath() : source;
    if (!File(path).existsSync()) {
      throw Exception('Document not found');
    }
    return LoadedPdf(path: path, name: p.basename(path));
  }

  static String _lastSegment(String source) {
    final decoded = Uri.decodeFull(source);
    final parts = decoded.split('/');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last : 'document.pdf';
  }

  static String _ensurePdfExtension(String name) {
    return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
  }

  /// Avoids clobbering an existing copy of a different file with the same name.
  static String _uniqueName(Directory dir, String name) {
    if (!File(p.join(dir.path, name)).existsSync()) return name;
    final base = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    var i = 1;
    while (File(p.join(dir.path, '$base ($i)$ext')).existsSync()) {
      i++;
    }
    return '$base ($i)$ext';
  }
}
