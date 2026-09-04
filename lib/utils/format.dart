import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';

/// Small date/number/string formatting helpers (no intl dependency).
class Formatters {
  Formatters._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. 15 Aug 2026
  static String date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// e.g. 15 Aug 2026, 4:05 PM
  static String dateTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${date(d)}, $h:$mm $ampm';
  }

  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static int daysUntil(DateTime? d) =>
      d == null ? 0 : daysBetween(DateTime.now(), d);

  /// "Expires in 24 days" / "Expired 12 days ago".
  static String expiryPhrase(DateTime expiry, {bool includeDate = true}) {
    final days = daysUntil(expiry);
    if (days < 0) {
      return 'Expired ${-days} day${-days == 1 ? '' : 's'} ago';
    }
    final prefix = 'Expires in $days day${days == 1 ? '' : 's'}';
    if (!includeDate) return prefix;
    return '$prefix (${date(expiry)})';
  }

  /// Relative human time such as "2h ago" for notifications.
  static String relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(time);
  }

  /// "3.4L" style income, compact for chips.
  static String incomeLakhs(double lakhs) {
    final text = lakhs == lakhs.roundToDouble()
        ? lakhs.round().toString()
        : lakhs.toStringAsFixed(1);
    return '₹$text L';
  }

  static String maskedDocNumber(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.length <= 8) return raw;
    final visible = raw.substring(raw.length - 4);
    return '•••• $visible';
  }

  static String fileSafe(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9 _.-]+'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.length > maxFilenameLength
        ? cleaned.substring(0, maxFilenameLength)
        : cleaned;
  }

  /// Human readable bytes, e.g. "24.3 KB".
  static String bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Time-of-day greeting key (morning/afternoon/evening).
  static String greetingKey([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Debug log helper honouring kDebugMode only.
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[SevaSetu] $message');
    }
  }
}
