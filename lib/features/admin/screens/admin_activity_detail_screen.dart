import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/form_section_card.dart';
import '../models/admin_audit.dart';
import '../services/admin_activity_repository.dart';
import '../services/admin_read_failure.dart';
import '../services/admin_resource.dart';

class AuditDetailArguments {
  const AuditDetailArguments(this.id);
  final String id;
}

class AdminActivityDetailScreen extends StatefulWidget {
  const AdminActivityDetailScreen({
    super.key,
    required this.id,
    this.repository,
    this.fromActivity = false,
  });
  static const routeName = '/admin/activity-detail';
  static const activityRouteName = '/admin/system-activity';
  final String id;
  final AdminActivityRepository? repository;
  final bool fromActivity;

  static AdminActivityDetailScreen fromSettings(RouteSettings? settings) {
    final args = settings?.arguments;
    final uri = Uri.tryParse(settings?.name ?? '');
    return AdminActivityDetailScreen(
      id: args is AuditDetailArguments
          ? args.id
          : uri?.queryParameters['eventId'] ?? '',
      fromActivity: args is AuditDetailArguments,
    );
  }

  @override
  State<AdminActivityDetailScreen> createState() =>
      _AdminActivityDetailScreenState();
}

class _AdminActivityDetailScreenState extends State<AdminActivityDetailScreen> {
  late final _repo = widget.repository ?? AdminActivityRepository();
  late final _initialOwner = _repo.owner();
  late final AdminResource<AuditDetail> _source = _repo.detail(widget.id);
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    unawaited(_source.load());
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _back() {
    if (_leaving) return;
    _leaving = true;
    final navigator = Navigator.of(context);
    if (widget.fromActivity && navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(
        AdminActivityDetailScreen.activityRouteName,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.fromActivity && Navigator.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Audit Event'),
        leading: IconButton(
          tooltip: 'Back to Activity',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _source,
          AdminActivityRepository.sessionChanges,
        ]),
        builder: (context, _) {
          if (_repo.owner() == null ||
              _repo.owner() != _initialOwner ||
              _source.failure == AdminReadFailure.unauthorized) {
            return const _DetailState(
              title: 'Administrative access required',
              message:
                  'Sign in with an active administrator account to view audit activity.',
            );
          }
          if (_source.loading) {
            return const GhanaLoadingIndicator(label: 'Loading audit event');
          }
          if (_source.error != null) {
            return _DetailState(
              title: adminServiceOffline(_source.failure)
                  ? 'Cannot reach CivicVoice'
                  : 'Unable to load event',
              message:
                  'This audit event could not be verified. Try loading it again.',
              onRetry: _source.load,
            );
          }
          final event = _source.data?.event;
          if (event == null) {
            return const _DetailState(
              title: 'Event not found',
              message:
                  'This event is unavailable or outside your administrative scope.',
            );
          }
          return ListView(
            key: const PageStorageKey('audit-event-detail'),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                event.item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(auditTimestamp(event.item.timestamp)),
              const SizedBox(height: AppSpacing.sm),
              Text(event.item.description),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(event.item.severity.label),
                  Text(auditCategories[event.category]!),
                ],
              ),
              _Fields(
                title: 'Event record',
                fields: {
                  'Event ID': event.id,
                  'Action': event.action.replaceAll('_', ' '),
                  'Outcome': event.outcome,
                  'Recorded at (UTC)': event.item.timestamp
                      .toUtc()
                      .toIso8601String(),
                },
              ),
              if (event.outcome == 'UNKNOWN')
                const Text(
                  'The outcome was not established. This record does not prove the action succeeded.',
                ),
              _Fields(
                title: 'Actor and scope',
                fields: {
                  'Actor': event.fields['actorName'],
                  'Actor ID':
                      event.fields['actorPublicId'] ?? event.fields['actorId'],
                  'Role at the time': event.fields['actorRole'],
                  'Region': event.fields['region'],
                  'Assembly': event.fields['assembly'],
                },
              ),
              const Text(
                'Actor details are recorded snapshots. A missing actor ID may mean the account was removed or no actor was established.',
              ),
              _Fields(
                title: 'Target',
                fields: {
                  'Type': event.fields['subjectType'],
                  'Reference': event.fields['subjectId'],
                },
              ),
              const Text(
                'The target reference is a historical record; its current availability has not been checked.',
              ),
              if (event.context.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No additional safe context was recorded for this event.',
                  ),
                )
              else
                _Fields(
                  title: 'Recorded context',
                  fields: {
                    for (final entry in event.context.entries)
                      _contextLabel(entry.key): _contextValue(
                        entry.key,
                        entry.value,
                      ),
                  },
                ),
              if (event.context.keys.any(
                (key) => key.startsWith('previousObserved'),
              ))
                const Text(
                  'Earlier values reflect what the server read before this change; another update may have happened before it was saved. Selected fields may be unchanged.',
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    ),
  );
}

String _contextLabel(String key) {
  const labels = {
    'active': 'Now active',
    'previousObservedActive': 'Previously observed active',
    'role': 'New role',
    'status': 'New status',
    'auditLogging': 'New audit collection',
    'previousAuditLogging': 'Previous audit collection',
    'authenticatedAt': 'Verified authentication time',
  };
  if (labels.containsKey(key)) return labels[key]!;
  final spaced = key.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => ' ${match[0]!.toLowerCase()}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String? _contextValue(String key, Object? value) {
  if (value == null) return null;
  if (value is bool) return value ? 'Yes' : 'No';
  if ([
    'authenticatedAt',
    'observedAt',
    'failedSince',
    'from',
    'to',
  ].contains(key)) {
    final text = value.toString();
    final time = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)
        ? DateTime.tryParse(text)
        : null;
    return time == null ? 'Not recorded' : auditTimestamp(time);
  }
  return value.toString().replaceAll('_', ' ');
}

class _Fields extends StatelessWidget {
  const _Fields({required this.title, required this.fields});
  final String title;
  final Map<String, String?> fields;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: FormSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in fields.entries)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.key,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    (field.value?.trim().isNotEmpty ?? false)
                        ? _wrap(field.value!)
                        : 'Not recorded',
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

// Break opportunities preserve long public IDs/names without horizontal overflow.
String _wrap(String value) =>
    value.replaceAllMapped(RegExp(r'\S{24}'), (m) => '${m[0]}\u200b');

class _DetailState extends StatelessWidget {
  const _DetailState({
    required this.title,
    required this.message,
    this.onRetry,
  });
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: AppStateMessage(
      icon: AppIcons.warning,
      badgeColor: AppColors.error,
      title: title,
      message: message,
      primaryActionLabel: onRetry == null ? null : 'Retry',
      onPrimaryAction: onRetry,
    ),
  );
}
