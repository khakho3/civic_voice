import 'package:civic_voice/core/theme/app_map_style.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/api_client.dart';
import '../../../widgets/busy_indicator.dart';
import '../../../widgets/confirm_dialog.dart';
import '../services/report_duplicates_service.dart';
import 'nearby_seconding_card.dart';

enum DuplicateChoice { different, seconded, ownReport }

class DuplicateDecision {
  const DuplicateDecision(this.choice, [this.candidate]);
  final DuplicateChoice choice;
  final ReportDuplicateCandidate? candidate;
}

class ReportDuplicatesSheet extends StatefulWidget {
  const ReportDuplicatesSheet({
    super.key,
    required this.candidates,
    required this.confirm,
  });
  final List<ReportDuplicateCandidate> candidates;
  final Future<void> Function(NearbySecondingReport) confirm;
  @override
  State<ReportDuplicatesSheet> createState() => _ReportDuplicatesSheetState();
}

class _ReportDuplicatesSheetState extends State<ReportDuplicatesSheet> {
  bool _busy = false;
  bool _uncertain = false;
  String? _error;
  String? _map;

  Future<void> _second(ReportDuplicateCandidate item) async {
    if (_busy || _uncertain) return;
    setState(() => _busy = true);
    try {
      final accepted = await showConfirmDialog(
        context,
        title: 'Confirm this existing issue?',
        message:
            'Confirm only if you can see the issue is still present. We will check your current location. This records your confirmation instead of creating another report.',
        confirmLabel: 'Confirm existing issue',
      );
      if (!mounted || !accepted) return;
      await widget.confirm(item.report);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(DuplicateDecision(DuplicateChoice.seconded, item));
      }
    } catch (error) {
      if (!mounted) return;
      final knownRejection =
          error is ApiException &&
          error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408;
      setState(() {
        _uncertain = !knownRejection;
        _error = knownRejection
            ? error.message
            : 'We could not verify whether your confirmation was saved. Check Nearby Reports before confirming again. Your draft is saved.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Could this already be reported?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'These open reports are near your selected issue pin. Confirm only an issue you can personally see is still present.',
          ),
          for (final item in widget.candidates)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.report.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${item.report.reference} · ${item.report.category}'),
                    Text(
                      '${item.status.label} · ${item.report.distanceMeters.round()} m from your issue pin',
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _map = _map == item.report.id
                                  ? null
                                  : item.report.id,
                            ),
                      child: Text(
                        _map == item.report.id
                            ? 'Hide location'
                            : 'View location',
                      ),
                    ),
                    if (_map == item.report.id)
                      SizedBox(
                        height: 180,
                        child: GoogleMap(
                          style: AppMapStyle.of(context),
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              item.report.latitude!,
                              item.report.longitude!,
                            ),
                            zoom: 16,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(item.report.id),
                              position: LatLng(
                                item.report.latitude!,
                                item.report.longitude!,
                              ),
                            ),
                          },
                        ),
                      ),
                    if (item.ownedByMe)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(
                                DuplicateDecision(
                                  DuplicateChoice.ownReport,
                                  item,
                                ),
                              ),
                        child: const Text('View my existing report'),
                      )
                    else if (item.canSecond)
                      OutlinedButton(
                        onPressed: _busy || _uncertain
                            ? null
                            : () => _second(item),
                        child: const Text('This is the same issue'),
                      )
                    else
                      Text(
                        item.secondedByMe
                            ? 'You have already confirmed this report.'
                            : 'This report is not accepting confirmations.',
                      ),
                  ],
                ),
              ),
            ),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          FilledButton(
            onPressed: _busy
                ? null
                : () => Navigator.of(
                    context,
                  ).pop(const DuplicateDecision(DuplicateChoice.different)),
            child: BusyLabel(
              busy: _busy,
              busyLabel: 'Checking confirmation',
              child: const Text('Report a different issue'),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Back to my draft'),
          ),
        ],
      ),
    ),
  );
}
