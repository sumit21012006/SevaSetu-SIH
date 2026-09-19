import '../models/agent_result.dart';

/// In-memory cache for agent responses with a 10-minute Time-To-Live (TTL).
class ResponseCache {
  ResponseCache({Duration ttl = const Duration(minutes: 10)}) : _ttl = ttl;

  final Duration _ttl;
  final Map<String, _CacheEntry> _cache = {};

  /// Retrieves a cached result if not expired.
  AgentResult? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    return entry.result.copyWith(fromCache: true);
  }

  /// Stores an agent result in cache.
  void put(String key, AgentResult result) {
    _cache[key] = _CacheEntry(
      result: result,
      expiry: DateTime.now().add(_ttl),
    );
  }

  /// Clears the cache.
  void clear() {
    _cache.clear();
  }
}

class _CacheEntry {
  const _CacheEntry({required this.result, required this.expiry});
  final AgentResult result;
  final DateTime expiry;
}
