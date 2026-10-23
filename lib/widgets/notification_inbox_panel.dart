import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/app_role.dart';
import '../models/notification_inbox.dart';
import '../services/notification_inbox_directory.dart';
import '../services/notification_navigation.dart';
import 'notification_list_view.dart' show NotificationDeviceSettings;
import 'busy_indicator.dart';
import 'confirm_dialog.dart';

/// All five live roles use the same verified inbox, independent of push permission.
class NotificationInboxPanel extends StatefulWidget {
  const NotificationInboxPanel({
    super.key,
    required this.role,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.directory,
    this.navigate,
  });
  final AppRole role;
  final EdgeInsets padding;
  final NotificationInboxDirectory? directory;
  final Future<void> Function(InboxNotification)? navigate;
  @override
  State<NotificationInboxPanel> createState() => _NotificationInboxPanelState();
}

class _NotificationInboxPanelState extends State<NotificationInboxPanel>
    with WidgetsBindingObserver {
  NotificationInboxDirectory get _inbox =>
      widget.directory ?? NotificationInboxDirectory.instance;
  bool _opening = false, _confirming = false;
  String? _navigationError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_inbox.refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_inbox.writing && !_opening) {
      unawaited(_inbox.refresh());
    }
  }

  Future<void> _open(InboxNotification item) async {
    if (_opening || _inbox.writing) return;
    final owner = _inbox.owner()?.key;
    setState(() {
      _opening = true;
      _navigationError = null;
    });
    try {
      if (!await _inbox.act([item.id], 'read')) {
        throw StateError('Unconfirmed notification');
      }
      if (!mounted || owner != _inbox.owner()?.key) return;
      if (widget.navigate != null) {
        await widget.navigate!(item);
        return;
      }
      final destination = await resolveInboxNotification(item, widget.role);
      if (!mounted || owner != _inbox.owner()?.key) return;
      unawaited(
        Navigator.of(
          context,
        ).pushNamed(destination.route, arguments: destination.arguments),
      );
    } catch (_) {
      if (mounted && owner == _inbox.owner()?.key) {
        setState(
          () => _navigationError =
              'This update could not be opened. Refresh your inbox and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _clear(List<String> ids) async {
    if (_confirming || _opening || _inbox.writing) return;
    final owner = _inbox.owner()?.key;
    setState(() => _confirming = true);
    try {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Clear these notifications?',
        message:
            'This clears only the messages shown on this page. New and other-page updates are kept.',
        confirmLabel: 'Clear',
        destructive: true,
      );
      if (confirmed && mounted && owner == _inbox.owner()?.key) {
        await _inbox.act(ids, 'dismiss');
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _inbox,
    builder: (context, _) {
      final roleAllowed = _inbox.owner()?.role == widget.role;
      final page = roleAllowed ? _inbox.page : null;
      final busy = _inbox.writing || _opening || _confirming;
      final blocked = busy || _inbox.uncertain;
      final ready =
          roleAllowed && _inbox.status == InboxStatus.ready && page != null;
      return ListView(
        padding: widget.padding,
        children: [
          const NotificationDeviceSettings(),
          if (roleAllowed &&
              (_inbox.status == InboxStatus.loading ||
                  _inbox.status == InboxStatus.idle))
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: BusyIndicator(
                  semanticsLabel: 'Loading notifications, please wait...',
                ),
              ),
            )
          else if (!ready) ...[
            const Text(
              'Your inbox could not be verified. No sample messages are shown.',
            ),
            TextButton(
              onPressed: busy ? null : () => _inbox.refresh(reset: true),
              child: const Text('Refresh inbox'),
            ),
          ] else ...[
            Text('${page.unreadCount} unread across your current inbox'),
            if (_inbox.writing || _opening)
              const BusyIndicator(
                semanticsLabel: 'Updating notifications, please wait...',
              ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: blocked || page.rows.isEmpty
                      ? null
                      : () => _inbox.act(
                          page.rows.map((row) => row.id).toList(),
                          'read',
                        ),
                  child: const Text('Mark this page read'),
                ),
                TextButton(
                  onPressed: blocked || page.rows.isEmpty
                      ? null
                      : () => _clear(page.rows.map((row) => row.id).toList()),
                  child: const Text('Clear this page'),
                ),
              ],
            ),
            if (_inbox.error != null)
              Semantics(liveRegion: true, child: Text(_inbox.error!)),
            if (_navigationError != null)
              Semantics(liveRegion: true, child: Text(_navigationError!)),
            if (page.rows.isEmpty)
              const Text(
                'No notifications on this page. New updates will appear here.',
              ),
            for (final item in page.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppComponentRadius.card,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          button: true,
                          label:
                              '${item.read ? '' : 'Unread. '}${item.title}. ${item.body}',
                          child: InkWell(
                            onTap: blocked ? null : () => _open(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(item.body),
                                  Text(
                                    item.createdAt
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: blocked
                                  ? null
                                  : () => _inbox.act([
                                      item.id,
                                    ], item.read ? 'unread' : 'read'),
                              child: Text(
                                item.read ? 'Mark unread' : 'Mark read',
                              ),
                            ),
                            TextButton(
                              onPressed: blocked
                                  ? null
                                  : () => _inbox.act([item.id], 'dismiss'),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Wrap(
              children: [
                TextButton(
                  onPressed: blocked || !_inbox.canPrevious
                      ? null
                      : _inbox.previous,
                  child: const Text('Previous page'),
                ),
                TextButton(
                  onPressed: blocked || !_inbox.canNext ? null : _inbox.next,
                  child: const Text('Next page'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => _navigationError = null);
                          unawaited(_inbox.refresh());
                        },
                  child: const Text('Refresh inbox'),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
