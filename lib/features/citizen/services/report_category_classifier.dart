import '../../../models/report_category.dart';

/// Assigns a [ReportCategory] from a report's title and description —
/// deterministic keyword matching, no network call or AI model, so it's
/// instant and works offline. Citizens no longer pick a category manually;
/// that step also had no field for "Other, please specify," so removing
/// the picker removes a dead end along with the extra work.
class ReportCategoryClassifier {
  const ReportCategoryClassifier._();

  static const Map<ReportCategory, List<String>> _keywords = {
    ReportCategory.infrastructure: [
      'road',
      'roads',
      'pothole',
      'potholes',
      'street',
      'sidewalk',
      'pavement',
      'bridge',
      'drain',
      'drainage',
      'gutter',
      'flood',
      'flooding',
      'light',
      'lights',
      'lighting',
      'streetlight',
      'lamp',
      'water',
      'pipe',
      'pipeline',
      'leak',
      'leaking',
      'electricity',
      'power',
      'outage',
      'cable',
      'cables',
      'wire',
      'wires',
      'pole',
      'traffic',
      'signal',
      'construction',
    ],
    ReportCategory.safety: [
      'security',
      'unsafe',
      'danger',
      'dangerous',
      'crime',
      'theft',
      'robbery',
      'assault',
      'fire',
      'accident',
      'violence',
      'harassment',
      'weapon',
      'gun',
      'fight',
      'fighting',
      'attack',
      'attacked',
      'threat',
      'threatened',
      'stray',
      'animal',
      'collapse',
      'collapsed',
      'emergency',
    ],
    ReportCategory.sanitation: [
      'sanitation',
      'waste',
      'garbage',
      'trash',
      'dump',
      'dumping',
      'sewage',
      'sewer',
      'toilet',
      'refuse',
      'litter',
      'dirty',
      'smell',
      'odor',
      'odour',
      'rubbish',
      'disposal',
      'bin',
      'bins',
      'overflow',
      'overflowing',
      'flies',
      'rats',
      'mosquito',
      'mosquitoes',
    ],
  };

  static ReportCategory classify({
    required String title,
    required String description,
  }) {
    final text = '$title $description'.toLowerCase();
    var bestCategory = ReportCategory.other;
    var bestScore = 0;

    for (final entry in _keywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }
}
