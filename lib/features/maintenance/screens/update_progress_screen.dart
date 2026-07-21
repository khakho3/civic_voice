import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/glass_dialog_backdrop.dart';
import '../../admin/services/admin_user_directory.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';

/// MNT-004 — Update Task Progress.
///
/// Marking a task Completed here *is* the completion submission — the
/// required 3 evidence photos + work notes captured on this screen, via a
/// real `image_picker` camera call, are what gets saved. There is no
/// separate "Upload Evidence" step after this one anymore: that screen
/// asked for photos a second time with Camera/Gallery buttons that only
/// simulated a progress bar (no real capture), plus a second, duplicate
/// notes field — pure friction with nothing behind it, removed rather than
/// wired up twice.
class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({
    super.key,
    required this.task,
    this.onBack,
    this.onTaskCompleted,
  });

  final MaintenanceTask task;
  final VoidCallback? onBack;

  /// Fired once a Completed save is written to
  /// [MaintenanceTaskDirectory] — the caller re-reads the task by id so it
  /// always shows the just-saved record, not a stale copy from before this
  /// screen opened.
  final ValueChanged<String>? onTaskCompleted;

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late MaintenanceTaskStatus _selectedStatus =
      widget.task.status == MaintenanceTaskStatus.assigned
      ? MaintenanceTaskStatus.inProgress
      : widget.task.status;
  final TextEditingController _notesController = TextEditingController();
  String? _validationError;
  String? _evidenceError;
  final List<XFile> _evidencePhotos = [];
  bool _cameraPermissionExplained = false;
  bool _saved = false;
  bool _submitting = false;

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
      builder: (context) => GlassDialogBackdrop(
        child: AlertDialog(
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

  Future<void> _handleSave() async {
    final notes = _notesController.text.trim();
    if (_selectedStatus == MaintenanceTaskStatus.completed &&
        notes.length < _minNotesLength) {
      setState(() {
        _validationError =
            'Completion notes are required. Describe the work completed in at least $_minNotesLength characters.';
        _evidenceError = null;
        _saved = false;
      });
      return;
    }
    if (_selectedStatus == MaintenanceTaskStatus.failed &&
        notes.length < _minNotesLength) {
      setState(() {
        _validationError = 'Failure note must explain why the task failed.';
        _evidenceError = null;
        _saved = false;
      });
      return;
    }

    if (_selectedStatus == MaintenanceTaskStatus.completed &&
        !MaintenanceTaskDirectory.instance.canSubmitEvidence(widget.task)) {
      setState(() {
        _validationError = null;
        _evidenceError = _leadOnlyMessage(context);
        _saved = false;
      });
      return;
    }

    if (_selectedStatus == MaintenanceTaskStatus.completed &&
        _evidencePhotos.length < _requiredEvidencePhotos) {
      setState(() {
        _validationError = null;
        _evidenceError =
            'Attach $_requiredEvidencePhotos photos to mark this completed.';
        _saved = false;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      await MaintenanceTaskDirectory.instance.updateTaskOnServer(
        widget.task,
        status: _selectedStatus,
        notes: notes,
        evidencePhotoPaths: _evidencePhotos.map((photo) => photo.path).toList(),
      );
      if (!mounted) return;
      setState(() {
        _validationError = null;
        _evidenceError = null;
        _saved = true;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Could not save this update. Please try again.';
        _saved = false;
        _submitting = false;
      });
      return;
    }
    if (_selectedStatus == MaintenanceTaskStatus.completed) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) widget.onTaskCompleted?.call(widget.task.id);
      });
    }
  }

  /// The team's lead-only gate exists so a task doesn't get marked
  /// Completed twice over by different members submitting separately —
  /// see [MaintenanceTaskDirectory.canSubmitEvidence] for the full rule
  /// (falls back to "anyone" once no lead is set).
  String _leadOnlyMessage(BuildContext context) {
    final team = MaintenanceTaskDirectory.instance.teamForTask(widget.task);
    final leadName = team?.leadUserId == null
        ? null
        : AdminUserDirectory.instance.userById(team!.leadUserId!)?.name;
    return leadName == null
        ? 'Only your team lead can submit completion evidence for this task.'
        : 'Only $leadName can submit completion evidence for this task.';
  }

  Future<void> _handleDiscard() async {
    final hasContent =
        _notesController.text.trim().isNotEmpty || _evidencePhotos.isNotEmpty;
    if (hasContent) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard draft?',
        message:
            'Your work notes and any captured evidence photos for this '
            'update will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
    setState(() {
      _notesController.clear();
      _validationError = null;
      _evidenceError = null;
      _evidencePhotos.clear();
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final readOnly =
        task.status == MaintenanceTaskStatus.completed ||
        task.status == MaintenanceTaskStatus.failed;
    final canSubmitEvidence = MaintenanceTaskDirectory.instance
        .canSubmitEvidence(task);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _UpdateProgressForm(
              task: task,
              disabled: readOnly,
              selectedStatus: _selectedStatus,
              notesController: _notesController,
              validationError: _validationError,
              saved: _saved,
              submitting: _submitting,
              canSubmitEvidence: canSubmitEvidence,
              leadOnlyMessage: _leadOnlyMessage(context),
              onStatusChanged: readOnly
                  ? null
                  : (status) => setState(() {
                      _selectedStatus = status;
                      _validationError = null;
                      _evidenceError = null;
                      _saved = false;
                    }),
              onNotesChanged: readOnly
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
              onAttachEvidence: readOnly || !canSubmitEvidence
                  ? null
                  : _captureEvidencePhoto,
              onSave: readOnly ? null : _handleSave,
              onDiscard: readOnly ? null : _handleDiscard,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Update Progress',
              onBack: widget.onBack,
              trailing: Chip(label: Text('#${task.id}')),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressForm extends StatelessWidget {
  const _UpdateProgressForm({
    required this.task,
    required this.disabled,
    required this.selectedStatus,
    required this.notesController,
    required this.validationError,
    required this.evidencePhotos,
    required this.requiredEvidencePhotos,
    required this.evidenceError,
    required this.saved,
    required this.submitting,
    required this.canSubmitEvidence,
    required this.leadOnlyMessage,
    required this.onStatusChanged,
    required this.onNotesChanged,
    required this.onAttachEvidence,
    required this.onSave,
    required this.onDiscard,
  });

  final MaintenanceTask task;
  final bool disabled;

  /// Whether the signed-in technician may submit completion evidence for
  /// this task at all — false when the team has a lead and it isn't them.
  final bool canSubmitEvidence;

  /// Explains [canSubmitEvidence] being false, shown in place of the photo
  /// capture grid rather than a silently-disabled one.
  final String leadOnlyMessage;
  final MaintenanceTaskStatus selectedStatus;
  final TextEditingController notesController;
  final String? validationError;
  final List<XFile> evidencePhotos;
  final int requiredEvidencePhotos;
  final String? evidenceError;
  final bool saved;
  final bool submitting;
  final ValueChanged<MaintenanceTaskStatus>? onStatusChanged;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback? onAttachEvidence;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final evidencePhotoCount = evidencePhotos.length;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            DetailHeader.topInset(context) + AppSpacing.md,
            AppSpacing.md,
            bottomInset + AppSpacing.xl,
          ),
          children: [
            if (saved) ...[
              _SavedBanner(semantic: semantic),
              const SizedBox(height: AppSpacing.md),
            ],
            Chip(label: Text('Task ID: #${task.id}')),
            const SizedBox(height: AppSpacing.sm),
            Text(task.title, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              task.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Current Status', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: 'In Progress',
              icon: AppIcons.activityPulse,
              color: AppColors.statusInProgress,
              selected: selectedStatus == MaintenanceTaskStatus.inProgress,
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(MaintenanceTaskStatus.inProgress),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: 'Completed',
              icon: AppIcons.statusResolved,
              color: semantic.success,
              selected: selectedStatus == MaintenanceTaskStatus.completed,
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(MaintenanceTaskStatus.completed),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: 'Failed',
              icon: AppIcons.statusRejected,
              color: semantic.error,
              selected: selectedStatus == MaintenanceTaskStatus.failed,
              onTap: onStatusChanged == null
                  ? null
                  : () => onStatusChanged!(MaintenanceTaskStatus.failed),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              selectedStatus == MaintenanceTaskStatus.failed
                  ? 'Failure Note'
                  : selectedStatus == MaintenanceTaskStatus.completed
                  ? 'Completion Notes'
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
                hintText: selectedStatus == MaintenanceTaskStatus.failed
                    ? 'Explain why the task failed and what is needed next...'
                    : selectedStatus == MaintenanceTaskStatus.completed
                    ? 'Describe the work completed and the final outcome...'
                    : 'Describe current progress, encountered issues, or required parts...',
                errorText: validationError,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (validationError == null &&
                (selectedStatus == MaintenanceTaskStatus.failed ||
                    selectedStatus == MaintenanceTaskStatus.completed))
              Text(
                selectedStatus == MaintenanceTaskStatus.failed
                    ? 'Required for failed tasks — minimum 10 characters'
                    : 'Required for completion — minimum 10 characters',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (selectedStatus == MaintenanceTaskStatus.completed) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Completion Photo Evidence', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              if (!canSubmitEvidence)
                _LeadOnlyNotice(message: leadOnlyMessage)
              else ...[
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
              ],
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
                onPressed: submitting ? null : onSave,
                child: Text(submitting ? 'Saving...' : 'Save Update'),
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

class _LeadOnlyNotice extends StatelessWidget {
  const _LeadOnlyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            AppIcons.permissionDenied,
            size: AppIconSize.md,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

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
