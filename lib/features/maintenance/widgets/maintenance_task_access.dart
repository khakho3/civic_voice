import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/detail_header.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';
import 'maintenance_assignment_notice.dart';

/// Rechecks membership before opening a task and removes mounted task content
/// as soon as its scope disappears. Also wraps the task's location route.
class MaintenanceTaskAccess extends StatefulWidget {
  const MaintenanceTaskAccess({
    super.key,
    required this.taskId,
    required this.builder,
    this.onBack,
    this.directory,
  });

  final String? taskId;
  final Widget Function(BuildContext, MaintenanceTask) builder;
  final VoidCallback? onBack;
  final MaintenanceTaskDirectory? directory;

  @override
  State<MaintenanceTaskAccess> createState() => _MaintenanceTaskAccessState();
}

class _MaintenanceTaskAccessState extends State<MaintenanceTaskAccess>
    with WidgetsBindingObserver {
  MaintenanceTaskDirectory get _directory =>
      widget.directory ?? MaintenanceTaskDirectory.instance;
  late bool _verifying = _directory.isLive;
  late bool _verified = !_directory.isLive;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_directory.isLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refresh());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _directory.isLive) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _refreshing = false;
  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    setState(() {
      _verifying = true;
      _failed = false;
    });
    try {
      await _directory.refresh();
      _verified = true;
    } catch (_) {
      _failed = true;
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      _directory.profile,
      _directory.tasks,
      _directory.loading,
      _directory.error,
    ]),
    builder: (context, _) {
      final task = _directory.taskById(widget.taskId ?? '');
      final loading = _verifying || _directory.loading.value;
      final failed = _failed || _directory.error.value != null;
      // Preserve the mounted form/draft through a same-scope refresh or a
      // temporary failure. Removal/reassignment still removes it immediately.
      if (_verified && task != null && _directory.canReadTask(task)) {
        return KeyedSubtree(
          key: ValueKey((_directory.scopeRevision, task.id)),
          child: widget.builder(context, task),
        );
      }
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: DetailHeader.topInset(context)),
                children: [
                  if (loading)
                    const GhanaLoadingIndicator(label: 'Verifying task access…')
                  else
                    AppStateMessage(
                      icon: failed ? AppIcons.warning : AppIcons.task,
                      title: failed
                          ? 'Unable to load task'
                          : _directory.unassigned
                          ? MaintenanceAssignmentNotice.title
                          : 'Task not found',
                      message: failed
                          ? 'The latest assigned work could not be loaded. Try again.'
                          : _directory.unassigned
                          ? MaintenanceAssignmentNotice.message
                          : 'This task is not available to your current team.',
                      primaryActionLabel: 'Retry',
                      onPrimaryAction: _refresh,
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: DetailHeader(title: 'Task', onBack: widget.onBack),
            ),
          ],
        ),
      );
    },
  );
}
