import 'package:civic_voice/app/civic_voice_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CivicVoice opens from splash to citizen dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CivicVoiceApp());

    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('Report. Track. Resolve.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning, Abdul Malik'), findsOneWidget);
    expect(find.text('Report a Community Issue'), findsOneWidget);
    expect(find.text('Report Now'), findsOneWidget);
  });
}
