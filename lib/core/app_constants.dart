/// Global constants for SevaSetu: brand strings, spacing scale,
/// status thresholds and animation timings.
library;

class AppBrand {
  AppBrand._();

  static const String name = 'SevaSetu';
  static const String tagline = 'Government Services, Simplified for You.';
  static const String supporting =
      'Discover the right service, check your eligibility, prepare your '
      'documents, and complete your journey — all in one place.';
  static const String shortPhrase = 'Discover. Check. Prepare. Apply.';
  static const String trustNote =
      'Your documents are securely managed and only used to prepare your '
      'application.';
  static const String demoNote =
      'Sample data for demonstration — documents shown are placeholders, '
      'not real government records.';
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal page padding used across screens.
  static const double page = 20;

  /// Standard radius for cards.
  static const double radiusCard = 18;
  static const double radiusTile = 14;
  static const double radiusPill = 999;
}

class AppDurations {
  AppDurations._();

  static const Duration splash = Duration(milliseconds: 2100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration fakeUpload = Duration(milliseconds: 1100);
  static const Duration fakeVoice = Duration(milliseconds: 1500);
}

/// A document whose validity runs out within [expiringSoonDays] is flagged
/// as "expiring soon".
const int expiringSoonDays = 365;

/// Hard cap on characters for generated file names.
const int maxFilenameLength = 80;
