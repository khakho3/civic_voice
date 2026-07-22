import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/report_category.dart';
import '../../../services/app_cache_service.dart';
import '../widgets/civic_glass_card.dart';
import '../models/report_draft.dart';
import '../models/create_report_view_state.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/report_category_classifier.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_tab_routes.dart';
import 'location_picker_screen.dart';
import 'photo_upload_screen.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({
    super.key,
    this.initialState = CreateReportViewState.ready,
  });

  static const String routeName = '/citizen/create-report';

  final CreateReportViewState initialState;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen>
    with WidgetsBindingObserver {
  final LocationService _locationService = const LocationService();
  late CreateReportViewState _state;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  Position? _capturedPosition;
  Location? _selectedLocation;
  bool _locationLoading = false;
  bool _locationPickerOpening = false;
  String _locationLabel = 'Tap to choose current GPS location.';
  String? _locationAddress;
  String? _locationCommunity;
  Region? _locationRegion;
  String? _locationAssembly;
  String? _locationError;
  int _locationLookupId = 0;
  Timer? _draftSaveTimer;

  ReportCategory get _classifiedCategory => ReportCategoryClassifier.classify(
    title: _titleController.text,
    description: _descriptionController.text,
  );

  bool get _hasRequiredFields => _titleController.text.trim().isNotEmpty;
  bool get _isReady =>
      _state == CreateReportViewState.ready &&
      _hasRequiredFields &&
      (_selectedLocation != null || _capturedPosition != null);
  bool get _isDisabled => _state == CreateReportViewState.disabled;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    final cached = AppCacheService.instance.reportDraft;
    _titleController = TextEditingController(text: cached?.title ?? '');
    _descriptionController = TextEditingController(
      text: cached?.description ?? '',
    );
    if (cached?.latitude != null && cached?.longitude != null) {
      _selectedLocation = Location(
        formattedAddress: cached!.location,
        latitude: cached.latitude!,
        longitude: cached.longitude!,
        locality: cached.community,
        administrativeArea: cached.region?.name ?? '',
        country: 'Ghana',
      );
      _locationAddress = cached.location;
      _locationCommunity = cached.community;
      _locationRegion = cached.region;
      _locationAssembly = cached.assembly;
      _locationLabel = cached.location;
      _state = CreateReportViewState.ready;
    } else if (cached != null && cached.title.trim().isNotEmpty) {
      _state = CreateReportViewState.draft;
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    unawaited(_saveDraft());
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _selectedLocation == null &&
        _capturedPosition == null) {
      _captureLocation();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveDraft());
    }
  }

  Future<void> _openLocationPicker() async {
    if (_locationPickerOpening) return;
    _locationPickerOpening = true;
    final location = await Navigator.of(context).push<Location>(
      MaterialPageRoute<Location>(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    _locationPickerOpening = false;

    if (!mounted || location == null) return;
    setState(() {
      _selectedLocation = location;
      _state = CreateReportViewState.ready;
      _locationAddress = location.formattedAddress;
      _locationCommunity = location.locality.isNotEmpty
          ? location.locality
          : location.administrativeArea;
      _locationRegion = Region.fromAdministrativeArea(
        location.administrativeArea,
      );
      _locationLabel = location.formattedAddress;
      _locationError = null;
      _locationLoading = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _captureLocation() async {
    if (_locationLoading) return;
    setState(() {
      _locationLoading = true;
      _state = CreateReportViewState.permissionRequired;
      _locationLabel = 'Checking phone location permission...';
      _locationError = null;
    });

    final result = await _locationService.requestCurrentPosition();
    if (!mounted) return;

    switch (result.status) {
      case LocationAccessStatus.gpsDisabled:
        setState(() {
          _state = CreateReportViewState.gpsDisabled;
          _locationLabel = 'Turn on GPS to capture your current location.';
          _locationError = result.message;
          _locationLoading = false;
        });
      case LocationAccessStatus.permissionDenied:
        setState(() {
          _state = CreateReportViewState.permissionRequired;
          _locationLabel = 'Allow location permission to capture GPS.';
          _locationError = result.message;
          _locationLoading = false;
        });
      case LocationAccessStatus.permissionDeniedForever:
        setState(() {
          _state = CreateReportViewState.permissionDenied;
          _locationLabel =
              'Location permission is blocked. Enable it in phone settings.';
          _locationError = result.message;
          _locationLoading = false;
        });
      case LocationAccessStatus.unavailable:
        setState(() {
          _state = _capturedPosition == null
              ? CreateReportViewState.gpsDisabled
              : CreateReportViewState.ready;
          _locationLabel = _capturedPosition == null
              ? 'Unable to capture GPS. Check location services and try again.'
              : _locationLabel;
          _locationError = result.message;
          _locationLoading = false;
        });
      case LocationAccessStatus.ready:
        _setCapturedPosition(result.position!, labelPrefix: 'GPS captured');
    }
  }

  void _setCapturedPosition(
    Position position, {
    required String labelPrefix,
    bool keepLoading = false,
  }) {
    if (!mounted) return;
    final lookupId = ++_locationLookupId;
    setState(() {
      _capturedPosition = position;
      _state = CreateReportViewState.ready;
      _locationLabel = '$labelPrefix. Finding address...';
      _locationAddress = null;
      _locationCommunity = null;
      _locationRegion = null;
      _locationAssembly = null;
      _locationError = null;
      _locationLoading = keepLoading;
    });
    _resolveAddress(position, labelPrefix: labelPrefix, lookupId: lookupId);
  }

  Future<void> _resolveAddress(
    Position position, {
    required String labelPrefix,
    required int lookupId,
  }) async {
    try {
      final places = await geocoding.Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 8));
      if (!mounted || lookupId != _locationLookupId || places.isEmpty) return;

      final place = places.first;
      final address = _formatAddress(place, position);
      final community = _formatCommunity(place);

      setState(() {
        _locationAddress = address;
        _locationCommunity = community;
        _locationRegion = Region.fromAdministrativeArea(
          place.administrativeArea,
        );
        _locationAssembly = _matchAssembly(place, _locationRegion);
        _locationLabel = '$labelPrefix: $address';
      });
      _scheduleDraftSave();
    } catch (error) {
      if (!mounted || lookupId != _locationLookupId) return;
      setState(() {
        _locationError =
            'GPS was captured, but address lookup failed: ${error.toString()}';
      });
    }
  }

  String _formatAddress(geocoding.Placemark place, Position position) {
    final parts = <String>[
      if (_clean(place.street).isNotEmpty) _clean(place.street),
      if (_clean(place.subLocality).isNotEmpty) _clean(place.subLocality),
      if (_clean(place.locality).isNotEmpty) _clean(place.locality),
      if (_clean(place.administrativeArea).isNotEmpty)
        _clean(place.administrativeArea),
    ];
    final address = _dedupe(parts).join(', ');
    if (address.isNotEmpty) return address;
    return 'Selected report location';
  }

  String _formatCommunity(geocoding.Placemark place) {
    final parts = <String>[
      if (_clean(place.subLocality).isNotEmpty) _clean(place.subLocality),
      if (_clean(place.locality).isNotEmpty) _clean(place.locality),
      if (_clean(place.subAdministrativeArea).isNotEmpty)
        _clean(place.subAdministrativeArea),
      if (_clean(place.administrativeArea).isNotEmpty)
        _clean(place.administrativeArea),
    ];
    final unique = _dedupe(parts);
    return unique.isEmpty ? 'Nearby community' : unique.take(2).join(', ');
  }

  String? _matchAssembly(geocoding.Placemark place, Region? region) {
    if (region == null) return null;
    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(
          RegExp(r'\b(metropolitan|municipal|district|assembly)\b'),
          '',
        )
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final candidates = [
      place.subAdministrativeArea,
      place.locality,
    ].map(_clean).where((value) => value.isNotEmpty).map(normalize).toList();
    for (final assembly in ghanaAssemblies[region] ?? const []) {
      final name = normalize(assembly.name);
      if (candidates.any(
        (candidate) => candidate.contains(name) || name.contains(candidate),
      )) {
        return assembly.name;
      }
    }
    return null;
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final key = value.toLowerCase();
      if (seen.add(key)) result.add(value);
    }
    return result;
  }

  String _clean(String? value) {
    return value?.trim() ?? '';
  }

  void _showLocationError() {
    final message = _locationError ?? 'Location is not available yet.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _continueToPhotos() async {
    if (!_hasRequiredFields) {
      setState(() => _state = CreateReportViewState.validationError);
      return;
    }
    if (_selectedLocation == null && _capturedPosition == null) {
      setState(() {
        _state = CreateReportViewState.validationError;
        _locationError = 'Choose a current GPS location before continuing.';
        _locationLabel = 'Tap to choose current GPS location.';
      });
      return;
    }

    final selected = _selectedLocation;
    await _saveDraft();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoUploadScreen(
          reportTitle: _titleController.text.trim(),
          reportDescription: _descriptionController.text.trim(),
          reportCategory: _classifiedCategory.label,
          reportLocationLabel:
              selected?.formattedAddress ?? _locationAddress ?? _locationLabel,
          reportCommunity:
              selected?.locality ??
              selected?.administrativeArea ??
              _locationCommunity,
          reportLatitude: selected?.latitude ?? _capturedPosition!.latitude,
          reportLongitude: selected?.longitude ?? _capturedPosition!.longitude,
          reportRegion: _locationRegion,
          reportAssembly: _locationAssembly,
        ),
      ),
    );
  }

  void _handleFormChanged() {
    setState(() {
      if (_state == CreateReportViewState.validationError &&
          _hasRequiredFields) {
        _state = _capturedPosition == null
            ? CreateReportViewState.draft
            : CreateReportViewState.ready;
      }
    });
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() {
    final selected = _selectedLocation;
    final current = AppCacheService.instance.reportDraft;
    return AppCacheService.instance.saveReportDraft(
      ReportDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _classifiedCategory.label,
        location:
            selected?.formattedAddress ?? _locationAddress ?? _locationLabel,
        community:
            selected?.locality ??
            selected?.administrativeArea ??
            _locationCommunity ??
            '',
        latitude: selected?.latitude ?? _capturedPosition?.latitude,
        longitude: selected?.longitude ?? _capturedPosition?.longitude,
        region: _locationRegion,
        assembly: _locationAssembly,
        photoPaths: current?.photoPaths ?? const <String>[],
      ),
    );
  }

  Future<void> _openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await _locationService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      // CivicTopBar/CivicBottomNav are Align-positioned in a Stack, not real
      // Scaffold slots — the default (true) resize shrank the whole Stack
      // as the keyboard opened, re-anchoring the bottom nav mid-screen
      // above the keyboard instead of at the true bottom edge. False keeps
      // header/nav pinned to the true screen edges always; civicContentPadding
      // reserves the keyboard's own height instead so scrollable content
      // still clears it.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final horizontalPadding = compact
                    ? AppSpacing.sm
                    : AppSpacing.md;
                final chromeInset = civicContentPadding(context);

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    chromeInset.top + AppSpacing.lg,
                    horizontalPadding,
                    chromeInset.bottom + AppSpacing.lg,
                  ),
                  children: [
                    _CreateReportBanner(state: _state),
                    _ReportTextField(
                      label: 'Issue Title',
                      requiredField: true,
                      controller: _titleController,
                      hint: 'e.g. Broken streetlight on Main Road',
                      hasError: _state == CreateReportViewState.validationError,
                      onChanged: (_) => _handleFormChanged(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ReportTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint:
                          'Describe the issue in as much detail as possible...',
                      minHeight: 128,
                      minLines: 4,
                      onChanged: (_) => _handleFormChanged(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryPreview(category: _classifiedCategory),
                    const SizedBox(height: AppSpacing.lg),
                    _LocationCard(
                      state: _state,
                      locationLabel: _locationLabel,
                      loading: _locationLoading,
                      onCaptureLocation: _openLocationPicker,
                      onOpenLocationSettings: _openLocationSettings,
                      onOpenAppSettings: _openAppSettings,
                      onShowLocationError: _showLocationError,
                      position: _capturedPosition,
                      selectedLocation: _selectedLocation,
                      error: _locationError,
                      address: _locationAddress,
                      community: _locationCommunity,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isReady)
                      const _InlineFeedback(
                        icon: AppIcons.success,
                        color: AppColors.success,
                        message: 'Details are ready. Next, add photos.',
                      ),
                    if (_state == CreateReportViewState.validationError)
                      const _InlineFeedback(
                        icon: AppIcons.error,
                        color: AppColors.error,
                        message: 'Check required fields and try again.',
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    CivicGlassCard(
                      borderRadius: AppRadius.allXl,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isDisabled ? null : _continueToPhotos,
                          icon: const Icon(AppIcons.chevronRight),
                          label: const Text('Continue to Photos'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            // No onBack — this is a bottom-nav destination (index 2), not a
            // drill-down; tapping Home in the bottom nav below already does
            // the exact same maybePop(), so a header back arrow here was
            // pure redundancy, matching the same fix applied to every other
            // primary tab in this module.
            child: CivicTopBar(title: 'Create Report', showNotifications: false),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 2,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).maybePop();
                  } else if (index == 1) {
                    Navigator.of(context).pushAndRemoveUntil(
                      citizenReportsTabRoute(context),
                      (route) => route.isFirst,
                    );
                  } else if (index == 3) {
                    Navigator.of(context).pushAndRemoveUntil(
                      citizenAlertsTabRoute(context),
                      (route) => route.isFirst,
                    );
                  } else if (index == 4) {
                    Navigator.of(context).pushAndRemoveUntil(
                      citizenProfileTabRoute(context),
                      (route) => route.isFirst,
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateReportBanner extends StatelessWidget {
  const _CreateReportBanner({required this.state});

  final CreateReportViewState state;

  @override
  Widget build(BuildContext context) {
    final data = switch (state) {
      CreateReportViewState.draft => null,
      CreateReportViewState.ready => null,
      CreateReportViewState.validationError => (
        AppIcons.error,
        AppColors.error,
        'Unable to continue',
        'Check required fields and try again.',
      ),
      CreateReportViewState.offline => (
        AppIcons.offline,
        AppColors.warning,
        'You are offline',
        'Drafts are saved locally until connection returns.',
      ),
      CreateReportViewState.permissionRequired => (
        AppIcons.permissionDenied,
        AppColors.warning,
        'Permission required',
        'Allow location access to capture GPS automatically.',
      ),
      CreateReportViewState.permissionDenied => (
        AppIcons.permissionDenied,
        AppColors.error,
        'Location permission denied',
        'Enable location permission or use Change Location.',
      ),
      CreateReportViewState.gpsDisabled => (
        AppIcons.location,
        AppColors.warning,
        'GPS disabled',
        'Turn on GPS to capture your current location.',
      ),
      CreateReportViewState.disabled => (
        AppIcons.warning,
        AppColors.warning,
        'Reporting disabled',
        'Submissions are temporarily unavailable.',
      ),
    };

    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: _InlineFeedback(
        icon: data.$1,
        color: data.$2,
        title: data.$3,
        message: data.$4,
      ),
    );
  }
}

class _ReportTextField extends StatelessWidget {
  const _ReportTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.requiredField = false,
    this.hasError = false,
    this.minHeight = AppDimensions.controlHeightStandard,
    this.minLines = 1,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool requiredField;
  final bool hasError;
  final double minHeight;
  final int minLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.titleSmall,
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 5,
          onChanged: onChanged,
          textInputAction: minLines == 1
              ? TextInputAction.next
              : TextInputAction.newline,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            constraints: BoxConstraints(minHeight: minHeight),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(color: AppColors.primary, width: 1.6),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(color: AppColors.error, width: 1.6),
            ),
            errorText: hasError && controller.text.trim().isEmpty
                ? 'Required'
                : null,
          ),
        ),
      ],
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.category});

  final ReportCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Category', style: theme.textTheme.titleSmall),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.allXl,
          ),
          child: Text(
            category.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Detected from your title and description.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.state,
    required this.locationLabel,
    required this.loading,
    required this.onCaptureLocation,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    required this.onShowLocationError,
    required this.position,
    required this.selectedLocation,
    required this.error,
    required this.address,
    required this.community,
  });

  final CreateReportViewState state;
  final String locationLabel;
  final bool loading;
  final VoidCallback onCaptureLocation;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onShowLocationError;
  final Position? position;
  final Location? selectedLocation;
  final String? error;
  final String? address;
  final String? community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedLocation;
    final captured = position;
    final hasLocation = selected != null || captured != null;
    final readableAddress = selected?.formattedAddress ?? address;
    final readableCommunity =
        selected?.locality ?? selected?.administrativeArea ?? community;
    final locationColor = hasLocation ? AppColors.success : AppColors.warning;
    final LatLng? previewTarget;
    if (selected != null) {
      previewTarget = LatLng(selected.latitude, selected.longitude);
    } else if (captured != null) {
      previewTarget = LatLng(captured.latitude, captured.longitude);
    } else {
      previewTarget = null;
    }

    return Semantics(
      button: true,
      label: 'Choose current GPS location',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onCaptureLocation,
        child: CivicGlassCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppIconSize.xl,
                    height: AppIconSize.xl,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.allLg,
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(AppIcons.myLocation, color: locationColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current GPS Location',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          readableAddress ?? locationLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 168,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: previewTarget == null
                    ? Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(AppIcons.location),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'Map preview appears after GPS capture',
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _LocationMapPreview(
                        target: previewTarget,
                        label: readableAddress ?? 'Selected report location',
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: state == CreateReportViewState.gpsDisabled
                    ? OutlinedButton.icon(
                        onPressed: loading ? null : onOpenLocationSettings,
                        icon: const Icon(AppIcons.settings),
                        label: const Text('Open Location Settings'),
                      )
                    : state == CreateReportViewState.permissionDenied
                    ? OutlinedButton.icon(
                        onPressed: loading ? null : onOpenAppSettings,
                        icon: const Icon(AppIcons.settings),
                        label: const Text('Open App Settings'),
                      )
                    : OutlinedButton.icon(
                        onPressed: loading ? null : onCaptureLocation,
                        icon: const Icon(AppIcons.location),
                        label: Text(
                          hasLocation ? 'Refresh Location' : 'Capture Location',
                        ),
                      ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: TextButton.icon(
                    onPressed: onShowLocationError,
                    icon: const Icon(AppIcons.info),
                    label: const Text('Details'),
                  ),
                ),
              ],
              if (hasLocation) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.center,
                  children: [
                    if (readableCommunity != null &&
                        readableCommunity.isNotEmpty)
                      _LocationMetaChip(
                        icon: AppIcons.pinned,
                        label: readableCommunity,
                      ),
                    _LocationMetaChip(
                      icon: AppIcons.myLocation,
                      label: captured == null
                          ? 'Google Maps selected'
                          : 'Accuracy: ${captured.accuracy.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({required this.target, required this.label});

  final LatLng target;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          key: ValueKey(
            '${target.latitude.toStringAsFixed(6)},'
            '${target.longitude.toStringAsFixed(6)}',
          ),
          initialCameraPosition: CameraPosition(target: target, zoom: 16),
          markers: {
            Marker(
              markerId: const MarkerId('report-location'),
              position: target,
            ),
          },
          compassEnabled: false,
          liteModeEnabled: true,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: false,
        ),
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: AppRadius.allMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.pinned,
                    color: AppColors.primary,
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationMetaChip extends StatelessWidget {
  const _LocationMetaChip({required this.icon, required this.label});

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
          Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({
    required this.icon,
    required this.color,
    required this.message,
    this.title,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
