import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

enum _TaskStatus { inProgress, delayed, blocked }

/// MNT-004 — Update Task Progress.
class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({super.key});

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  AppScreenState _state = AppScreenState.success;

  _TaskStatus _selectedStatus = _TaskStatus.inProgress;
  final TextEditingController _notesController = TextEditingController();
  String? _validationError;
  bool _saved = false;

  static const int _minNotesLength = 10;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_notesController.text.trim().length < _minNotesLength) {
      setState(() {
        _validationError = 'Work notes must contain at least $_minNotesLength characters.';
        _saved = false;
      });
      return;
    }
    setState(() {
      _validationError = null;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.maybeOf(context)?.pop(),
        ),
        title: const Text('Update Task Progress'),
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(icon: Icon(AppIcons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (_) {},
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        // Not applicable to this screen per the approved states — treated as
        // success to avoid inventing an unspecified state.
        return _buildForm(context);
      case AppScreenState.error:
        return _ErrorView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.offline:
        return _OfflineView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.permission:
        return _PermissionView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.disabled:
        return _buildForm(context, disabled: true);
      case AppScreenState.success:
        return _buildForm(context);
    }
  }

  Widget _buildForm(BuildContext context, {bool disabled = false}) {
    return _UpdateProgressForm(
      disabled: disabled,
      selectedStatus: _selectedStatus,
      notesController: _notesController,
      validationError: _validationError,
      saved: _saved,
      onStatusChanged: disabled
          ? null
          : (status) => setState(() {
                _selectedStatus = status;
                _saved = false;
              }),
      onNotesChanged: disabled
          ? null
          : (_) {
              if (_saved || _validationError != null) {
                setState(() {
                  _saved = false;
                  _validationError = null;
                });
              }
            },
      onSave: disabled ? null : _handleSave,
      onDiscard: disabled
          ? null
          : () => setState(() {
                _notesController.clear();
                _validationError = null;
                _saved = false;
              }),
    );
  }
}

class _UpdateProgressForm extends StatelessWidget {
  const _UpdateProgressForm({
    required this.disabled,
    required this.selectedStatus,
    required this.notesController,
    required this.validationError,
    required this.saved,
    required this.onStatusChanged,
    required this.onNotesChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final bool disabled;
  final _TaskStatus selectedStatus;
  final TextEditingController notesController;
  final String? validationError;
  final bool saved;
  final ValueChanged<_TaskStatus>? onStatusChanged;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (saved) ...[
              _SavedBanner(semantic: semantic),
              const SizedBox(height: AppSpacing.md),
            ],
            Chip(label: const Text('Task ID: #CV-8842')),
            const SizedBox(height: AppSpacing.sm),
            Text('Street Light Repair - Sector 4', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Update the current status of the maintenance operation for central lighting grid.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Current Status', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              status: _TaskStatus.inProgress,
              label: 'In Progress',
              icon: AppIcons.statusInProgress,
              color: AppColors.statusInProgress,
              selected: selectedStatus == _TaskStatus.inProgress,
              onTap: onStatusChanged == null ? null : () => onStatusChanged!(_TaskStatus.inProgress),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              status: _TaskStatus.delayed,
              label: 'Delayed',
              icon: AppIcons.warning,
              color: semantic.warning,
              selected: selectedStatus == _TaskStatus.delayed,
              onTap: onStatusChanged == null ? null : () => onStatusChanged!(_TaskStatus.delayed),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              status: _TaskStatus.blocked,
              label: 'Blocked',
              icon: AppIcons.statusRejected,
              color: semantic.error,
              selected: selectedStatus == _TaskStatus.blocked,
              onTap: onStatusChanged == null ? null : () => onStatusChanged!(_TaskStatus.blocked),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Work Notes', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              onChanged: onNotesChanged,
              maxLines: 4,
              enabled: !disabled,
              decoration: InputDecoration(
                hintText: 'Describe current progress, encountered issues, or required parts...',
                errorText: validationError,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (validationError == null)
              Text(
                'Minimum 10 characters required',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: AppSpacing.lg),

            Text('Evidence / Photos', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _AddPhotoTile(disabled: disabled),
                const SizedBox(width: AppSpacing.sm),
                _PhotoThumbnail(),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onSave, child: const Text('Save Update')),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: onDiscard, child: const Text('Discard Draft')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.semantic});
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.success.withValues(alpha: 0.08),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: semantic.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.success, color: semantic.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress saved',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: semantic.success),
                ),
                Text(
                  'Your status update and work notes were saved to this assigned task.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final _TaskStatus status;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : colorScheme.surface,
      borderRadius: AppComponentRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppComponentRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: selected ? color : colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: AppIconSize.md),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
              Icon(
                selected ? AppIcons.statusResolved : Icons.circle_outlined,
                color: selected ? color : colorScheme.outlineVariant,
                size: AppIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.disabled});
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Icon(AppIcons.camera, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.card,
      ),
      child: Icon(AppIcons.imageUnavailable, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text('Loading update form', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Preparing status selector, notes, and evidence.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to save progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again without changing the maintenance workflow.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.error),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.offline, size: AppIconSize.xl, color: semantic.warning),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reconnect before saving progress.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.permissionDenied, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Permission required', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance access is required to update this assigned task.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}