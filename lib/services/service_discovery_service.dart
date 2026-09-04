import '../data/mock_store.dart';
import '../models/service.dart';

class ServiceFilter {
  const ServiceFilter({this.category, this.state, this.query = ''});

  final ServiceCategory? category;
  final String? state;
  final String query;
}

/// Service discovery: natural-language-ish search over names, keywords and
/// descriptions, plus category/state filters.
///
/// Future implementation: FastAPI + PostgreSQL full-text search with the
/// same query contract.
abstract class ServiceDiscoveryService {
  List<GovService> search(ServiceFilter filter);
}

class LocalServiceDiscoveryService implements ServiceDiscoveryService {
  LocalServiceDiscoveryService(this._store);

  final AppDataStore _store;

  @override
  List<GovService> search(ServiceFilter filter) {
    final q = filter.query.trim().toLowerCase();
    List<GovService> results = _store.services.where((s) {
      if (filter.category != null && s.category != filter.category) {
        return false;
      }
      if (filter.state != null && filter.state!.isNotEmpty) {
        if (s.scope != 'All India' && !s.scope.contains(filter.state!)) {
          return false;
        }
      }
      if (q.isEmpty) return true;

      final haystack = [
        s.name,
        s.shortDescription,
        s.description,
        s.department,
        ...s.keywords,
      ].join(' ').toLowerCase();

      // Token overlap scoring so multi-word queries match sensibly.
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
      final hits = tokens.where(haystack.contains).length;
      return tokens.isEmpty ? haystack.contains(q) : hits >= 1;
    }).toList();

    if (q.isNotEmpty) {
      results.sort((a, b) => _score(b, q).compareTo(_score(a, q)));
    }
    return results;
  }

  int _score(GovService s, String q) {
    var score = 0;
    if (s.name.toLowerCase().contains(q)) score += 10;
    if (s.keywords.any((k) => k.toLowerCase().contains(q))) score += 6;
    if (s.shortDescription.toLowerCase().contains(q)) score += 3;
    if (s.department.toLowerCase().contains(q)) score += 2;
    return score;
  }
}
