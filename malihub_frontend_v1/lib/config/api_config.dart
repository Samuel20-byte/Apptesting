/// Central place to point the app at the backend.
///
/// While developing against your local Express server:
/// - LDPlayer (and standard Android emulators) can usually reach your
///   Windows host machine at 10.0.2.2 — this is NOT your PC's real IP,
///   it's a special alias the emulator maps back to "localhost" on the
///   host. That's why the default below uses it instead of "localhost".
/// - If 10.0.2.2 doesn't connect, run `ipconfig` on Windows, grab your
///   IPv4 address (e.g. 192.168.1.42), and use that instead — some
///   LDPlayer network modes need the real LAN IP. Make sure Windows
///   Firewall allows inbound connections on the port your backend uses.
/// - Once deployed, switch baseUrl to your Railway URL
///   (e.g. https://malihub-backend-production.up.railway.app/api).
class ApiConfig {
  // TODO: swap this for your Railway URL once the backend is deployed.
  static const String baseUrl = 'http://192.168.0.15/api';

  static const Duration timeout = Duration(seconds: 15);
}
