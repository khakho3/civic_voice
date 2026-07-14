import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/screens/task_completed_screen.dart';
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart';

enum _UploadStatus { idle, uploading, success }

/// MNT-005 — Upload / Resolution Evidence.
class UploadEvidenceScreen extends StatefulWidget {
  const UploadEvidenceScreen({super.key});

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen> {
  AppScreenState _state = AppScreenState.success;

  _UploadStatus _uploadStatus = _UploadStatus.idle;
  double _uploadProgress = 0;
  final int _photoCount = 2;
  final TextEditingController _notesController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _simulateUpload() {
    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _uploadProgress = 0.65;
      _validationError = null;
    });
  }

  void _handleSubmit() {
    if (_photoCount == 0) {
      setState(() => _validationError = 'Evidence is required before task completion.');
      return;
    }
    setState(() {
      _uploadStatus = _UploadStatus.success;
      _validationError = null;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskCompletedScreen()));
      }
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
        title: const Text('Complete Task'),
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(icon: Icon(AppIcons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignedTasksScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
    return _UploadEvidenceForm(
      disabled: disabled,
      uploadStatus: _uploadStatus,
      uploadProgress: _uploadProgress,
      photoCount: _photoCount,
      notesController: _notesController,
      validationError: _validationError,
      onCapture: disabled ? null : _simulateUpload,
      onSubmit: disabled ? null : _handleSubmit,
    );
  }
}

class _UploadEvidenceForm extends StatelessWidget {
  const _UploadEvidenceForm({
    required this.disabled,
    required this.uploadStatus,
    required this.uploadProgress,
    required this.photoCount,
    required this.notesController,
    required this.validationError,
    required this.onCapture,
    required this.onSubmit,
  });

  final bool disabled;
  final _UploadStatus uploadStatus;
  final double uploadProgress;
  final int photoCount;
  final TextEditingController notesController;
  final String? validationError;
  final VoidCallback? onCapture;
  final VoidCallback? onSubmit;

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
            Text('Resolution Evidence', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Upload a clear photo showing the completed work for verification.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            _CapturePanel(hasError: validationError != null, onTap: onCapture),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCapture,
                    icon: const Icon(AppIcons.camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCapture,
                    icon: const Icon(AppIcons.imageUnavailable),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (uploadStatus == _UploadStatus.uploading) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Uploading evidence', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(borderRadius: AppRadius.allXs, child: LinearProgressIndicator(value: uploadProgress)),
            ],
            if (uploadStatus == _UploadStatus.success) ...[
              const SizedBox(height: AppSpacing.md),
              _InlineSuccessNote(semantic: semantic),
            ],
            if (validationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(validationError!, style: textTheme.bodySmall?.copyWith(color: semantic.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Image Previews', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: List.generate(
                photoCount,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _PhotoThumbnail(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Completion Notes', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              maxLines: 3,
              enabled: !disabled,
              decoration: const InputDecoration(
                hintText: "Describe the resolution in detail (e.g., 'Pothole filled with high-grade asphalt, surface leveled...')",
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(AppIcons.upload),
                label: const Text('Submit Resolution'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  const _CapturePanel({required this.hasError, required this.onTap});
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: AppComponentRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppComponentRadius.card,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: hasError ? semantic.error : colorScheme.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.camera, color: colorScheme.primary, size: AppIconSize.lg),
                const SizedBox(height: AppSpacing.sm),
                Text('Tap to capture or upload', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Camera capture or gallery selection · JPG, PNG up to 10MB',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineSuccessNote extends StatelessWidget {
  const _InlineSuccessNote({required this.semantic});
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(AppIcons.success, size: AppIconSize.sm, color: semantic.success),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Upload successful — Resolution evidence is attached to the task.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.success),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: AppComponentRadius.card),
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
              Text('Loading evidence form', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Preparing camera, gallery, and notes.',
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
            Icon(AppIcons.uploadFailed, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text('Upload Failed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Evidence upload failed. Keep the task open and retry.',
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
              'Reconnect before submitting resolution evidence.',
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
              'Camera/gallery permission is required to upload evidence.',
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