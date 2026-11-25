/// Backend connection settings, supplied at build time:
///
///   flutter run --dart-define=API_BASE_URL=https://app.bizpaddi.com
///   flutter build apk --dart-define=API_BASE_URL=https://app.bizpaddi.com
///
/// Leave it unset to run on the in-memory demo data (no network).
class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  /// True when the app talks to the real Bizpaddi backend.
  static bool get isLive => baseUrl.isNotEmpty;

  /// The backend authenticates every portal with one login; the business app
  /// only accepts business-owner accounts.
  static const accountType = 'admin';

  static const timeout = Duration(seconds: 20);

  /// Laravel paginates lists 20–50 per page; cap how many pages we pull on load.
  static const maxPages = 5;
}
