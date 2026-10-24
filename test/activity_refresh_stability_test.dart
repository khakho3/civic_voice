import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/widgets/search_filter_list.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'verified activity rail remains mounted through repeated refresh/error dark=$dark',
      (tester) async {
        final directory = AdminSystemActivityDirectory.instance;
        directory.invalidateAndClear();
        addTearDown(directory.invalidateAndClear);
        directory.hasLiveSnapshot = true;
        directory.state.value = AdminSystemActivityDirectoryState.loaded;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminSystemActivityScreen(items: directory.items.value),
          ),
        );
        await tester.pumpAndSettle();
        final rail = tester.element(find.byType(SearchFilterList));
        for (var i = 0; i < 3; i++) {
          directory.state.value = AdminSystemActivityDirectoryState.loading;
          await tester.pump();
          expect(tester.element(find.byType(SearchFilterList)), same(rail));
          directory.state.value = i == 1
              ? AdminSystemActivityDirectoryState.failed
              : AdminSystemActivityDirectoryState.loaded;
          await tester.pump();
          expect(tester.element(find.byType(SearchFilterList)), same(rail));
          expect(tester.takeException(), isNull);
        }
        directory.invalidateAndClear();
        await tester.pump();
        expect(find.byType(SearchFilterList), findsNothing);
      },
    );
  }
}
