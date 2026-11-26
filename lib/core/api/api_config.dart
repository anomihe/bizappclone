/// Backend connection settings.
///
/// The app always talks to the Bizpaddi backend; there is no demo mode.
/// Builds use https://app.bizpaddi.com unless another server is given:
///
///   flutter run --dart-define=API_BASE_URL=https://staging.example.com
class ApiConfig {
  static const defaultBaseUrl = 'https://app.bizpaddi.com';
  static const _override = String.fromEnvironment('API_BASE_URL');
  static const baseUrl = _override == '' ? defaultBaseUrl : _override;

  /// The business app's own account type at login (staff and customers get their own homes).
  static const accountType = 'admin';

  static const timeout = Duration(seconds: 20);

  /// Laravel paginates lists 20–50 per page; cap how many pages we pull on load.
  static const maxPages = 5;
}
