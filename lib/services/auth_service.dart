import '../data/mock_store.dart';
import '../models/profile.dart';

/// Citizen identity service.
///
/// Future implementation: Firebase Authentication + a citizen profile row
/// in PostgreSQL. The interface below is what the UI depends on, so the
/// swap is contained to this file.
abstract class AuthService {
  UserProfile get profile;

  Future<UserProfile> updateProfile(UserProfile updated);

  /// Prepares for real sign-in flows (Aadhaar OTP / OAuth). No-op in V1.
  Future<void> ensureSignedIn();
}

class LocalAuthService implements AuthService {
  LocalAuthService(this._store);

  final AppDataStore _store;

  @override
  UserProfile get profile => _store.profile;

  @override
  Future<UserProfile> updateProfile(UserProfile updated) async {
    _store.profile = updated;
    return updated;
  }

  @override
  Future<void> ensureSignedIn() async {
    // V1 has a fixed demo citizen; real auth lands with the backend.
  }
}
