import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../services/api_client.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/evidence_image_viewer.dart';
import '../../../widgets/focused_search.dart';
import '../../../widgets/report_location_map_screen.dart';
import '../../../widgets/search_filter_list.dart';
import '../models/admin_report_routing.dart';
import '../services/admin_resource.dart';
import '../services/admin_routing_repository.dart';

class AdminReportRoutingScreen extends StatefulWidget {
  const AdminReportRoutingScreen({super.key, this.repository});
  final AdminRoutingRepository? repository;
  @override
  State<AdminReportRoutingScreen> createState() =>
      _AdminReportRoutingScreenState();
}

class _AdminReportRoutingScreenState extends State<AdminReportRoutingScreen> {
  late final _repo = widget.repository ?? AdminRoutingRepository();
  late AdminResource<RoutingPage> _source;
  String _query = '';
  List<String?> _cursors = [null];
  bool _changing = false;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _source = _repo.queue(_query, _cursors.last);
    unawaited(_source.load());
  }

  void _change(VoidCallback change) {
    setState(() {
      _source.dispose();
      change();
      _changing = true;
      _create();
    });
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  Future<void> _open(RoutingReport report) async {
    if (_repo.owner() == null || _source.loading) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AdminReportRoutingDetailScreen(id: report.id, repository: _repo),
      ),
    );
    if (mounted) unawaited(_source.load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report Routing')),
    body: AnimatedBuilder(
      animation: _source,
      builder: (context, _) {
        if (_repo.owner() == null) return const _AccessRequired();
        final page = _source.data;
        return SearchFilterList(
          header: SearchFilterHeader(
            screenKey: 'admin-report-routing',
            hintText: 'Title or report reference',
            query: _query,
            enabled: !_source.loading,
            onQueryChanged: (value) => _change(() {
              _query = value.trim().substring(
                0,
                value.trim().length.clamp(0, 100),
              );
              _cursors = [null];
            }),
            results: (term) => [
              for (final report in page?.reports ?? <RoutingReport>[])
                if ('${report.title} ${report.reference}'
                    .toLowerCase()
                    .contains(term.toLowerCase()))
                  FocusedSearchResult(
                    title: report.title,
                    subtitle: report.reference,
                    onSelected: () => _open(report),
                  ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Reports needing a locality',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Check the issue pin, address and evidence to confirm its region and assembly. Officer availability does not determine geography.',
              ),
              const SizedBox(height: AppSpacing.md),
              if (_source.loading)
                _changing
                    ? const Text('Updating reports…')
                    : const GhanaLoadingIndicator(
                        label: 'Loading report routing',
                      ),
              if (_source.error != null) Text(_source.error!),
              if (page != null) ...[
                Text(
                  '${page.total} unresolved ${page.total == 1 ? 'report' : 'reports'}',
                ),
                if (page.reports.isEmpty)
                  _RoutingCard(
                    child: Text(
                      _query.isEmpty
                          ? 'No reports are waiting for locality resolution.'
                          : 'No unresolved reports match this search.',
                    ),
                  ),
                for (final report in page.reports)
                  _RoutingCard(
                    onTap: _source.loading ? null : () => _open(report),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.reference,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                report.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${report.regionLabel} · ${report.assemblyLabel}',
                              ),
                              Text(report.location ?? 'No address recorded.'),
                              if (!report.canRoute)
                                const Text('Routing is locked'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: _source.loading || _cursors.length < 2
                          ? null
                          : () => _change(() => _cursors = [null]),
                      child: const Text('First page'),
                    ),
                    TextButton(
                      onPressed:
                          _source.loading ||
                              page.nextCursor == null ||
                              _cursors.contains(page.nextCursor)
                          ? null
                          : () => _change(
                              () => _cursors = [..._cursors, page.nextCursor],
                            ),
                      child: const Text('Next page'),
                    ),
                  ],
                ),
              ],
              TextButton(
                onPressed: _source.loading
                    ? null
                    : () {
                        setState(() => _changing = false);
                        unawaited(_source.load());
                      },
                child: const Text('Refresh queue'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class AdminReportRoutingDetailScreen extends StatefulWidget {
  const AdminReportRoutingDetailScreen({
    super.key,
    required this.id,
    this.repository,
  });
  final String id;
  final AdminRoutingRepository? repository;
  @override
  State<AdminReportRoutingDetailScreen> createState() =>
      _AdminReportRoutingDetailScreenState();
}

class _AdminReportRoutingDetailScreenState
    extends State<AdminReportRoutingDetailScreen> {
  late final _repo = widget.repository ?? AdminRoutingRepository();
  late final _source = _repo.report(widget.id);
  final _reason = TextEditingController();
  Region? _region;
  String? _assembly, _viewOwner;
  RoutingReport? _last;
  RoutingAcknowledgment? _saved;
  bool _seeded = false, _confirming = false;
  @override
  void initState() {
    super.initState();
    _viewOwner = _repo.owner();
    unawaited(_source.load());
  }

  @override
  void dispose() {
    _source.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_source.writing || _confirming) return;
    if (_viewOwner != _repo.owner()) {
      _last = null;
      _seeded = false;
      _region = null;
      _assembly = null;
      _reason.clear();
      _viewOwner = _repo.owner();
    }
    _saved = null;
    await _source.load();
  }

  RoutingChange? get _change => _region == null || _assembly == null
      ? null
      : RoutingChange(_region!, _assembly!, _reason.text);
  Future<void> _save() async {
    final previous = _source.data, change = _change, owner = _repo.owner();
    if (previous == null ||
        !previous.canRoute ||
        change?.valid != true ||
        owner == null ||
        owner != _viewOwner ||
        _confirming ||
        _source.loading ||
        _source.writing ||
        _source.uncertain) {
      return;
    }
    setState(() => _confirming = true);
    try {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Confirm report routing?',
        message:
            '${previous.reference}: ${previous.regionLabel} / ${previous.assemblyLabel} → ${change!.region.label} / ${change.assembly}.\nReason: ${change.reason.trim()}',
        confirmLabel: 'Save routing',
      );
      if (!confirmed ||
          !mounted ||
          _repo.owner() != owner ||
          _source.data?.updatedAt != previous.updatedAt) {
        return;
      }
      RoutingAcknowledgment? acknowledgment;
      final saved = await _source.mutate((token, current) async {
        if (current.updatedAt != previous.updatedAt || !current.canRoute) {
          throw StateError('Report changed');
        }
        acknowledgment = await _repo.save(token, current, change);
      }, verify: (fresh) => acknowledgment?.matchesFresh(fresh) ?? false);
      if (saved && mounted && _repo.owner() == owner) {
        setState(() {
          _saved = acknowledgment;
          _reason.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _source,
    builder: (context, _) {
      final authorized = _repo.owner() != null;
      final currentOwner = _repo.owner() == _viewOwner;
      final fresh = _source.data;
      if (fresh != null && currentOwner) {
        _last = fresh;
        if (!_seeded) {
          _region = routingRegion(fresh.region);
          _assembly =
              _region != null &&
                  routingJurisdiction(_region!, fresh.assembly ?? '')
              ? fresh.assembly
              : null;
          _seeded = true;
        }
      }
      final report = currentOwner ? fresh ?? _last : null;
      final locked =
          _source.loading ||
          _source.writing ||
          _source.uncertain ||
          _confirming ||
          _source.error != null;
      return PopScope(
        canPop: !_source.writing && !_confirming,
        child: Scaffold(
          appBar: AppBar(title: const Text('Report Routing')),
          body: !authorized
              ? const _AccessRequired()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_source.loading && report == null)
                        const GhanaLoadingIndicator(label: 'Loading report'),
                      if (_source.error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(_source.error!),
                        ),
                      if (!currentOwner)
                        const Text(
                          'Your session changed. Reload to verify access to this report.',
                        ),
                      if (report != null) ...[
                        _RoutingCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${report.reference} · ${report.status.replaceAll('_', ' ')}',
                              ),
                              Text(
                                report.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                report.description ??
                                    'No description recorded.',
                              ),
                              Text(report.location ?? 'No address recorded.'),
                              if (report.community?.isNotEmpty == true)
                                Text(report.community!),
                              Text(
                                'Saved routing: ${report.regionLabel} · ${report.assemblyLabel}',
                              ),
                              Text(
                                'Last updated ${MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(report.updatedAt).toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(DateTime.parse(report.updatedAt).toLocal()))}',
                              ),
                              if (ReportLocationMapScreen.valid(
                                report.latitude,
                                report.longitude,
                              )) ...[
                                Text(
                                  'Issue pin: ${report.latitude}, ${report.longitude}',
                                ),
                                ReportLocationPreviewAction(
                                  latitude: report.latitude,
                                  longitude: report.longitude,
                                  label: report.location ?? report.title,
                                ),
                              ] else
                                const Text('No saved issue pin.'),
                              if (report.photos.isNotEmpty)
                                _RoutingEvidence(photos: report.photos),
                            ],
                          ),
                        ),
                        if (_saved != null)
                          _RoutingCard(
                            child: Semantics(
                              liveRegion: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Routing area saved',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    '${report.reference} · ${report.regionLabel} · ${report.assemblyLabel}',
                                  ),
                                  Text(
                                    _saved!.municipalOfficers == 0
                                        ? 'No active Municipal officer covers this locality yet. The report stays saved and becomes visible when a matching officer is added.'
                                        : '${_saved!.municipalOfficers} active Municipal officers cover this locality. They can see the report after refreshing their inbox.',
                                  ),
                                  Text(
                                    _saved!.auditRecorded
                                        ? 'The actor, reason and previous routing area were recorded in Activity.'
                                        : 'Audit collection is off; this change was not added to Activity.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_saved == null && !report.canRoute)
                          _RoutingCard(
                            child: Text(
                              report.unresolved
                                  ? 'Routing is locked. This report has entered review or assignment.'
                                  : 'Routing area already resolved. This queue only resolves missing localities.',
                            ),
                          ),
                        if (_saved == null && report.canRoute)
                          _RoutingCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Confirm the issue locality',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text(
                                  'Check the issue pin, address and evidence. Officer availability must not determine the assembly.',
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<Region>(
                                  label: 'Region',
                                  hint: 'Select region',
                                  value: _region,
                                  items: [
                                    for (final region in Region.values)
                                      AppDropdownItem(
                                        value: region,
                                        label: region.label,
                                      ),
                                  ],
                                  onChanged: locked
                                      ? null
                                      : (value) => setState(() {
                                          _region = value;
                                          _assembly = null;
                                        }),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<String>(
                                  label: 'Assembly',
                                  hint: _region == null
                                      ? 'Select Region first'
                                      : 'Select assembly',
                                  value: _assembly,
                                  items: [
                                    for (final assembly
                                        in ghanaAssemblies[_region] ?? [])
                                      AppDropdownItem(
                                        value: assembly.name,
                                        label: assembly.fullName,
                                      ),
                                  ],
                                  onChanged: locked || _region == null
                                      ? null
                                      : (value) =>
                                            setState(() => _assembly = value),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _reason,
                                  enabled: !locked,
                                  minLines: 3,
                                  maxLines: 5,
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    labelText: 'Reason',
                                    helperMaxLines: 3,
                                    helperText:
                                        '10–200 characters. Explain how you confirmed the locality.',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (_source.uncertain)
                                  const Text(
                                    'The change is unconfirmed or the report changed. Reload before trying again. Your reason has been retained.',
                                  ),
                                FilledButton(
                                  onPressed: locked || _change?.valid != true
                                      ? null
                                      : _save,
                                  child: Text(
                                    _source.writing
                                        ? 'Saving routing…'
                                        : 'Confirm routing area',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      TextButton(
                        onPressed: _source.writing || _confirming
                            ? null
                            : _reload,
                        child: const Text('Reload report'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}

class _AccessRequired extends StatelessWidget {
  const _AccessRequired();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Text(
      'Super Admin access required. Sign in with a verified Super Admin account.',
    ),
  );
}

class _RoutingCard extends StatelessWidget {
  const _RoutingCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    ),
  );
}

class _RoutingEvidence extends StatelessWidget {
  const _RoutingEvidence({required this.photos});
  final List<String> photos;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) => Semantics(
        button: true,
        label: 'Open evidence ${index + 1}',
        child: InkWell(
          onTap: () => EvidenceImageViewer.openGallery(
            context,
            photos.map(ApiClient.assetUrl).toList(),
            initialIndex: index,
          ),
          child: SizedBox(
            width: 96,
            child: Image.network(
              ApiClient.assetUrl(photos[index]),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(AppIcons.imageUnavailable),
            ),
          ),
        ),
      ),
    ),
  );
}
