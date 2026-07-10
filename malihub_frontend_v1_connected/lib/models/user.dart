import 'json_helpers.dart';

class AppUser {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String currencyPreference;

  AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.currencyPreference = 'KES',
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return ('$f$l').toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: toInt(json['user_id']),
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phone_number'],
        currencyPreference: json['currency_preference'] ?? 'KES',
      );
}
