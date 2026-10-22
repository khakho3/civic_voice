import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/collapsible_list_header.dart';
import 'package:civic_voice/widgets/focused_search.dart';
import 'package:civic_voice/widgets/text_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screen = 'test-screen';

List<FocusedSearchResult> _results(String query, void Function(String) open) =>
    [
      for (final title in const ['Pothole on Main Road', 'Broken streetlight'])
        if (title.toLowerCase().contains(query.toLowerCase()))
          FocusedSearchResult(title: title, onSelected: () => open(title)),
    ];

Widget _host({
  required void Function(String) onOpen,
  ScrollController? controller,
  void Function(String?)? onClosed,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            SearchTriggerField(
              hintText: 'Search reports',
              onOpen: () async {
                final submitted = await showFocusedSearch(
                  context,
                  screenKey: _screen,
                  hintText: 'Search reports',
                  results: (query) => _results(query, onOpen),
                );
                onClosed?.call(submitted);
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: 60,
                itemBuilder: (_, index) =>
                    SizedBox(height: 56, child: Text('Row $index')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize(accountId: 'officer-a');
  });

  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    testWidgets(
      'focused search owns the full screen and a pill field at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_host(onOpen: (_) {}));
        final trigger = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(SearchTriggerField),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(trigger.shape, isA<StadiumBorder>());
        expect(tester.getSize(find.byType(SearchTriggerField)).height, 48);
        await tester.tap(find.text('Search reports'));
        await tester.pumpAndSettle();
        final panel = find.byType(FocusedSearchPanel);
        final scaffold = find.descendant(
          of: panel,
          matching: find.byType(Scaffold),
        );
        expect(tester.getRect(scaffold), Rect.fromLTWH(0, 0, width, 900));
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(
          (field.decoration!.focusedBorder as OutlineInputBorder).borderRadius,
          BorderRadius.circular(999),
        );
        expect(
          tester.getSize(find.byType(TextField)).height,
          lessThanOrEqualTo(52),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'history records trimmed, case-insensitive, newest-first entries',
    () async {
      final cache = AppCacheService.instance;
      await cache.recordSearch(_screen, '  Pothole ');
      await cache.recordSearch(_screen, 'streetlight');
      await cache.recordSearch(_screen, 'POTHOLE');
      await cache.recordSearch(_screen, '   ');
      expect(cache.searchHistory(_screen), ['POTHOLE', 'streetlight']);

      for (var i = 0; i < 12; i++) {
        await cache.recordSearch(_screen, 'term $i');
      }
      expect(
        cache.searchHistory(_screen),
        hasLength(AppCacheService.searchHistoryLimit),
      );

      await cache.removeSearch(_screen, 'TERM 11');
      expect(cache.searchHistory(_screen), isNot(contains('term 11')));

      // Scoped per account: another account on the device sees none of it.
      await cache.activateAccount('officer-b');
      expect(cache.searchHistory(_screen), isEmpty);
      await cache.activateAccount('officer-a');
      expect(cache.searchHistory(_screen), isNotEmpty);

      await cache.clearSearchHistory(_screen);
      expect(cache.searchHistory(_screen), isEmpty);
    },
  );

  testWidgets('focused search has a visible Close and Back also closes', (
    tester,
  ) async {
    String? closedWith = 'unset';
    await tester.pumpWidget(
      _host(onOpen: (_) {}, onClosed: (value) => closedWith = value),
    );

    await tester.tap(find.text('Search reports'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close search'), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.byType(FocusedSearchPanel), findsNothing);
    expect(closedWith, isNull);

    await tester.tap(find.text('Search reports'));
    await tester.pumpAndSettle();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(FocusedSearchPanel), findsNothing);
  });

  testWidgets('activating a result records history, closes, then opens it', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(_host(onOpen: (title) => opened = title));

    await tester.tap(find.text('Search reports'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pot');
    await tester.pumpAndSettle();
    // Typing alone records nothing.
    expect(AppCacheService.instance.searchHistory(_screen), isEmpty);
    expect(find.text('Broken streetlight'), findsNothing);

    await tester.tap(find.text('Pothole on Main Road'));
    await tester.pumpAndSettle();

    expect(opened, 'Pothole on Main Road');
    expect(find.byType(FocusedSearchPanel), findsNothing);
    expect(AppCacheService.instance.searchHistory(_screen), ['pot']);
  });

  testWidgets('history rows can be removed and Clear confirms first', (
    tester,
  ) async {
    await AppCacheService.instance.recordSearch(_screen, 'drain');
    await AppCacheService.instance.recordSearch(_screen, 'pothole');
    await tester.pumpWidget(_host(onOpen: (_) {}));

    await tester.tap(find.text('Search reports'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('pothole'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove "pothole" from recent searches'));
    await tester.pumpAndSettle();
    expect(find.text('pothole'), findsNothing);
    expect(find.text('drain'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Clear recent searches?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('drain'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('drain'), findsNothing);
    expect(AppCacheService.instance.searchHistory(_screen), isEmpty);
  });

  testWidgets(
    'list position survives repeated open/close and no editable field '
    'regains focus',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(onOpen: (_) {}, controller: controller));

      controller.jumpTo(900);
      await tester.pump();

      for (var cycle = 0; cycle < 3; cycle++) {
        await tester.tap(find.text('Search reports'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Close search'));
        await tester.pumpAndSettle();

        expect(controller.offset, 900);
        final focused = FocusManager.instance.primaryFocus?.context?.widget;
        expect(focused, isNot(isA<EditableText>()));
        expect(find.byType(EditableText), findsNothing);
      }
    },
  );

  testWidgets(
    'text-only chips: no icons, gold fill and dark ink when selected',
    (tester) async {
      var selected = 'all';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TextFilterChips<String>(
                options: const [
                  TextFilterOption(value: 'all', label: 'All'),
                  TextFilterOption(value: 'open', label: 'Open'),
                ],
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
      final semantic = AppSemanticColors.light;
      Text label(String text) => tester.widget<Text>(find.text(text));
      expect(label('All').style?.color, semantic.onAction);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(selected, 'open');
      expect(label('Open').style?.color, semantic.onAction);
      expect(
        tester.getSize(find.text('Open')).height,
        lessThan(TextFilterChips.chipHeight),
      );
    },
  );

  testWidgets(
    'collapsed rail appears on scroll down and upward scrolling does not '
    're-expand until the true top',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CollapsibleListHeader(
              header: const SizedBox(height: 120, child: Text('Full header')),
              collapsedHeader: const SizedBox(
                height: 48,
                child: Text('Compact rail'),
              ),
              child: ListView.builder(
                controller: controller,
                itemCount: 80,
                itemBuilder: (_, index) =>
                    SizedBox(height: 56, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Full header'), findsOneWidget);

      await tester.drag(find.text('Item 3'), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Compact rail'), findsOneWidget);
      expect(find.text('Full header'), findsNothing);

      // A modest upward scroll mid-list keeps the rail.
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(4));
      expect(find.text('Compact rail'), findsOneWidget);

      // Back at the true top, the full header returns.
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(find.text('Full header'), findsOneWidget);
    },
  );
}
