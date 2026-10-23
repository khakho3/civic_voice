import 'package:civic_voice/core/theme/app_map_style.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../widgets/async_action_button.dart';
import '../../../widgets/busy_indicator.dart';
import 'civic_glass_card.dart';
import 'nearby_seconding_card.dart';

/// Privacy-limited nearby summaries. Foreign reports never enter own tracking.
class NearbyReportsSheet extends StatefulWidget {
  const NearbyReportsSheet({
    super.key,
    required this.load,
    required this.confirm,
  });
  final Future<List<NearbySecondingReport>> Function() load;
  final Future<void> Function(NearbySecondingReport) confirm;
  @override
  State<NearbyReportsSheet> createState() => _NearbyReportsSheetState();
}

class _NearbyReportsSheetState extends State<NearbyReportsSheet> {
  List<NearbySecondingReport>? _reports;
  NearbySecondingReport? _selected;
  String? _error;
  String? _confirmationMessage;
  bool _loading = true;
  bool _confirming = false;
  bool _uncertain = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final reports = await widget.load();
      if (mounted) {
        setState(() {
          _reports = reports;
          _uncertain = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Could not check nearby reports. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _confirming || _uncertain) return;
    setState(() {
      _confirming = true;
      _confirmationMessage = null;
    });
    try {
      await widget.confirm(selected);
      if (!mounted) return;
      setState(() {
        _reports = _reports?.where((item) => item.id != selected.id).toList();
        _selected = null;
        _confirmationMessage = 'Thanks for confirming this report.';
      });
    } catch (error) {
      if (!mounted) return;
      final knownRejection =
          error is ApiException &&
          error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408;
      setState(() {
        _uncertain = !knownRejection;
        _confirmationMessage = knownRejection
            ? error.message
            : 'We could not verify whether your confirmation was saved. Refresh nearby reports before trying again.';
      });
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Semantics(
      namesRoute: true,
      label: 'Nearby Issues',
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Nearby Issues',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Reports within 300 metres that you can help confirm. Your own reports stay in My Reports.',
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const Center(
                  child: Column(
                    children: [
                      BusyIndicator(),
                      SizedBox(height: AppSpacing.sm),
                      Text('Checking nearby reports…'),
                    ],
                  ),
                ),
              if (!_loading && _error != null) ...[
                Text(_error!, semanticsLabel: _error),
                AsyncActionButton(label: 'Retry nearby', onPressed: _load),
              ],
              if (_confirmationMessage != null)
                Semantics(liveRegion: true, child: Text(_confirmationMessage!)),
              if (!_loading && _error == null && selected == null) ...[
                if (_reports?.isEmpty ?? false)
                  const Text('No reports need confirmation nearby right now.'),
                for (final report in _reports ?? <NearbySecondingReport>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => setState(() {
                          _selected = report;
                          _confirmationMessage = null;
                        }),
                        child: CivicGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${report.category} · ${report.distanceMeters.round()}m away',
                              ),
                              if (report.reference.isNotEmpty)
                                Text(report.reference),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              if (!_loading && _error == null && selected != null) ...[
                TextButton(
                  onPressed: _confirming
                      ? null
                      : () => setState(() => _selected = null),
                  child: const Text('Back to nearby reports'),
                ),
                Text(
                  selected.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (selected.latitude != null && selected.longitude != null)
                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      style: AppMapStyle.of(context),
                      liteModeEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(selected.latitude!, selected.longitude!),
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(selected.id),
                          position: LatLng(
                            selected.latitude!,
                            selected.longitude!,
                          ),
                        ),
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Confirm only if you can see that this issue is still there. We will check your current phone location.',
                ),
                if (!_uncertain)
                  AsyncActionButton(
                    label: "Confirm it's still there",
                    onPressed: _confirming ? null : _confirm,
                  ),
                TextButton(
                  onPressed: _confirming
                      ? null
                      : () => setState(() {
                          _reports = _reports
                              ?.where((item) => item.id != selected.id)
                              .toList();
                          _selected = null;
                        }),
                  child: const Text('Not sure'),
                ),
              ],
              if (!_loading)
                AsyncActionButton(
                  label: 'Refresh nearby',
                  kind: AsyncActionKind.text,
                  onPressed: _confirming ? null : _load,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
