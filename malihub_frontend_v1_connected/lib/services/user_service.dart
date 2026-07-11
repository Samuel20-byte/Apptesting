import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final _client = ApiClient.instance;

  Future<AppUser> getMe() async {
    final data = await _client.get('/users/me');
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateMe({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? currencyPreference,
  }) async {
    final data = await _client.put('/users/me', body: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (currencyPreference != null) 'currency_preference': currencyPreference,
    });
    return AppUser.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put('/users/me/password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
