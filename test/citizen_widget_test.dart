import 'package:civic_voice/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CivicVoice opens from splash to citizen dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CivicVoiceApp());

    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('Report. Track. Resolve.'), findsOneWidget);

    // The splash screen's own timer fires at 3500ms, not 1500ms.
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Amina Mensah'), findsOneWidget);
    expect(find.text('Report a Community Issue'), findsOneWidget);
    expect(find.text('Report Now'), findsOneWidget);
  });
}
