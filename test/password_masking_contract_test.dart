import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';

Widget host(String screen) => MaterialApp(
  theme: AppTheme.dark,
  home: switch (screen) {
    'login' => const LoginScreen(),
    'registration' => const RegistrationScreen(),
    _ => Scaffold(
      body: SetNewPasswordForm(
        submitLabel: 'Save',
        onSaved: (_) async => false,
      ),
    ),
  },
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'masking-test');
  });

  testWidgets(
    'baseline brief-reveal preference reproduces a visible typed character',
    (tester) async {
      tester.platformDispatcher.brieflyShowPasswordTestValue = true;
      addTearDown(tester.platformDispatcher.resetBrieflyShowPassword);
      await tester.pumpWidget(host('login'));
      await tester.pumpAndSettle();
      final field = find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.obscureText,
      );
      await tester.showKeyboard(field);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Z',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      expect(
        tester
            .state<EditableTextState>(field)
            .renderEditable
            .text!
            .toPlainText(),
        'Z',
      );
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final (screen, index, hint) in [
    ('login', 0, AutofillHints.password),
    ('registration', 0, AutofillHints.newPassword),
    ('registration', 1, AutofillHints.newPassword),
    ('new-password', 0, AutofillHints.newPassword),
    ('new-password', 1, AutofillHints.newPassword),
  ]) {
    testWidgets(
      'immediate-mask preference preserves secure editing and Show/Hide $screen $index',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.brieflyShowPasswordTestValue = false;
        addTearDown(tester.platformDispatcher.resetBrieflyShowPassword);
        await tester.pumpWidget(host(screen));
        await tester.pumpAndSettle();
        final passwordFields = find.byWidgetPredicate(
          (widget) => widget is EditableText && widget.obscureText,
        );
        final editor = tester.state<EditableTextState>(
          passwordFields.at(index),
        );
        final controller = editor.widget.controller;
        final field = find.byWidgetPredicate(
          (widget) =>
              widget is EditableText &&
              identical(widget.controller, controller),
        );
        await tester.showKeyboard(field);
        var value = '';
        for (final addition in ['a', 'B', '7', '!', '💛', 'e\u0301']) {
          value += addition;
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            ),
          );
          await tester.pump();
          expect(editor.renderEditable.text!.toPlainText(), '•' * value.length);
          expect(controller.text, value);
        }
        // Paste/replace and deletion still use the real unmodified editing value.
        for (final next in ['Pasted#123', 'Pasted#12', 'Prefix-Pasted#12']) {
          value = next;
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            ),
          );
          await tester.pump();
          expect(controller.text, value);
          expect(editor.renderEditable.text!.toPlainText(), '•' * value.length);
        }
        expect(editor.textInputConfiguration.obscureText, isTrue);
        expect(
          editor.textInputConfiguration.autofillConfiguration.enabled,
          isTrue,
        );
        expect(
          editor.textInputConfiguration.autofillConfiguration.autofillHints,
          contains(hint),
        );
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: value.length,
        );
        await tester.pump();
        expect(editor.copyEnabled, isFalse);
        expect(editor.cutEnabled, isFalse);
        final formField = find.ancestor(
          of: field,
          matching: find.byType(TextFormField),
        );
        final show = find.descendant(
          of: formField,
          matching: find.byTooltip('Show password'),
        );
        await Scrollable.ensureVisible(tester.element(show), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(show);
        await tester.pumpAndSettle();
        expect(editor.renderEditable.text!.toPlainText(), value);
        expect(controller.text, value);
        final hide = find.descendant(
          of: formField,
          matching: find.byTooltip('Hide password'),
        );
        await tester.tap(hide);
        await tester.pumpAndSettle();
        expect(editor.renderEditable.text!.toPlainText(), '•' * value.length);
        expect(editor.textInputConfiguration.obscureText, isTrue);
        expect(controller.text, value);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
