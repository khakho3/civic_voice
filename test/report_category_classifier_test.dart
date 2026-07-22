import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/features/citizen/services/report_category_classifier.dart';
import 'package:civic_voice/models/report_category.dart';

void main() {
  group('ReportCategoryClassifier', () {
    test('classifies a plain infrastructure report as Infrastructure', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Pothole on Main Street',
          description: 'A large pothole has formed near the junction.',
        ),
        ReportCategory.infrastructure,
      );
    });

    test('classifies a sanitation report as Sanitation', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Overflowing bin',
          description: 'Garbage bin has been overflowing for a week.',
        ),
        ReportCategory.sanitation,
      );
    });

    test('falls back to Other when nothing matches', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'General feedback',
          description: 'Just wanted to say the new app looks nice.',
        ),
        ReportCategory.other,
      );
    });

    test(
      'an unprotected electric wire is classified as Safety, not Infrastructure',
      () {
        // Regression: 'wire' alone scores Infrastructure a point with
        // nothing to counter it unless Safety also recognizes the
        // hazard-describing words citizens actually use.
        expect(
          ReportCategoryClassifier.classify(
            title: 'Unprotected electric wire',
            description: 'There is an unprotected electric wire hanging low near the school.',
          ),
          ReportCategory.safety,
        );
      },
    );

    test('an exposed cable is classified as Safety', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Exposed cable near bus stop',
          description: 'A cable is exposed and touching the ground.',
        ),
        ReportCategory.safety,
      );
    });

    test('a sparking wire is classified as Safety', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Sparking wire',
          description: 'There is sparking coming from the wire.',
        ),
        ReportCategory.safety,
      );
    });

    test('faulty wiring is classified as Safety', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Faulty wiring',
          description: 'The wiring here looks faulty and unsafe.',
        ),
        ReportCategory.safety,
      );
    });

    test(
      "'I live near' does not get misread as a live-wire hazard signal",
      () {
        // 'live' is deliberately excluded from the Safety keyword list —
        // this is the exact false-positive it would otherwise cause.
        expect(
          ReportCategoryClassifier.classify(
            title: 'Broken streetlight',
            description: 'I live near this street and the light has been out for days.',
          ),
          ReportCategory.infrastructure,
        );
      },
    );

    test('an explicit crime report is still classified as Safety', () {
      expect(
        ReportCategoryClassifier.classify(
          title: 'Robbery near the market',
          description: 'A robbery just happened near the market entrance.',
        ),
        ReportCategory.safety,
      );
    });
  });
}
