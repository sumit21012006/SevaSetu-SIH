import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ai_source.dart';

/// Metadata entry for a Government Resolution.
class GRManifestEntry {
  const GRManifestEntry({
    required this.id,
    required this.filename,
    required this.serviceId,
    required this.title,
    required this.grNumber,
    required this.department,
    required this.issueDate,
  });

  factory GRManifestEntry.fromJson(Map<String, dynamic> json) {
    return GRManifestEntry(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      grNumber: json['grNumber'] as String? ?? '',
      department: json['department'] as String? ?? '',
      issueDate: json['issueDate'] as String? ?? '',
    );
  }

  final String id;
  final String filename;
  final String serviceId;
  final String title;
  final String grNumber;
  final String department;
  final String issueDate;
}

/// Knowledge repository managing official sources, deterministic rules, and GRs.
class KnowledgeRepository {
  KnowledgeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  bool _isLoaded = false;

  final List<AISource> _sources = [];
  final Map<String, List<Map<String, dynamic>>> _rulesByService = {};
  final List<GRManifestEntry> _grEntries = [];
  final Map<String, String> _grTextCache = {};

  bool get isLoaded => _isLoaded;
  List<AISource> get allSources => List.unmodifiable(_sources);
  List<GRManifestEntry> get grEntries => List.unmodifiable(_grEntries);

  /// Loads all knowledge bases from assets. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // 1. Load sources.json
      final sourcesStr = await _bundle.loadString('assets/knowledge/sources.json');
      final sourcesJson = jsonDecode(sourcesStr) as Map<String, dynamic>;
      final rawSources = sourcesJson['sources'] as List<dynamic>? ?? [];
      _sources.clear();
      for (final item in rawSources) {
        if (item is Map<String, dynamic>) {
          _sources.add(AISource.fromJson(item));
        }
      }

      // 2. Load eligibility_rules.json
      final rulesStr = await _bundle.loadString('assets/knowledge/eligibility_rules.json');
      final rulesJson = jsonDecode(rulesStr) as Map<String, dynamic>;
      final rulesMap = rulesJson['rules'] as Map<String, dynamic>? ?? {};
      _rulesByService.clear();
      rulesMap.forEach((svcId, list) {
        if (list is List<dynamic>) {
          _rulesByService[svcId] = list.whereType<Map<String, dynamic>>().toList();
        }
      });

      // 3. Load gr_manifest.json
      final grStr = await _bundle.loadString('assets/knowledge/gr_manifest.json');
      final grJson = jsonDecode(grStr) as Map<String, dynamic>;
      final rawGr = grJson['resolutions'] as List<dynamic>? ?? [];
      _grEntries.clear();
      for (final item in rawGr) {
        if (item is Map<String, dynamic>) {
          _grEntries.add(GRManifestEntry.fromJson(item));
        }
      }

      _isLoaded = true;
    } catch (e) {
      // Allow graceful fallback if assets are not loaded in non-widget unit test environments
      _isLoaded = false;
    }
  }

  /// Finds official sources relevant to a specific service or category.
  List<AISource> getSourcesForService(String serviceId) {
    return _sources.where((s) => s.serviceId == serviceId).toList();
  }

  /// Finds raw rule definitions for a service.
  List<Map<String, dynamic>> getRulesForService(String serviceId) {
    return _rulesByService[serviceId] ?? const [];
  }

  /// Finds GR manifest entry for a service.
  GRManifestEntry? getGRForService(String serviceId) {
    try {
      return _grEntries.firstWhere((g) => g.serviceId == serviceId);
    } catch (_) {
      return null;
    }
  }

  /// Loads full GR text from disk/asset.
  Future<String> loadGRText(String filename) async {
    if (_grTextCache.containsKey(filename)) {
      return _grTextCache[filename]!;
    }
    try {
      final text = await _bundle.loadString('assets/knowledge/gr/$filename');
      _grTextCache[filename] = text;
      return text;
    } catch (e) {
      return 'Official resolution text unavailable for $filename: $e';
    }
  }
}
