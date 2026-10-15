import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';

/// Resolve an explicitly named district, never infer jurisdiction from which
/// officers happen to exist. Ambiguous/unknown geocoder output stays unknown.
String? reportAssemblyFor(Region? region, Iterable<String?> districtNames) {
  if (region == null) return null;
  String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\b(metropolitan|municipal|district|assembly)\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  final names = districtNames
      .whereType<String>()
      .map(normalize)
      .where((name) => name.isNotEmpty)
      .toSet();
  final matches = (ghanaAssemblies[region] ?? const [])
      .where((assembly) => names.contains(normalize(assembly.name)))
      .toList();
  return matches.length == 1 ? matches.single.name : null;
}
