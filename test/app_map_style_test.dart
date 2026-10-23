import 'dart:convert';
import 'package:civic_voice/core/theme/app_map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'map styles follow app theme and restore default tiles in light mode',
    (tester) async {
      String? style;
      Future<void> show(Brightness brightness) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) {
              style = AppMapStyle.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await show(Brightness.dark);
      expect(jsonDecode(style!), isA<List<dynamic>>());
      expect(
        (jsonDecode(style!) as List).first['stylers'].first['color'],
        '#202622',
      );
      await show(Brightness.light);
      await tester.pumpAndSettle();
      expect(style, isNull);
    },
  );
}
