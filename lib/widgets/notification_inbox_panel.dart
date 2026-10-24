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
            const _InboxState(
              icon: AppIcons.warning,
              message: 'Could not load notifications. Please try again.',
            ),
            TextButton(
              onPressed: busy ? null : () => _inbox.refresh(reset: true),
              child: const Text('Refresh inbox'),
            ),
          ] else ...[
            if (page.rows.isNotEmpty)
              Text(
                '${page.unreadCount} unread',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            if (_inbox.writing || _opening)
              const BusyIndicator(
                semanticsLabel: 'Updating notifications, please wait...',
              ),
            if (page.rows.isNotEmpty)
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
              const _InboxState(message: 'No notifications yet.'),
            for (final item in page.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _InboxCard(
                  item: item,
                  blocked: blocked,
                  onOpen: () => _open(item),
                  onRead: () =>
                      _inbox.act([item.id], item.read ? 'unread' : 'read'),
                  onDismiss: () => _inbox.act([item.id], 'dismiss'),
                ),
              ),
            Wrap(
              children: [
                if (_inbox.canPrevious || _inbox.canNext)
                  TextButton(
                    onPressed: blocked || !_inbox.canPrevious
                        ? null
                        : _inbox.previous,
                    child: const Text('Previous page'),
                  ),
                if (_inbox.canPrevious || _inbox.canNext)
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

class _InboxState extends StatelessWidget {
  const _InboxState({
    required this.message,
    this.icon = AppIcons.notifications,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 280,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.blocked,
    required this.onOpen,
    required this.onRead,
    required this.onDismiss,
  });
  final InboxNotification item;
  final bool blocked;
  final VoidCallback onOpen, onRead, onDismiss;
  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context), theme = Theme.of(context);
    final date = item.createdAt.toLocal();
    return Card(
      key: ValueKey('notification-card-${item.id}'),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.read
              ? semantic.glassBorder
              : semantic.actionText.withValues(alpha: .4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '${item.read ? '' : 'Unread. '}${item.title}. ${item.body}',
            child: InkWell(
              onTap: blocked ? null : onOpen,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: semantic.actionFill.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.notifications,
                        color: semantic.actionText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!item.read)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.sm,
                                  ),
                                  child: Semantics(
                                    label: 'Unread',
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: semantic.actionFill,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            item.body,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
          Wrap(
            children: [
              TextButton(
                onPressed: blocked ? null : onRead,
                child: Text(item.read ? 'Mark unread' : 'Mark read'),
              ),
              TextButton(
                onPressed: blocked ? null : onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
