import 'package:civic_voice/utils/civic_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'formats dates and audit time in Ghana after an offset crosses midnight',
    () {
      final value = DateTime.parse('2026-11-07T19:05:09-05:00');
      expect(formatCivicDate(value), 'Sun, Nov 8, 2026');
      expect(
        formatCivicTimestamp(value, precise: true),
        'Sun, Nov 8, 2026 · 12:05:09 AM',
      );
      expect(
        formatCivicTimestamp(DateTime.utc(2024, 11, 8, 12, 7)),
        'Fri, Nov 8, 2024 · 12:07 PM',
      );
    },
  );

  test(
    'keeps current-year time compact and leaves missing records unknown',
    () {
      final year = DateTime.now().toUtc().year;
      final midnight = DateTime.utc(year, 11, 8, 0, 5);
      expect(
        formatCivicTimestamp(midnight),
        matches(r'^\w{3}, Nov 8 · 12:05 AM$'),
      );
      expect(formatCivicTimestamp(null), 'Not recorded');
      expect(
        formatCivicTimestamp(null, fallback: 'Time not recorded'),
        'Time not recorded',
      );
    },
  );
}
