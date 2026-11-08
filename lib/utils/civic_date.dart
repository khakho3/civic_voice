const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _dayLabel(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

String formatCivicDate(DateTime? value) {
  if (value == null) return 'Not recorded';
  final date = value.toUtc();
  return '${_dayLabel(date)}, ${date.year}';
}

String formatCivicTime(DateTime value, {bool precise = false}) {
  final date = value.toUtc();
  final hour = (date.hour + 11) % 12 + 1;
  final period = date.hour < 12 ? 'AM' : 'PM';
  final minute = date.minute.toString().padLeft(2, '0');
  final seconds = precise ? ':${date.second.toString().padLeft(2, '0')}' : '';
  return '$hour:$minute$seconds $period';
}

/// Recorded instants use Ghana time regardless of the device timezone.
String formatCivicTimestamp(
  DateTime? value, {
  bool precise = false,
  String fallback = 'Not recorded',
}) {
  if (value == null) return fallback;
  final date = value.toUtc();
  final day = precise || date.year != DateTime.now().toUtc().year
      ? formatCivicDate(date)
      : _dayLabel(date);
  return '$day · ${formatCivicTime(date, precise: precise)}';
}
