import 'package:civic_voice/core/theme/app_map_style.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/civic_glass_card.dart';
import '../widgets/location_picker_chrome.dart';
import '../controllers/location_picker_controller.dart';
import '../models/location.dart';
import '../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final Location? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final LocationPickerController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = LocationPickerController(
      initialLocation: widget.initialLocation,
    )..addListener(_onControllerChanged);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.initialize(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmLocation() async {
    final location = await _controller.confirmSelection();
    if (!mounted || location == null) return;
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerMove: (_) {
              FocusScope.of(context).unfocus();
              _controller.beginMapGesture();
            },
            child: GoogleMap(
              style: AppMapStyle.of(context),
              initialCameraPosition: _controller.initialCameraPosition,
              onMapCreated: _controller.attachMap,
              onCameraMove: _controller.onCameraMove,
              onCameraMoveStarted: _controller.onCameraMoveStarted,
              onCameraIdle: _controller.onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: false,
            ),
          ),
          const _CenterPin(),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: _SearchPanel(
                controller: _searchController,
                picker: _controller,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: 320,
            child: _CurrentLocationButton(
              onPressed: _controller.useCurrentLocation,
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _SelectedLocationCard(
                picker: _controller,
                onConfirm: _confirmLocation,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            child: _RoundIconButton(
              icon: AppIcons.back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (_controller.statusMessage != null &&
              !_controller.resolvingAddress &&
              !_controller.initializing)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: MediaQuery.paddingOf(context).top + 88,
              child: _StatusBanner(
                message: _controller.statusMessage!,
                actionLabel: _actionLabelFor(_controller.accessStatus),
                onAction: _controller.openSettingsForCurrentState,
              ),
            ),
          if (_controller.mapConfigurationWarning != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 246,
              child: _MapConfigBanner(
                message: _controller.mapConfigurationWarning!,
              ),
            ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  String? _actionLabelFor(LocationAccessStatus status) {
    return switch (status) {
      LocationAccessStatus.gpsDisabled => 'Turn On',
      LocationAccessStatus.permissionDenied => 'Allow',
      LocationAccessStatus.permissionDeniedForever => 'Settings',
      _ => null,
    };
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.controller, required this.picker});

  final TextEditingController controller;
  final LocationPickerController picker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        elevation: AppElevation.level3,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
        borderRadius: AppRadius.allXl,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocationPickerSearchField(
              controller: controller,
              onChanged: picker.search,
              searching: picker.searching,
            ),
            if (picker.resolvingAddress || picker.initializing)
              LocationPickerBusyStatus(
                message: picker.statusMessage ?? 'Loading, please wait...',
              ),
            if (picker.suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: picker.suggestions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = picker.suggestions[index];
                    return ListTile(
                      leading: const Icon(AppIcons.location),
                      title: Text(
                        suggestion.mainText ?? suggestion.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: suggestion.secondaryText == null
                          ? null
                          : Text(
                              suggestion.secondaryText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () {
                        controller.text = suggestion.description;
                        FocusScope.of(context).unfocus();
                        picker.selectSuggestion(suggestion);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  const _SelectedLocationCard({required this.picker, required this.onConfirm});

  final LocationPickerController picker;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = picker.selectedLocation;

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Selected Address', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            location?.formattedAddress ?? 'Move the map to select a location',
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InfoChip(
                  icon: AppIcons.pinned,
                  label: _fallback(location?.landmark, 'Landmark pending'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: AppIcons.navigate,
                  label: _fallback(location?.locality, 'Town/City pending'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: AppIcons.location,
                  label: _fallback(
                    location?.administrativeArea,
                    'Region pending',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: picker.canConfirm ? onConfirm : null,
              icon: const Icon(AppIcons.chevronRight),
              label: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }

  String _fallback(String? value, String fallback) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? fallback : clean;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: AppSemanticColors.of(context).actionText,
          ),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: AppSemanticColors.of(context).actionFill,
                elevation: AppElevation.level3,
                shadowColor: AppColors.primary.withValues(alpha: 0.32),
                shape: const CircleBorder(),
                child: SizedBox.square(
                  dimension: 52,
                  child: Icon(
                    AppIcons.pinned,
                    color: AppSemanticColors.of(context).onAction,
                    size: AppIconSize.lg,
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).actionFill,
                  borderRadius: AppRadius.allXs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _RoundIconButton(
      icon: AppIcons.myLocation,
      tooltip: 'Use Current Location',
      onPressed: onPressed,
      emphasize: true,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasize = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: emphasize
            ? semantic.actionFill
            : theme.colorScheme.surface.withValues(alpha: 0.96),
        elevation: AppElevation.level3,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
        shape: CircleBorder(
          side: emphasize
              ? BorderSide(color: semantic.onAction, width: 2)
              : BorderSide.none,
        ),
        child: IconButton(
          onPressed: onPressed,
          color: emphasize ? semantic.onAction : null,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      backgroundColor: AppColors.warning.withValues(alpha: 0.14),
      child: Row(
        children: [
          const Icon(AppIcons.warning, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _MapConfigBanner extends StatelessWidget {
  const _MapConfigBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CivicGlassCard(
      backgroundColor: AppColors.error.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.error, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
