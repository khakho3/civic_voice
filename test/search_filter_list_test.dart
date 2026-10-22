import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/focused_search.dart';
import 'package:civic_voice/widgets/search_filter_list.dart';
import 'package:civic_voice/widgets/text_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(
  ScrollController scroll, {
  int count = 80,
  bool dark = false,
  bool reduced = false,
  bool enabled = true,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: SearchFilterList(
        header: SearchFilterHeader(
          screenKey: 'regression',
          hintText: 'Search records',
          query: '',
          onQueryChanged: (_) {},
          enabled: enabled,
          results: (q) => [FocusedSearchResult(title: 'Result $q')],
          filters: TextFilterChips<int>(
            options: const [
              TextFilterOption(value: 0, label: 'All'),
              TextFilterOption(value: 1, label: 'In progress'),
              TextFilterOption(value: 2, label: 'Awaiting confirmation'),
            ],
            selected: 0,
            onSelected: (_) {},
            padding: EdgeInsets.zero,
          ),
        ),
        child: ListView.builder(
          key: const ValueKey('records-list'),
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (_, i) => SizedBox(height: 80, child: Text('Record $i')),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'search-regression');
  });

  testWidgets(
    'rail height eases between sizes and keeps the content anchored',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(host(scroll));
      final header = find.byKey(const ValueKey('collapsible_header'));
      final expanded = tester.getSize(header).height;
      scroll.jumpTo(400);
      await tester.pump();
      final anchor = tester.getTopLeft(find.text('Record 5')).dy;
      expect(tester.getSize(header).height, expanded);
      await tester.pump(const Duration(milliseconds: 60));
      final intermediate = tester.getSize(header).height;
      expect(intermediate, lessThan(expanded));
      expect(tester.getTopLeft(find.text('Record 5')).dy, closeTo(anchor, 1));
      await tester.pumpAndSettle();
      expect(tester.getSize(header).height, lessThan(intermediate));
      expect(tester.getTopLeft(find.text('Record 5')).dy, closeTo(anchor, 1));
      // The viewport now extends behind the compact controls: frost must sample
      // actual list pixels, rather than blur an empty Column sibling.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('records-list'))).dy,
        tester.getTopLeft(header).dy,
      );
    },
  );

  for (final reduced in [false, true]) {
    testWidgets('collapse preserves fling momentum reduced=$reduced', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(host(scroll, reduced: reduced));
      await tester.fling(
        find.byKey(const ValueKey('records-list')),
        const Offset(0, -200),
        1800,
      );
      await tester.pump(const Duration(milliseconds: 32));
      final offset = scroll.offset;
      expect(scroll.position.isScrollingNotifier.value, isTrue);
      await tester.pump(const Duration(milliseconds: 32));
      expect(scroll.offset, greaterThan(offset));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'collapse keeps one held gesture alive through reversal reduced=$reduced',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        var ends = 0;
        await tester.pumpWidget(
          NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) ends++;
              return false;
            },
            child: host(scroll, reduced: reduced),
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('records-list'))),
        );
        for (var frame = 0; frame < 10; frame++) {
          await gesture.moveBy(const Offset(0, -24));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
        expect(
          ends,
          0,
          reason: 'Changing header layout must not end the held drag',
        );
        final before = scroll.offset;
        await gesture.moveBy(const Offset(0, -80));
        await tester.pump(const Duration(milliseconds: 16));
        expect(scroll.offset, greaterThan(before + 20));
        final down = scroll.offset;
        await gesture.moveBy(const Offset(0, 80));
        await tester.pump(const Duration(milliseconds: 16));
        expect(scroll.offset, lessThan(down - 20));
        expect(ends, 0);
        // Reverse all the way to the top, then scroll away again without lifting.
        await gesture.moveBy(const Offset(0, 400));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('expanded_header')), findsOneWidget);
        await gesture.moveBy(const Offset(0, -240));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
        expect(ends, 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('rail, filters and focused dismissal at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(host(scroll, dark: dark));
        await tester.drag(find.text('Record 3'), const Offset(0, -550));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
        final offset = scroll.offset;
        await tester.drag(
          find.byType(TextFilterChips<int>),
          const Offset(-200, 0),
        );
        await tester.pumpAndSettle();
        expect(scroll.offset, offset);
        expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
        await tester.tap(find.byTooltip('Search records'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'gutter');
        await tester.pumpAndSettle();
        expect(find.text('Result gutter'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(FocusedSearchPanel), findsNothing);
        expect(scroll.offset, offset);
        await tester.tap(find.byTooltip('Search records'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(scroll.offset, offset);
        expect(find.byType(TextField), findsNothing);
        await tester.drag(
          find.byKey(const ValueKey('records-list')),
          const Offset(0, 100),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('short list never loses search after an overscroll', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(host(scroll, count: 3));
    await tester.drag(find.text('Record 1'), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expanded_header')), findsOneWidget);
    expect(find.text('Search records'), findsOneWidget);
  });

  testWidgets('collapse compensates viewport height and ignores nested lists', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(host(scroll, reduced: true));
    // Programmatic page restore also collapses once away from the top.
    final before = tester.getTopLeft(find.text('Record 5')).dy - 400;
    scroll.jumpTo(400);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
    expect(tester.getTopLeft(find.text('Record 5')).dy, closeTo(before, 1));
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('records-list')),
      const Offset(0, 70),
    );
    await tester.pumpAndSettle();
    expect(find.text('Search records'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled search does not open a dialog', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(host(scroll, enabled: false));
    await tester.tap(find.text('Search records'));
    await tester.pumpAndSettle();
    expect(find.byType(FocusedSearchPanel), findsNothing);
  });

  testWidgets(
    'an empty submission clears an applied query without saving history',
    (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  submitted = await showFocusedSearch(
                    context,
                    screenKey: 'clear-query',
                    hintText: 'Search records',
                    initialQuery: 'old query',
                    results: emptySearchResults,
                  );
                },
                child: const Text('Open search'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(submitted, '');
      expect(AppCacheService.instance.searchHistory('clear-query'), isEmpty);
      expect(find.byType(FocusedSearchPanel), findsNothing);
    },
  );
}
