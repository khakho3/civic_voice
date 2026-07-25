/// Returns a dashboard greeting for the supplied local time.
///
/// When [time] is omitted, the device's current local time is used.
String timeBasedGreeting([DateTime? time]) {
  final hour = (time ?? DateTime.now()).hour;

  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
