import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/utils/time_greeting.dart';

void main() {
  test('timeBasedGreeting follows the local dashboard day periods', () {
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 0)), 'Good Morning');
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 11, 59)), 'Good Morning');
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 12)), 'Good Afternoon');
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 16, 59)), 'Good Afternoon');
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 17)), 'Good Evening');
    expect(timeBasedGreeting(DateTime(2026, 1, 1, 23, 59)), 'Good Evening');
  });
}
