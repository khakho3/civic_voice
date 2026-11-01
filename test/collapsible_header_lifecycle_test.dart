import 'package:civic_voice/widgets/collapsible_list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final rail in [false, true]) {
    testWidgets('header can dispose before any scroll (compact rail=$rail)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleListHeader(
              header: const Text('Expanded filters'),
              collapsedHeader: rail ? const Text('Compact filters') : null,
              child: ListView(children: const [Text('Fixture content')]),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
