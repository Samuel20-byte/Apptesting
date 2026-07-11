/// Central place to point the app at the backend.
///
/// The backend now lives on Railway, so this points at the public
/// Railway domain instead of the local emulator/LAN address used
/// during development.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apptesting-production.up.railway.app/api',
  );

  static const Duration timeout = Duration(seconds: 15);
}
