/// Prisma's Decimal fields (amount, balance, budget_amount, etc.) come back
/// from Express as JSON strings like "52350.00", not raw numbers. These
/// helpers parse either shape safely so a stray String vs num doesn't crash
/// the UI.
double toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
