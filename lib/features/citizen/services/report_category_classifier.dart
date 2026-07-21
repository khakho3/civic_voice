import '../../../models/report_category.dart';

/// Assigns a [ReportCategory] from a report's title and description —
/// deterministic keyword matching, no network call or AI model, so it's
/// instant and works offline. Citizens no longer pick a category manually;
/// that step also had no field for "Other, please specify," so removing
/// the picker removes a dead end along with the extra work.
class ReportCategoryClassifier {
  const ReportCategoryClassifier._();

  static const Map<ReportCategory, List<String>> _keywords = {
    // Safety listed first: classify() keeps the first category to reach
    // the top score and never displaces it on a tie (see below), so
    // ordering *is* priority. A pothole+accident report or a wiring
    // report that also reads as electrocution risk should resolve to
    // Safety, not lose a tie to Infrastructure just because that entry
    // happened to be declared first — a missed safety report is worse
    // than a missed infrastructure one.
    ReportCategory.safety: [
      'security',
      'unsafe',
      'danger',
      'dangerous',
      'hazard',
      'hazardous',
      'toxic',
      'poison',
      'poisoned',
      'crime',
      'theft',
      'steal',
      'stolen',
      'robbery',
      'robber',
      'robbers',
      'robbed',
      'mugging',
      'mugged',
      'armed',
      'assault',
      'assaulted',
      'rape',
      'raped',
      'molest',
      'molested',
      'abuse',
      'abused',
      'kidnap',
      'kidnapped',
      'fire',
      'explosion',
      'explode',
      'exploded',
      'accident',
      'crash',
      'crashed',
      'collision',
      'violence',
      'harassment',
      'harassed',
      'weapon',
      'gun',
      'shooting',
      'shot',
      'knife',
      'stabbed',
      'stabbing',
      'fight',
      'fighting',
      'attack',
      'attacked',
      'threat',
      'threatened',
      'stray',
      'animal',
      'bite',
      'bitten',
      'rabid',
      'aggressive',
      'collapse',
      'collapsed',
      'collapsing',
      'electrocute',
      'electrocuted',
      'electrocution',
      'shock',
      'shocked',
      'injury',
      'injured',
      'hurt',
      'bleeding',
      'unconscious',
      'drowning',
      'drown',
      'trapped',
      'emergency',
    ],
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

    // Strictly-greater comparison means a tie keeps whichever category
    // was already in the lead, i.e. whichever appears first in
    // _keywords — that's why Safety is declared first above, not an
    // incidental ordering.
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
