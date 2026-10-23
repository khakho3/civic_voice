import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_map_style.dart';

class ReportLocationMapScreen extends StatelessWidget {
  const ReportLocationMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  static bool valid(double? latitude, double? longitude) =>
      latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  static Future<void> open(
    BuildContext context, {
    required double? latitude,
    required double? longitude,
    required String label,
  }) async {
    if (!valid(latitude, longitude)) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportLocationMapScreen(
          latitude: latitude!,
          longitude: longitude!,
          label: label,
        ),
      ),
    );
  }

  final double latitude;
  final double longitude;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Location'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Chip(label: Text('Read only')),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            style: AppMapStyle.of(context),
            initialCameraPosition: CameraPosition(target: target, zoom: 17),
            markers: {
              Marker(
                markerId: const MarkerId('report-location-full'),
                position: target,
                infoWindow: InfoWindow(title: label, snippet: 'Report pin'),
              ),
            },
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.location,
                        size: AppIconSize.md,
                        color: AppSemanticColors.of(context).actionText,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: AppFontWeight.semiBold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${latitude.toStringAsFixed(5)}, '
                              '${longitude.toStringAsFixed(5)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportLocationPreviewAction extends StatelessWidget {
  const ReportLocationPreviewAction({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
  });
  final double? latitude;
  final double? longitude;
  final String label;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: ReportLocationMapScreen.valid(latitude, longitude)
        ? () => ReportLocationMapScreen.open(
            context,
            latitude: latitude,
            longitude: longitude,
            label: label,
          )
        : null,
    icon: const Icon(AppIcons.navigate),
    label: const Text('View Map'),
  );
}
