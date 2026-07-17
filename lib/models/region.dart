/// Ghana's 16 administrative regions — the jurisdiction unit municipal,
/// district, and metropolitan assembly accounts are scoped to. Citizen
/// reports capture this at submission time (derived from the reverse-
/// geocoded location) so they can eventually route to the assembly
/// covering that region; Ministry and System Administrator accounts are
/// national, so they have no region of their own.
enum Region {
  greaterAccra('Greater Accra'),
  ashanti('Ashanti'),
  western('Western'),
  westernNorth('Western North'),
  central('Central'),
  eastern('Eastern'),
  volta('Volta'),
  oti('Oti'),
  northern('Northern'),
  northEast('North East'),
  savannah('Savannah'),
  upperEast('Upper East'),
  upperWest('Upper West'),
  bono('Bono'),
  bonoEast('Bono East'),
  ahafo('Ahafo');

  const Region(this.label);

  final String label;

  /// Maps a reverse-geocoded `administrativeArea` string onto a [Region].
  ///
  /// Geocoder output varies ("Greater Accra", "Greater Accra Region",
  /// different casing) so this matches case-insensitively and tolerates a
  /// trailing "Region". Returns `null` rather than throwing when nothing
  /// matches — a report should still be submittable even if the device's
  /// geocoder returns an unrecognized or empty string.
  static Region? fromAdministrativeArea(String? value) {
    final cleaned = value?.trim().toLowerCase();
    if (cleaned == null || cleaned.isEmpty) return null;
    final normalized = cleaned.endsWith(' region')
        ? cleaned.substring(0, cleaned.length - ' region'.length)
        : cleaned;

    for (final region in Region.values) {
      if (region.label.toLowerCase() == normalized) return region;
    }
    return null;
  }
}
