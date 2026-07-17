import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

enum _TaskStatus { inProgress, completed, failed }

/// MNT-004 — Update Task Progress.
class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
    this.onNavigateToProfile,
    this.onOpenEvidence,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onOpenEvidence;

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  AppScreenState _state = AppScreenState.success;

  final ImagePicker _imagePicker = ImagePicker();
  _TaskStatus _selectedStatus = _TaskStatus.inProgress;
  final TextEditingController _notesController = TextEditingController();
  String? _validationError;
  String? _evidenceError;
  final List<XFile> _evidencePhotos = [];
  bool _cameraPermissionExplained = false;
  bool _saved = false;

  static const int _minNotesLength = 10;
  static const int _requiredEvidencePhotos = 3;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidencePhoto() async {
    if (_evidencePhotos.length >= _requiredEvidencePhotos) return;

    if (!_cameraPermissionExplained) {
      final allowed = await _confirmCameraUse();
      if (!mounted || !allowed) return;
      _cameraPermissionExplained = true;
    }

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (!mounted) return;
      if (photo == null) return;

      _addEvidencePhoto(photo);
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _evidenceError =
            'Camera is not available on this device for completion evidence.';
        _saved = false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _evidenceError =
            'Camera permission is required to capture completion evidence.';
        _saved = false;
      });
    }
  }

  Future<bool> _confirmCameraUse() async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow camera access?'),
        content: const Text(
          'Civic Voice will open your phone camera so you can capture real-time completion evidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow Camera'),
          ),
        ],
      ),
    );
    return allowed ?? false;
  }

  void _addEvidencePhoto(XFile photo) {
    setState(() {
      _evidencePhotos.add(photo);
      _evidenceError = null;
      _saved = false;
    });
  }

  void _handleSave() {
    final notes = _notesController.text.trim();
    if (_selectedStatus == _TaskStatus.failed &&
        notes.length < _minNotesLength) {
      setState(() {
        _validationError = 'Failure note must explain why the task failed.';
        _evidenceError = null;
        _saved = false;
      });
      return;
    }

    if (_selectedStatus == _TaskStatus.completed &&
        _evidencePhotos.length < _requiredEvidencePhotos) {
      setState(() {
        _validationError = null;
        _evidenceError =
            'Attach $_requiredEvidencePhotos photos to mark this completed.';
        _saved = false;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _evidenceError = null;
      _saved = true;
    });
    if (_selectedStatus == _TaskStatus.completed) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          widget.onOpenEvidence?.call();
        }
      });
    }
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
          NavigationDestination(
            icon: Icon(AppIcons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onNavigateToDashboard?.call();
          } else if (index == 1) {
            widget.onNavigateToTasks?.call();
          } else if (index == 2) {
            widget.onNavigateToProfile?.call();
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _buildForm(context);
      case AppScreenState.error:
        return _ErrorView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.offline:
        return _OfflineView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.permission:
        return _PermissionView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
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
              _validationError = null;
              _evidenceError = null;
              _saved = false;
            }),
      onNotesChanged: disabled
          ? null
          : (_) {
              if (_saved || _validationError != null) {
                setState(() {
                  _saved = false;
                  _validationError = null;
                  _evidenceError = null;
                });
              }
            },
      evidencePhotos: _evidencePhotos,
      requiredEvidencePhotos: _requiredEvidencePhotos,
      evidenceError: _evidenceError,
      onAttachEvidence: disabled ? null : _captureEvidencePhoto,
      onSave: disabled ? null : _handleSave,
      onDiscard: disabled
          ? null
          : () => setState(() {
              _notesController.clear();
              _validationError = null;
              _evidenceError = null;
              _evidencePhotos.clear();
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
    required this.evidencePhotos,
    required this.requiredEvidencePhotos,
    required this.evidenceError,
    required this.saved,
    required this.onStatusChanged,
    required this.onNotesChanged,
    required this.onAttachEvidence,
    required this.onSave,
    required this.onDiscard,
  });

  final bool disabled;
  final _TaskStatus selectedStatus;
  final TextEditingController notesController;
  final String? validationError;
  final List<XFile> evidencePhotos;
  final int requiredEvidencePhotos;
  final String? evidenceError;
  final bool saved;
  final ValueChanged<_TaskStatus>? onStatusChanged;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback? onAttachEvidence;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final evidencePhotoCount = evidencePhotos.length;

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
            Text(
              'Street Light Repair - Sector 4',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Update the current status of the maintenance operation for central lighting grid.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(_TaskStatus.inProgress),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              status: _TaskStatus.completed,
              label: 'Completed',
              icon: AppIcons.statusResolved,
              color: semantic.success,
              selected: selectedStatus == _TaskStatus.completed,
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(_TaskStatus.completed),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              status: _TaskStatus.failed,
              label: 'Failed',
              icon: AppIcons.statusRejected,
              color: semantic.error,
              selected: selectedStatus == _TaskStatus.failed,
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(_TaskStatus.failed),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              selectedStatus == _TaskStatus.failed
                  ? 'Failure Note'
                  : 'Work Notes',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              onChanged: onNotesChanged,
              maxLines: 4,
              enabled: !disabled,
              decoration: InputDecoration(
                hintText: selectedStatus == _TaskStatus.failed
                    ? 'Explain why the task failed and what is needed next...'
                    : 'Describe current progress, encountered issues, or required parts...',
                errorText: validationError,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (validationError == null && selectedStatus == _TaskStatus.failed)
              Text(
                'Required for failed tasks',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (selectedStatus == _TaskStatus.completed) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Completion Photo Evidence', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$evidencePhotoCount of $requiredEvidencePhotos photos attached',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var index = 0; index < requiredEvidencePhotos; index++)
                    _EvidencePhotoSlot(
                      index: index,
                      photo: index < evidencePhotos.length
                          ? evidencePhotos[index]
                          : null,
                      disabled:
                          disabled ||
                          index > evidencePhotoCount ||
                          evidencePhotoCount >= requiredEvidencePhotos,
                      onTap: index == evidencePhotoCount
                          ? onAttachEvidence
                          : null,
                    ),
                ],
              ),
              if (evidenceError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  evidenceError!,
                  style: textTheme.bodySmall?.copyWith(color: semantic.error),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save Update'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onDiscard,
                child: const Text('Discard Draft'),
              ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: semantic.success),
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
            border: Border.all(
              color: selected ? color : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: AppIconSize.md),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
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

class _EvidencePhotoSlot extends StatelessWidget {
  const _EvidencePhotoSlot({
    required this.index,
    required this.photo,
    required this.disabled,
    required this.onTap,
  });

  final int index;
  final XFile? photo;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final attached = photo != null;
    final accent = attached ? semantic.success : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppComponentRadius.card,
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: 96,
        height: 88,
        decoration: BoxDecoration(
          color: attached
              ? semantic.success.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerLow,
          borderRadius: AppComponentRadius.card,
          border: Border.all(
            color: attached
                ? semantic.success.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
        child: attached
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(photo!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _EvidenceSlotLabel(
                          icon: AppIcons.success,
                          label: 'Photo ${index + 1}',
                          color: accent,
                        ),
                  ),
                  Positioned(
                    right: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: semantic.success,
                        borderRadius: AppRadius.allXs,
                      ),
                      child: Icon(
                        AppIcons.success,
                        size: AppIconSize.sm,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              )
            : _EvidenceSlotLabel(
                icon: AppIcons.camera,
                label: 'Add ${index + 1}',
                color: accent,
              ),
      ),
    );
  }
}

class _EvidenceSlotLabel extends StatelessWidget {
  const _EvidenceSlotLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
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
          Text(
            'Loading update form',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
            Text(
              'Unable to save progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: semantic.warning,
            ),
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
            Icon(
              AppIcons.permissionDenied,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance access is required to update this assigned task.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
