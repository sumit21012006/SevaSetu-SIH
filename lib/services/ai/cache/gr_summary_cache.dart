import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/agent_result.dart';

/// Persistent cache for GR simplifications, keyed by sha256(text + language).
class GRSummaryCache {
  GRSummaryCache();

  Directory? _cacheDir;
  final Map<String, AgentResult> _inMemoryFallback = {};

  Future<Directory> _getDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/gr_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      return dir;
    } catch (_) {
      // In unit test or non-flutter environments where getApplicationDocumentsDirectory fails
      final temp = Directory.systemTemp.createTempSync('gr_cache_test');
      _cacheDir = temp;
      return temp;
    }
  }

  /// Computes deterministic hash key for document text and target language.
  String computeKey(String grText, String languageCode) {
    final bytes = utf8.encode('$languageCode:$grText');
    return sha256.convert(bytes).toString();
  }

  /// Retrieves cached result from disk or memory.
  Future<AgentResult?> get(String key) async {
    if (_inMemoryFallback.containsKey(key)) {
      return _inMemoryFallback[key]!.copyWith(fromCache: true);
    }

    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$key.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final result = AgentResult.fromJson(json).copyWith(fromCache: true);
        _inMemoryFallback[key] = result;
        return result;
      }
    } catch (_) {}
    return null;
  }

  /// Persists result to disk and memory.
  Future<void> put(String key, AgentResult result) async {
    _inMemoryFallback[key] = result;
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$key.json');
      await file.writeAsString(jsonEncode(result.toJson()));
    } catch (_) {}
  }
}
