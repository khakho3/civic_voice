class Location {
  const Location({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.administrativeArea,
    required this.country,
    this.landmark,
    this.assembly,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String locality;
  final String administrativeArea;
  final String country;
  final String? landmark;
  final String? assembly;

  bool get hasReadableAddress => formattedAddress.trim().isNotEmpty;
}
