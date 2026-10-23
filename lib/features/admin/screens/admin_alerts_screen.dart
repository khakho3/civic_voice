import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
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
  List<String?> _cursors = [null];
  late AdminResource<AdminAlertPage> _source;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    final state = _state, query = _query, cursor = _cursors.last;
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
    setState(() {
      _source.dispose();
      change();
      _create();
    });
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  Future<void> _open(AdminAlert alert) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminAlertReviewScreen(id: alert.id),
      ),
    );
    if (mounted) {
      unawaited(_source.load());
      unawaited(AdminOverviewDirectory.instance.load());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alert reviews')),
    body: AnimatedBuilder(
      animation: _source,
      builder: (context, _) {
        final page = _source.data;
        return SearchFilterList(
          header: SearchFilterHeader(
            screenKey: 'admin-alert-reviews',
            hintText: 'Search alert reviews',
            query: _query,
            enabled: !_source.loading,
            onQueryChanged: (value) => _change(() {
              _query = value.trim().substring(
                0,
                value.trim().length.clamp(0, 200),
              );
              _cursors = [null];
            }),
            results: (term) => [
              for (final alert in page?.alerts ?? <AdminAlert>[])
                if ('${alert.title} ${alert.description}'
                    .toLowerCase()
                    .contains(term.toLowerCase()))
                  FocusedSearchResult(
                    title: alert.title,
                    subtitle: 'Current page · ${alert.state}',
                    onSelected: () => _open(alert),
                  ),
            ],
            filters: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in const {
                    'ACTIVE': 'Active',
                    'OPEN': 'Open',
                    'ACKNOWLEDGED': 'Acknowledged',
                    'RESOLVED': 'Resolved',
                    'ALL': 'All',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter.value),
                        selected: _state == filter.key,
                        onSelected: _source.loading
                            ? null
                            : (_) => _change(() {
                                _state = filter.key;
                                _cursors = [null];
                              }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Actionable system and security events. Routine password changes remain in Activity.',
              ),
              if (_source.loading)
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
              if (page != null) ...[
                Text('${page.total} matching alerts'),
                if (page.alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('No alerts match these filters.'),
                  ),
                for (final alert in page.alerts)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: ListTile(
                      title: Text(alert.title),
                      subtitle: Text(
                        '${alert.state.replaceAll('_', ' ')} · ${alert.severity}\n${alert.createdAt.toLocal()}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(alert),
                    ),
                  ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: _source.loading || _cursors.length < 2
                          ? null
                          : () => _change(() {
                              _cursors = _cursors.sublist(
                                0,
                                _cursors.length - 1,
                              );
                            }),
                      child: const Text('Previous page'),
                    ),
                    TextButton(
                      onPressed:
                          _source.loading ||
                              page.nextCursor == null ||
                              _cursors.contains(page.nextCursor)
                          ? null
                          : () => _change(() {
                              _cursors = [..._cursors, page.nextCursor];
                            }),
                      child: const Text('Next page'),
                    ),
                  ],
                ),
              ],
              TextButton(
                onPressed: _source.loading ? null : _source.load,
                child: const Text('Refresh alerts'),
              ),
            ],
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
        title: 'Confirm alert review?',
        message: '${alert.title}\nMark as ${state.toLowerCase()}.\n$note',
        confirmLabel: 'Save review',
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
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (_source.loading)
              const Center(
                child: BusyIndicator(semanticsLabel: 'Loading, please wait...'),
              ),
            if (_source.error != null || detail == null && !_source.loading)
              Semantics(
                liveRegion: true,
                child: Text(_source.error ?? 'This alert is unavailable.'),
              ),
            if (alert != null) ...[
              Text(
                alert.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${alert.severity} · ${alert.state.replaceAll('_', ' ')}'),
              Text(alert.description),
              Text('Recorded ${alert.createdAt.toLocal()}'),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _note,
                enabled: !locked,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Review note',
                  helperText: 'Explain this review in 10–1000 characters.',
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (alert.state == 'OPEN')
                    _action(
                      'Acknowledge',
                      'ACKNOWLEDGE',
                      'ACKNOWLEDGED',
                      locked,
                    ),
                  if (alert.state != 'RESOLVED')
                    _action('Resolve', 'RESOLVE', 'RESOLVED', locked),
                  if (alert.state == 'RESOLVED')
                    _action('Reopen', 'REOPEN', 'OPEN', locked),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Review history (${detail!.actionCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (detail.actions.isEmpty)
                const Text('No review actions recorded.'),
              for (final item in detail.actions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item['state']} · ${item['actorName']}'),
                  subtitle: Text(
                    '${item['note']}\n${adminInstant(item['createdAt']).toLocal()}',
                  ),
                ),
              if (detail.actionCount > detail.actions.length)
                const Text('Showing the latest 20 review actions.'),
            ],
            TextButton(
              onPressed: _source.loading || _source.writing || _confirming
                  ? null
                  : _source.load,
              child: const Text('Reload alert'),
            ),
          ],
        );
      },
    ),
  );
  Widget _action(String label, String action, String state, bool locked) =>
      FilledButton(
        onPressed: locked || _note.text.trim().length < 10
            ? null
            : () => _review(action, state),
        child: BusyLabel(
          busy: _source.writing,
          busyLabel: 'Saving alert review',
          child: Text(label),
        ),
      );
}
