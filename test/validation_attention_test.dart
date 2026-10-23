import 'package:civic_voice/widgets/validation_attention.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/citizen/screens/create_report_screen.dart';
import 'package:civic_voice/features/citizen/screens/photo_upload_screen.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'invalid submit reveals first field; editing does not jump reduced=$reduced',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final form = GlobalKey<FormState>();
        final first = FocusNode(), second = FocusNode();
        addTearDown(first.dispose);
        addTearDown(second.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 600),
                viewInsets: const EdgeInsets.only(bottom: 260),
                disableAnimations: reduced,
              ),
              child: Scaffold(
                appBar: AppBar(title: const Text('Form')),
                body: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      children: [
                        TextFormField(
                          focusNode: first,
                          validator: (v) =>
                              (v ?? '').isEmpty ? 'First required' : null,
                        ),
                        const SizedBox(height: 650),
                        TextFormField(
                          focusNode: second,
                          validator: (v) =>
                              (v ?? '').isEmpty ? 'Second required' : null,
                        ),
                        FilledButton(
                          onPressed: () => ValidationAttention.validate(form),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.ensureVisible(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(first.hasFocus, isTrue);
        expect(
          tester.getTopLeft(find.byType(TextFormField).first).dy,
          greaterThanOrEqualTo(56),
        );
        expect(
          tester.getBottomLeft(find.byType(TextFormField).first).dy,
          lessThan(340),
        );
        await tester.enterText(find.byType(TextFormField).first, 'Fixed');
        await tester.pumpAndSettle();
        expect(first.hasFocus, isTrue);
        await tester.ensureVisible(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(second.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('queued validation is safe when the form is removed', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: TextFormField(validator: (_) => 'Required'),
          ),
        ),
      ),
    );
    ValidationAttention.validate(form);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Citizen Continue reveals an offscreen missing title', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'validation-test');
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CreateReportScreen()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue to Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to Photos'));
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(field.focusNode.hasFocus, isTrue);
    expect(tester.getTopLeft(find.byType(TextField).first).dy, greaterThan(70));
    expect(
      tester.getBottomLeft(find.byType(TextField).first).dy,
      lessThan(640),
    );
    expect(find.byType(PhotoUploadScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing photos reveals upload controls and does not navigate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(
      accountId: 'photos-validation-test',
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const PhotoUploadScreen()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Attach at least 2 photos to continue.'), findsOneWidget);
    expect(find.byType(PhotoUploadScreen), findsOneWidget);
    expect(tester.getTopLeft(find.text('Gallery')).dy, greaterThan(60));
    expect(tester.getBottomLeft(find.text('Gallery')).dy, lessThan(600));
    expect(tester.takeException(), isNull);
  });
}
