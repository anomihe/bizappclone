/// Backend connection settings.
///
/// Builds talk to https://app.bizpaddi.com by default. Override at build time:
///
///   flutter run --dart-define=API_BASE_URL=https://staging.example.com   (another server)
///   flutter run --dart-define=DEMO_MODE=true                             (sample data, no network)
class ApiConfig {
  static const defaultBaseUrl = 'https://app.bizpaddi.com';
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl);

  /// Runs on the in-memory sample data instead of the backend.
  static const demoMode = bool.fromEnvironment('DEMO_MODE');

  /// True when the app talks to the real Bizpaddi backend.
  static bool get isLive => !demoMode && baseUrl.isNotEmpty;

  /// The backend authenticates every portal with one login; the business app
  /// only accepts business-owner accounts.
  static const accountType = 'admin';

  static const timeout = Duration(seconds: 20);

  /// Laravel paginates lists 20–50 per page; cap how many pages we pull on load.
  static const maxPages = 5;
}
