import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/civic_bottom_sheet.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_dialog_backdrop.dart';
import '../../../widgets/busy_indicator.dart';
import '../../../services/app_haptics.dart';
import '../../../services/api_client.dart';
import '../widgets/returned_work_notice.dart';
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
  final FocusNode _notesFocus = FocusNode();
  bool _pickingPhoto = false;
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
  bool _accessUnavailable = false;
  bool _requiresRefresh = false;
  MaintenanceTask get _task =>
      MaintenanceTaskDirectory.instance.taskById(widget.task.id) ?? widget.task;

  static const int _minNotesLength = 10;
  static const int _requiredEvidencePhotos = 3;

  @override
  void dispose() {
    _notesFocus.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidencePhoto() async {
    if (_submitting ||
        _pickingPhoto ||
        !_task.needsEvidence ||
        _evidencePhotos.length >= _requiredEvidencePhotos) {
      return;
    }
    final source = await showCivicBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(AppIcons.camera),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    _pickingPhoto = true;

    if (source == ImageSource.camera && !_cameraPermissionExplained) {
      final allowed = await _confirmCameraUse();
      if (!mounted || !allowed) {
        _pickingPhoto = false;
        return;
      }
      _cameraPermissionExplained = true;
    }

    try {
      final photo = await _imagePicker.pickImage(
        source: source,
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
            'Photo access is required to attach completion evidence.';
        _saved = false;
      });
    } finally {
      _pickingPhoto = false;
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

  /// Surfaces a validation failure two ways at once: the inline error text
  /// next to the field it's about (already there), plus a SnackBar, since
  /// this form is long enough that a Save tap from the bottom (where the
  /// button lives) can leave the inline error scrolled off-screen and
  /// effectively invisible.
  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSave() async {
    if (_submitting || _requiresRefresh || !_task.needsEvidence) return;
    final notes = _notesController.text.trim();
    if (_selectedStatus == MaintenanceTaskStatus.completed &&
        notes.length < _minNotesLength) {
      final message =
          'Completion notes are required. Describe the work completed in at least $_minNotesLength characters.';
      setState(() {
        _validationError = message;
        _evidenceError = null;
        _saved = false;
      });
      _showValidationSnackBar(message);
      _notesFocus.requestFocus();
      return;
    }
    if (_selectedStatus == MaintenanceTaskStatus.failed &&
        notes.length < _minNotesLength) {
      const message = 'Describe the field issue in at least 10 characters.';
      setState(() {
        _validationError = message;
        _evidenceError = null;
        _saved = false;
      });
      _showValidationSnackBar(message);
      _notesFocus.requestFocus();
      return;
    }

    if (_selectedStatus == MaintenanceTaskStatus.completed &&
        _evidencePhotos.length < _requiredEvidencePhotos) {
      final message =
          'Attach $_requiredEvidencePhotos photos to submit this for approval.';
      setState(() {
        _validationError = null;
        _evidenceError = message;
        _saved = false;
      });
      _showValidationSnackBar(message);
      return;
    }

    AppHaptics.activate();
    setState(() => _submitting = true);
    try {
      await MaintenanceTaskDirectory.instance.updateTaskOnServer(
        _task,
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requiresRefresh = error is! FormatException;
        _accessUnavailable =
            error is ApiException && [401, 403, 404].contains(error.statusCode);
        _validationError = error is FormatException
            ? error.message
            : _accessUnavailable
            ? 'This task is no longer available to your account. Return to Tasks.'
            : 'The update could not be confirmed. Refresh the task before retrying.';
        _saved = false;
        _submitting = false;
      });
      return;
    }
    if (_selectedStatus == MaintenanceTaskStatus.completed) {
      widget.onTaskCompleted?.call(widget.task.id);
    }
  }

  Future<void> _refreshTask() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await MaintenanceTaskDirectory.instance.refresh();
      if (!mounted) return;
      setState(() {
        _accessUnavailable =
            MaintenanceTaskDirectory.instance.taskById(widget.task.id) == null;
        _requiresRefresh = false;
        _validationError = _accessUnavailable
            ? 'This task is no longer available to your account. Return to Tasks.'
            : null;
        _submitting = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _validationError =
              'Could not refresh this task. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _handleDiscard() async {
    if (_submitting) return;
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
    final task = _task;
    final readOnly =
        task.status == MaintenanceTaskStatus.completed ||
        task.status == MaintenanceTaskStatus.failed ||
        task.status == MaintenanceTaskStatus.pendingApproval ||
        _accessUnavailable ||
        _requiresRefresh;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _UpdateProgressForm(
              task: task,
              disabled: readOnly,
              selectedStatus: _selectedStatus,
              notesController: _notesController,
              minNotesLength: _minNotesLength,
              validationError: _validationError,
              saved: _saved,
              submitting: _submitting,
              notesFocus: _notesFocus,
              onRemoveEvidence: (index) {
                if (_submitting || readOnly) return;
                setState(() {
                  _evidencePhotos.removeAt(index);
                  _saved = false;
                  _evidenceError = null;
                });
              },
              onStatusChanged: readOnly || _submitting
                  ? null
                  : (status) {
                      AppHaptics.activate();
                      setState(() {
                        _selectedStatus = status;
                        _validationError = null;
                        _evidenceError = null;
                        _saved = false;
                      });
                    },
              onNotesChanged: readOnly || _submitting
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
              onAttachEvidence: readOnly || _submitting
                  ? null
                  : _captureEvidencePhoto,
              onSave: readOnly ? null : _handleSave,
              onRefresh: _refreshTask,
              onDiscard: readOnly || _submitting ? null : _handleDiscard,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Update Progress',
              onBack: widget.onBack,
              trailing: Chip(
                label: Text(
                  '#${task.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
    required this.minNotesLength,
    required this.validationError,
    required this.evidencePhotos,
    required this.requiredEvidencePhotos,
    required this.evidenceError,
    required this.saved,
    required this.submitting,
    required this.notesFocus,
    required this.onRemoveEvidence,
    required this.onStatusChanged,
    required this.onNotesChanged,
    required this.onAttachEvidence,
    required this.onSave,
    required this.onRefresh,
    required this.onDiscard,
  });

  final MaintenanceTask task;
  final bool disabled;

  final FocusNode notesFocus;
  final ValueChanged<int> onRemoveEvidence;
  final MaintenanceTaskStatus selectedStatus;
  final TextEditingController notesController;
  final int minNotesLength;
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
  final VoidCallback onRefresh;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final evidencePhotoCount = evidencePhotos.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        DetailHeader.topInset(context) + AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        if (task.fieldIssueNotes != null) ...[
          Text('Previous field issue', style: textTheme.titleSmall),
          Text(task.fieldIssueNotes!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (task.status == MaintenanceTaskStatus.pendingApproval) ...[
          const Text(
            'Submitted for approval. A municipal officer is confirming this work. This task is read-only until they respond.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (task.sendBackReason?.trim().isNotEmpty == true) ...[
          ReturnedWorkNotice(reason: task.sendBackReason!),
          const SizedBox(height: AppSpacing.md),
        ],
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
          label: 'Field issue',
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
              ? 'Field Issue Note (required)'
              : selectedStatus == MaintenanceTaskStatus.completed
              ? 'Completion Notes (required)'
              : 'Work Notes',
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: notesController,
          focusNode: notesFocus,
          onChanged: onNotesChanged,
          maxLines: 4,
          maxLength: 2000,
          enabled: !disabled && !submitting,
          decoration: InputDecoration(
            hintText: selectedStatus == MaintenanceTaskStatus.failed
                ? 'Describe the obstacle and what is needed next...'
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
            'Minimum $minNotesLength characters',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (selectedStatus == MaintenanceTaskStatus.completed) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Completion Photo Evidence', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...[
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
                    onRemove:
                        !disabled &&
                            !submitting &&
                            index < evidencePhotos.length
                        ? () => onRemoveEvidence(index)
                        : null,
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
              style: textTheme.bodySmall?.copyWith(color: semantic.errorText),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : onSave,
            child: BusyLabel(
              busy: submitting,
              busyLabel: selectedStatus == MaintenanceTaskStatus.completed
                  ? 'Submitting for approval'
                  : 'Saving update',
              child: Text(
                selectedStatus == MaintenanceTaskStatus.completed
                    ? 'Submit for Approval'
                    : 'Save Update',
              ),
            ),
          ),
        ),
        if (validationError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: submitting ? null : onRefresh,
            child: const Text('Refresh task'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onDiscard,
            child: const Text('Discard Draft'),
          ),
        ),
      ],
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
                  ).textTheme.titleSmall?.copyWith(color: semantic.successText),
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
    this.onRemove,
  });

  final int index;
  final VoidCallback? onRemove;
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
                    right: 0,
                    top: 0,
                    child: IconButton.filled(
                      tooltip: 'Remove photo ${index + 1}',
                      onPressed: onRemove,
                      icon: const Icon(AppIcons.close),
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
