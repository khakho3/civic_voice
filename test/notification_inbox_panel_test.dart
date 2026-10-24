import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/notification_inbox_directory.dart';
import 'package:civic_voice/widgets/notification_inbox_panel.dart';
import 'notification_inbox_directory_test.dart' show page, row;

void main() {
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  late NotificationInboxDirectory inbox;
  InboxOwner? identity;
  late Future<Map<String, dynamic>> Function(String, String?) load;
  late Future<Map<String, dynamic>> Function(String, List<String>, String)
  write;
  setUp(() {
    identity = const InboxOwner('fixture-account', AppRole.citizen);
    load = (_, _) async => page();
    write = (_, ids, _) async => {'updated': ids.length};
    inbox = NotificationInboxDirectory(
      owner: () => identity,
      token: () async => 'fixture',
      list: (t, c) => load(t, c),
      write: (t, ids, a) => write(t, ids, a),
    );
  });
  tearDown(() => inbox.dispose());
  Future<void> mount(
    WidgetTester tester, {
    ThemeData? theme,
    Future<void> Function()? opened,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => 0,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(
          body: NotificationInboxPanel(
            role: AppRole.citizen,
            directory: inbox,
            navigate: (_) async {
              await opened?.call();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'denied OS permission preserves verified inbox and acknowledged navigation',
    (tester) async {
      var opens = 0;
      await mount(
        tester,
        opened: () async {
          opens++;
        },
      );
      expect(find.text('Device Notifications Are Off'), findsOneWidget);
      expect(find.text('Report one'), findsOneWidget);
      expect(find.text('4 unread'), findsOneWidget);
      await tester.tap(find.text('Report one'));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed write shows uncertainty and disables repeat actions until refresh',
    (tester) async {
      var calls = 0, opens = 0;
      write = (_, _, _) async {
        calls++;
        throw StateError('offline');
      };
      await mount(
        tester,
        opened: () async {
          opens++;
        },
      );
      await tester.tap(find.text('Report one'));
      await tester.pumpAndSettle();
      expect(inbox.uncertain, isTrue);
      expect(opens, 0);
      expect(calls, 1);
      expect(
        find.textContaining('This change could not be confirmed'),
        findsOneWidget,
      );
      final read = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Mark read'),
      );
      expect(read.onPressed, isNull);
      await tester.scrollUntilVisible(
        find.text('Refresh inbox'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Refresh inbox')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh inbox'));
      await tester.pumpAndSettle();
      expect(inbox.uncertain, isFalse);
    },
  );
  testWidgets('zero write acknowledgment cannot open a report', (tester) async {
    var opens = 0;
    write = (_, _, _) async => {'updated': 0};
    await mount(
      tester,
      opened: () async {
        opens++;
      },
    );
    await tester.tap(find.text('Report one'));
    await tester.pumpAndSettle();
    expect(opens, 0);
    expect(
      find.textContaining('This update could not be opened'),
      findsOneWidget,
    );
  });
  testWidgets('late acknowledgment after account switch never navigates', (
    tester,
  ) async {
    var opens = 0;
    final pending = Completer<Map<String, dynamic>>();
    write = (_, _, _) => pending.future;
    await mount(
      tester,
      opened: () async {
        opens++;
      },
    );
    await tester.tap(find.text('Report one'));
    await tester.pump();
    identity = const InboxOwner('other-account', AppRole.citizen);
    load = (_, _) async => page(rows: [row('two')]);
    await inbox.refresh();
    pending.complete({'updated': 1});
    await tester.pumpAndSettle();
    expect(opens, 0);
    expect(find.text('Report one'), findsNothing);
    expect(find.text('Report two'), findsOneWidget);
  });
  testWidgets('unverified load shows retry without synthesized notifications', (
    tester,
  ) async {
    load = (_, _) async => throw StateError('offline');
    await mount(tester);
    expect(find.textContaining('Could not load notifications'), findsOneWidget);
    expect(find.text('Report one'), findsNothing);
    load = (_, _) async => page(rows: [], unread: 0);
    await tester.tap(find.text('Refresh inbox'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No notifications yet.'), findsOneWidget);
    expect(find.text('Mark this page read'), findsNothing);
    expect(find.text('Clear this page'), findsNothing);
    expect(find.text('Previous page'), findsNothing);
    expect(find.text('Next page'), findsNothing);
  });
  testWidgets(
    'bulk clear freezes displayed IDs and retains newly arriving updates',
    (tester) async {
      List<String>? cleared;
      write = (_, ids, action) async {
        expect(action, 'dismiss');
        cleared = ids;
        return {'updated': ids.length};
      };
      await mount(tester);
      await tester.tap(find.text('Clear this page'));
      await tester.pumpAndSettle();
      load = (_, _) async => page(rows: [row('one'), row('new')]);
      await inbox.refresh();
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle();
      expect(cleared, ['one']);
      await tester.scrollUntilVisible(
        find.text('Report new'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Report new'), findsOneWidget);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'small ${dark ? 'dark' : 'light'} inbox keeps actions readable',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, theme: dark ? AppTheme.dark : AppTheme.light);
        expect(find.text('Report one'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 0);
        expect(card.color!.a, 1);
      },
    );
  }
}
