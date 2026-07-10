import 'package:intl/intl.dart';

String formatCurrency(double value, {String currencyCode = 'KES'}) {
  final formatted = NumberFormat('#,##0', 'en_US').format(value.abs());
  final sign = value < 0 ? '-' : '';
  return '$sign$currencyCode $formatted';
}

String formatSignedCurrency(double value, {String currencyCode = 'KES'}) {
  final sign = value >= 0 ? '+' : '-';
  final formatted = NumberFormat('#,##0', 'en_US').format(value.abs());
  return '$sign$currencyCode $formatted';
}

String formatDate(DateTime date) {
  return DateFormat('d MMM y').format(date);
}

String formatShortDate(DateTime date) {
  return DateFormat('MM/dd/yyyy').format(date);
}

String formatRelativeTime(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(date);
}
