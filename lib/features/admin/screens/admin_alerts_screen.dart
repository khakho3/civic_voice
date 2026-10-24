import 'dart:async';
import '../../../widgets/civic_filter_chip.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../../models/region.dart';
import '../../../widgets/busy_indicator.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/focused_search.dart';
import '../../../widgets/search_filter_list.dart';
import '../models/admin_overview.dart';
import '../services/admin_overview_directory.dart';
import '../services/admin_resource.dart';

typedef AlertPageFactory =
    AdminResource<AdminAlertPage> Function(
      String state,
      String query,
      String? cursor,
    );

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key, this.resourceFactory});
  final AlertPageFactory? resourceFactory;
  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  String _state = 'ACTIVE', _query = '';
  bool _changingView = false;
  final List<AdminAlert> _appended = [];
  final Set<String> _seenCursors = {};
  String? _appendedOwner, _nextCursor, _moreError;
  AdminResource<AdminAlertPage>? _more;
  bool _continued = false;
  late AdminResource<AdminAlertPage> _source;
  AdminAlertPage? _lastPage;
  String? _lastOwner;
  final _resultsKey = GlobalKey();
  double _resultHeight = 0;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    final state = _state, query = _query;
    const String? cursor = null;
    _source =
        widget.resourceFactory?.call(state, query, cursor) ??
        AdminResource<AdminAlertPage>(
          fetch: (token) => ApiClient.instance.adminAlerts(
            idToken: token,
            state: state,
            query: query,
            cursor: cursor,
          ),
          parse: AdminAlertPage.parse,
        );
    unawaited(_source.load());
  }

  void _change(VoidCallback change) {
    final current = _source.data;
    if (current != null) {
      _lastPage = AdminAlertPage(
        [
          ...current.alerts,
          if (_appendedOwner == _source.owner()) ..._appended,
        ],
        current.total,
        null,
      );
      _lastOwner = _source.owner();
    }
    _resultHeight = _resultsKey.currentContext?.size?.height ?? 0;
    setState(() {
      _more?.dispose();
      _more = null;
      _appended.clear();
      _seenCursors.clear();
      _appendedOwner = null;
      _nextCursor = null;
      _moreError = null;
      _continued = false;
      _source.dispose();
      _changingView = true;
      change();
      _create();
    });
  }

  Future<void> _reload() async {
    _change(() => _changingView = false);
  }

  Future<void> _loadMore() async {
    final page = _source.data, owner = _source.owner();
    final cursor = _continued ? _nextCursor : page?.nextCursor;
    if (_source.loading ||
        _more != null ||
        page == null ||
        owner == null ||
        cursor == null) {
      return;
    }
    if (_seenCursors.contains(cursor)) {
      setState(
        () => _moreError =
            'More alerts could not be verified. Refresh alerts to try again.',
      );
      return;
    }
    final state = _state, query = _query;
    final resource =
        widget.resourceFactory?.call(state, query, cursor) ??
        AdminResource<AdminAlertPage>(
          fetch: (token) => ApiClient.instance.adminAlerts(
            idToken: token,
            state: state,
            query: query,
            cursor: cursor,
          ),
          parse: AdminAlertPage.parse,
        );
    setState(() {
      _more = resource;
      _moreError = null;
    });
    await resource.load();
    if (!mounted || _more != resource) return;
    final next = resource.data;
    if (owner == _source.owner() &&
        owner == resource.owner() &&
        next != null &&
        next.nextCursor != cursor &&
        !_seenCursors.contains(next.nextCursor)) {
      setState(() {
        if (_appendedOwner != owner) _appended.clear();
        _appendedOwner = owner;
        final ids = {
          ...page.alerts.map((a) => a.id),
          ..._appended.map((a) => a.id),
        };
        for (final alert in next.alerts) {
          if (ids.add(alert.id)) _appended.add(alert);
        }
        _seenCursors.add(cursor);
        _nextCursor = next.nextCursor;
        _continued = true;
      });
    } else if (owner == _source.owner()) {
      setState(
        () => _moreError = 'More alerts could not be loaded. Please try again.',
      );
    }
    resource.dispose();
    if (mounted && _more == resource) setState(() => _more = null);
  }

  @override
  void dispose() {
    _more?.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _open(AdminAlert alert) async {
    if (_source.loading || _source.owner() == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminAlertReviewScreen(id: alert.id),
      ),
    );
    if (mounted) {
      unawaited(_reload());
      unawaited(AdminOverviewDirectory.instance.load());
    }
  }

  bool _matches(AdminAlert alert) {
    final state =
        _state == 'ALL' ||
        (_state == 'ACTIVE' && alert.state != 'RESOLVED') ||
        alert.state == _state;
    return state &&
        '${alert.title} ${alert.description} ${alert.actorName ?? ''} ${alert.actorPublicId ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alerts')),
    body: AnimatedBuilder(
      animation: _source,
      builder: (context, _) {
        final page = _source.data;
        final updating = _changingView && _source.loading;
        // These are matches from a previously verified page for this same owner,
        // never a cached total or an authoritative empty result for the new query.
        final preview = updating && _lastOwner == _source.owner();
        final alerts =
            (page == null
                ? null
                : [
                    ...page.alerts,
                    if (_appendedOwner == _source.owner()) ..._appended,
                  ]) ??
            (preview ? _lastPage?.alerts.where(_matches).toList() : null) ??
            <AdminAlert>[];
        final interactive =
            _source.owner() != null && (!_source.loading || _changingView);
        return SearchFilterList(
          header: SearchFilterHeader(
            screenKey: 'admin-alert-reviews',
            hintText: 'Search recorded alert events',
            query: _query,
            enabled: interactive,
            onQueryChanged: (value) => _change(() {
              _query = value.trim().substring(
                0,
                value.trim().length.clamp(0, 200),
              );
            }),
            results: (term) => [
              for (final alert in alerts)
                if ('${alert.title} ${alert.description}'
                    .toLowerCase()
                    .contains(term.toLowerCase()))
                  FocusedSearchResult(
                    title: alert.title,
                    subtitle: 'Current page · ${alert.state}',
                    onSelected: updating ? null : () => _open(alert),
                  ),
            ],
            filters: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in const {
                    'ACTIVE': 'Open and acknowledged',
                    'OPEN': 'Open',
                    'ACKNOWLEDGED': 'Acknowledged',
                    'RESOLVED': 'Resolved',
                    'ALL': 'All alerts',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: CivicFilterChip(
                        label: filter.value,
                        selected: _state == filter.key,
                        onTap: !interactive
                            ? null
                            : () {
                                if (_state == filter.key) return;
                                _change(() {
                                  _state = filter.key;
                                });
                              },
                      ),
                    ),
                ],
              ),
            ),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 320 &&
                  notification.metrics.pixels > 0 &&
                  notification is ScrollUpdateNotification &&
                  _moreError == null) {
                unawaited(_loadMore());
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Alert follow-up',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review alerts and record how they were handled. Acknowledged alerts stay open until resolved. Resolving an alert leaves the original event and report unchanged.',
                ),
                const SizedBox(height: 16),
                if (_source.loading && !updating)
                  const Center(
                    child: BusyIndicator(
                      semanticsLabel: 'Loading, please wait...',
                    ),
                  ),
                if (_source.error != null || page == null && !_source.loading)
                  Text(
                    _source.error ??
                        'A verified administrator session is required.',
                  ),
                ConstrainedBox(
                  key: _resultsKey,
                  constraints: BoxConstraints(
                    minHeight: preview ? _resultHeight : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 24,
                        child: updating
                            ? Semantics(
                                liveRegion: true,
                                child: const Text('Updating alerts…'),
                              )
                            : page != null
                            ? Text('${page.total} matching alerts')
                            : null,
                      ),
                      if (page != null && alerts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('No alerts match these filters.'),
                        ),
                      for (final alert in alerts)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: _AlertCard(
                            onTap: updating ? null : () => _open(alert),
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _ReviewBadge(state: alert.state),
                                  Text(
                                    _shortDate(alert.createdAt),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              Text(
                                alert.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                alert.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                alert.severity == 'CRITICAL'
                                    ? 'Critical'
                                    : 'Needs attention',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      if (_more != null && page != null)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text('Loading more alerts…'),
                        ),
                      if (_moreError != null && page != null)
                        TextButton(
                          onPressed: _more == null ? _loadMore : null,
                          child: Text(_moreError!),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _source.loading ? null : _reload,
                  child: const Text('Refresh alerts'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class AdminAlertReviewScreen extends StatefulWidget {
  const AdminAlertReviewScreen({
    super.key,
    required this.id,
    this.resource,
    this.save,
  });
  final String id;
  final AdminResource<AdminAlertDetail>? resource;
  final Future<Map<String, dynamic>> Function(
    String token,
    String action,
    int revision,
    String note,
  )?
  save;
  @override
  State<AdminAlertReviewScreen> createState() => _AdminAlertReviewScreenState();
}

class _AdminAlertReviewScreenState extends State<AdminAlertReviewScreen> {
  late final AdminResource<AdminAlertDetail> _source =
      widget.resource ??
      AdminResource<AdminAlertDetail>(
        fetch: (token) async {
          if (!adminId(widget.id)) throw StateError('Invalid alert');
          return ApiClient.instance.adminAlert(widget.id, idToken: token);
        },
        parse: (raw) {
          final detail = AdminAlertDetail.parse(raw);
          if (detail.alert.id != widget.id) {
            throw const FormatException('Wrong alert');
          }
          return detail;
        },
      );
  final _note = TextEditingController();
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    unawaited(_source.load());
  }

  @override
  void dispose() {
    _note.dispose();
    if (widget.resource == null) _source.dispose();
    super.dispose();
  }

  Future<void> _review(String action, String state) async {
    final alert = _source.data?.alert,
        note = _note.text.trim(),
        owner = _source.owner();
    if (alert == null ||
        _confirming ||
        _source.loading ||
        _source.writing ||
        _source.uncertain ||
        note.length < 10 ||
        note.length > 1000) {
      return;
    }
    setState(() => _confirming = true);
    try {
      final confirmed = await showConfirmDialog(
        context,
        title: '${_actionLabel(action)}?',
        message: note,
        confirmLabel: _actionLabel(action),
      );
      if (!confirmed || !mounted || _source.owner() != owner) return;
      final saved = await _source.mutate(
        (token, previous) async {
          if (previous.alert.id != alert.id ||
              previous.alert.revision != alert.revision) {
            throw StateError('Alert changed');
          }
          final response =
              await (widget.save?.call(token, action, alert.revision, note) ??
                  ApiClient.instance.reviewAdminAlert(
                    alert.id,
                    idToken: token,
                    action: action,
                    revision: alert.revision,
                    note: note,
                  ));
          final review = response['review'];
          if (review is! Map ||
              review['state'] != state ||
              review['revision'] != alert.revision + 1) {
            throw const FormatException('Unconfirmed review');
          }
          adminInstant(review['updatedAt']);
        },
        verify: (detail) =>
            detail.alert.id == alert.id &&
            detail.alert.state == state &&
            detail.alert.revision == alert.revision + 1,
      );
      if (saved && mounted && _source.owner() == owner) {
        _note.clear();
        unawaited(AdminOverviewDirectory.instance.load());
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alert review')),
    body: AnimatedBuilder(
      animation: _source,
      builder: (context, _) {
        final detail = _source.data, alert = detail?.alert;
        final locked =
            _source.loading ||
            _source.writing ||
            _source.uncertain ||
            _confirming;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_source.loading)
                const Center(
                  child: BusyIndicator(
                    semanticsLabel: 'Loading, please wait...',
                  ),
                ),
              if (_source.error != null || detail == null && !_source.loading)
                Semantics(
                  liveRegion: true,
                  child: Text(_source.error ?? 'This alert is unavailable.'),
                ),
              if (alert != null) ...[
                _AlertCard(
                  children: [
                    Text(
                      '${alert.severity} · ${_stateLabel(alert.state)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      alert.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(alert.description),
                    Text(
                      _fullDate(alert.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _geography(alert),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _OriginalAlertEvent(alert: alert),
                        ),
                      ),
                      child: const Text('View original audit event'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AlertCard(
                  children: [
                    Text(
                      'Alert follow-up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Record who is reviewing this alert and how it was handled. Resolving an alert leaves the original event and report unchanged.',
                    ),
                    TextField(
                      controller: _note,
                      enabled: !locked,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Follow-up note',
                        helperText:
                            '10–1000 characters. Describe the follow-up; do not include passwords or private credentials.',
                        helperMaxLines: 4,
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (alert.state == 'OPEN')
                          _action(
                            'Acknowledge',
                            'ACKNOWLEDGE',
                            'ACKNOWLEDGED',
                            locked,
                          ),
                        if (alert.state != 'RESOLVED')
                          _action(
                            'Resolve alert',
                            'RESOLVE',
                            'RESOLVED',
                            locked,
                          ),
                        if (alert.state != 'OPEN')
                          _action('Reopen alert', 'REOPEN', 'OPEN', locked),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AlertCard(
                  children: [
                    Text(
                      'Recorded follow-up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (detail!.actions.isEmpty)
                      const Text('No follow-up recorded yet.'),
                    for (final item in detail.actions) ...[
                      Text(
                        '${_stateLabel(item['state'])} · ${item['actorName']} (${item['actorPublicId']})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(item['note']),
                      Text(
                        _fullDate(adminInstant(item['createdAt'])),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (detail.actionCount > detail.actions.length)
                      Text(
                        'Showing the latest ${detail.actions.length} of ${detail.actionCount} follow-up records.',
                      ),
                  ],
                ),
              ],
              TextButton(
                onPressed: _source.loading || _source.writing || _confirming
                    ? null
                    : _source.load,
                child: const Text('Reload alert'),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _action(String label, String action, String state, bool locked) {
    final enabled =
        !locked &&
        _note.text.trim().length >= 10 &&
        _note.text.trim().length <= 1000;
    final child = BusyLabel(
      busy: _source.writing,
      busyLabel: 'Saving alert review',
      child: Text(label),
    );
    return action == 'RESOLVE'
        ? FilledButton(
            onPressed: enabled ? () => _review(action, state) : null,
            child: child,
          )
        : OutlinedButton(
            onPressed: enabled ? () => _review(action, state) : null,
            child: child,
          );
  }
}

String _stateLabel(String state) =>
    const {
      'OPEN': 'Open',
      'ACKNOWLEDGED': 'Acknowledged',
      'RESOLVED': 'Resolved',
    }[state] ??
    state;
String _actionLabel(String action) => const {
  'ACKNOWLEDGE': 'Acknowledge',
  'RESOLVE': 'Resolve alert',
  'REOPEN': 'Reopen alert',
}[action]!;
String _shortDate(DateTime value) {
  final d = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _fullDate(DateTime value) {
  final d = value.toLocal();
  final short = _shortDate(d).split(', ');
  return '${short.first} ${d.year}, ${short.last}:${d.second.toString().padLeft(2, '0')} ${d.timeZoneOffset == Duration.zero ? 'GMT' : d.timeZoneName}';
}

String _geography(AdminAlert alert) {
  final region =
      Region.values.where((r) => r.name == alert.region).firstOrNull?.label ??
      alert.region;
  return '${region ?? 'National/system'} · ${alert.assembly ?? 'No assembly recorded'}';
}

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge({required this.state});
  final String state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      _stateLabel(state),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.children, this.onTap});
  final List<Widget> children;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppSemanticColors.of(context).glassBorder),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}

/// Read-only original event snapshot already returned by the scoped alert API.
/// This does not replace the separately assigned generic Activity Detail screen.
class _OriginalAlertEvent extends StatelessWidget {
  const _OriginalAlertEvent({required this.alert});
  final AdminAlert alert;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Original audit event')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AlertCard(
          children: [
            Text(alert.title, style: Theme.of(context).textTheme.headlineSmall),
            Text(alert.description),
            Text(_fullDate(alert.createdAt)),
            Text(_geography(alert)),
            Text('Event ID: ${alert.id}'),
            Text('Severity: ${alert.severity}'),
            if (alert.action != null) Text('Action: ${alert.action}'),
            if (alert.actorName != null)
              Text(
                'Recorded actor: ${alert.actorName}${alert.actorPublicId == null ? '' : ' (${alert.actorPublicId})'}',
              ),
            if (alert.outcome != null) Text('Outcome: ${alert.outcome}'),
          ],
        ),
      ],
    ),
  );
}
