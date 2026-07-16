import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  AuthResult(this.token, this.user);
}

class AuthService {
  final _client = ApiClient.instance;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = data['token'] as String;
    final user = AppUser.fromJson(data['user']);
    await _client.saveToken(token);
    return AuthResult(token, user);
  }

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final data = await _client.post('/auth/register', body: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
    });
    final token = data['token'] as String;
    final user = AppUser.fromJson(data['user']);
    await _client.saveToken(token);
    return AuthResult(token, user);
  }

  /// Backend always responds with the same generic message whether or not
  /// the email is registered (so this endpoint can't be used to check which
  /// emails exist) — a non-2xx response here means something like a
  /// malformed email or a network/server problem, not "account not found".
  Future<void> forgotPassword({required String email}) async {
    await _client.post('/auth/forgot-password', body: {
      'email': email,
    });
  }

  Future<bool> hasStoredSession() async {
    final t = await _client.token;
    return t != null && t.isNotEmpty;
  }

  Future<void> logout() async {
    await _client.clearToken();
  }
}
