import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// A previously opened PDF: a real on-disk [path] plus its display [name].
class RecentFile {
  final String path;
  final String name;

  const RecentFile({required this.path, required this.name});

  Map<String, String> toJson() => {'path': path, 'name': name};

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'] as String,
        name: json['name'] as String,
      );
}

/// Persists the list of recently opened PDFs.
///
/// Only files that still exist on disk are returned, so stale entries (e.g.
/// a temp copy that was cleared) never surface a broken "document not found".
class RecentFiles {
  RecentFiles._();

  static const _key = 'recent_files_v2';
  static const _max = 20;

  static Future<List<RecentFile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final files = <RecentFile>[];
    for (final entry in raw) {
      try {
        final file = RecentFile.fromJson(
          jsonDecode(entry) as Map<String, dynamic>,
        );
        if (File(file.path).existsSync()) files.add(file);
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return files;
  }

  static Future<void> add(RecentFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((f) => f.path == file.path);
    current.insert(0, file);
    final trimmed = current.take(_max).toList();
    await prefs.setStringList(
      _key,
      trimmed.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  static Future<void> remove(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((f) => f.path == path);
    await prefs.setStringList(
      _key,
      current.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
