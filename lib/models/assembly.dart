import 'region.dart';

/// The three legal classifications a Ghanaian Metropolitan/Municipal/
/// District Assembly (MMDA) can hold — Metropolitan for the largest urban
/// centres, Municipal for mid-sized single-town districts, District for
/// the rest. Assigned by the same Legislative Instrument that creates the
/// assembly, not a free choice.
enum AssemblyType {
  metropolitan('Metropolitan'),
  municipal('Municipal'),
  district('District');

  const AssemblyType(this.label);

  final String label;
}

/// One Metropolitan/Municipal/District Assembly — the jurisdiction unit a
/// System Administrator account with [AdminTier.admin] (see
/// `admin_role_management_data.dart`) is actually scoped to, one level more
/// specific than [Region]. A Municipal Officer or Maintenance Team account
/// belongs to exactly one of these too, inherited from whichever assembly
/// Admin provisioned them.
class Assembly {
  const Assembly({
    required this.name,
    required this.type,
    required this.region,
  });

  final String name;
  final AssemblyType type;
  final Region region;

  /// e.g. "Kumasi Metropolitan Assembly".
  String get fullName => '$name ${type.label} Assembly';
}
