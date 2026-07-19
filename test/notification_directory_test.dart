import 'package:civic_voice/services/notification_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('read notification IDs survive directory initialization', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final directory = NotificationDirectory.instance;
    directory.readIds.value = <String>{};
    await directory.initialize();

    directory.markRead('report-123-underReview');
    await Future<void>.delayed(Duration.zero);
    directory.readIds.value = <String>{};
    await directory.initialize();

    expect(directory.isRead('report-123-underReview'), isTrue);
  });
}
