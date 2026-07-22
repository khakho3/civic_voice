import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_status.dart';
import '../models/incoming_report.dart';
import '../models/verification_data.dart';
import '../services/municipal_report_directory.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../widgets/municipal_detail_header.dart';
import '../widgets/officer_contact_row.dart';

/// MUN-004 — Verify / Reject Report.
///
/// Approved states (Figma "04 - Report Verification" section): Default,
/// Loading, Verified, Rejected, Failed, Error, Offline, Permission,
/// Disabled.
///
/// Distinct from Report Review's Error/Offline: here "Failed" (Verification
/// Failed) is specifically the verify/reject *submission* failing, separate
/// from "Error" (Something went wrong), which is the report failing to
/// *load* in the first place — two different failure points worth keeping
/// distinct since they need different recovery actions ("Back to Report" vs
/// "Return to Dashboard").
enum MunicipalVerificationViewState {
  loading,
  loaded,
  verified,
  rejected,
  failed,
  error,
  offline,
  permissionDenied,
  disabled,
}

class MunicipalVerificationScreen extends StatefulWidget {
  const MunicipalVerificationScreen({
    super.key,
    this.referenceId = 'REQ-8421',
    this.status = ReportStatus.submitted,
    this.initialState = MunicipalVerificationViewState.loaded,
    this.onBack,
    this.onNavigateToDashboard,
    this.onBackToInbox,
    this.onAssignTeam,
  });

  final String referenceId;
  final ReportStatus status;
  final MunicipalVerificationViewState initialState;

  /// Pops one level — wired to the header's back arrow only.
  final VoidCallback? onBack;

  /// Returns all the way to the Dashboard tab — distinct from [onBack],
  /// which only pops one level (back to Report Review). Wired to every
  /// "Return to Dashboard" / "Back to Dashboard" action.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onBackToInbox;
  final VoidCallback? onAssignTeam;

  @override
  State<MunicipalVerificationScreen> createState() =>
      _MunicipalVerificationScreenState();
}

class _MunicipalVerificationScreenState
    extends State<MunicipalVerificationScreen> {
  late MunicipalVerificationViewState _state = widget.initialState;
  late final VerificationData _data;
  final Set<int> _checked = {};
  final _reasonController = TextEditingController();
  QuickRejectionReason? _selectedQuickReason;

  bool get _allConfirmed => _checked.length == _data.checklist.length;

  @override
  void initState() {
    super.initState();
    final report = MunicipalReportDirectory.instance.byReferenceId(
      widget.referenceId,
    );
    _data = report?.apiId == null
        ? VerificationData.mock()
        : VerificationData.fromReport(report!);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      if (!_checked.add(index)) _checked.remove(index);
    });
  }

  void _selectQuickReason(QuickRejectionReason reason) {
    setState(() {
      final deselecting = _selectedQuickReason == reason;
      _selectedQuickReason = deselecting ? null : reason;
      _reasonController.text = deselecting ? '' : reason.label;
    });
  }

  Future<void> _submitVerify() async {
    setState(() => _state = MunicipalVerificationViewState.loading);
    try {
      await MunicipalReportDirectory.instance.verifyOnServer(
        widget.referenceId,
      );
      if (mounted) {
        setState(() => _state = MunicipalVerificationViewState.verified);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = MunicipalVerificationViewState.failed);
      }
    }
  }

  Future<void> _submitReject() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a reason before rejecting this report.'),
        ),
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reject this report?',
      message:
          'The citizen who submitted ${widget.referenceId} will be notified '
          'that it was rejected. This can\'t be undone.',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _state = MunicipalVerificationViewState.loading);
    try {
      await MunicipalReportDirectory.instance.rejectOnServer(
        widget.referenceId,
        reason,
        _selectedQuickReason,
      );
      if (mounted) {
        setState(() => _state = MunicipalVerificationViewState.rejected);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = MunicipalVerificationViewState.failed);
      }
    }
  }

  void _retryLoad() {
    setState(() => _state = MunicipalVerificationViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = MunicipalVerificationViewState.loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showActionBar =
        _state == MunicipalVerificationViewState.loaded ||
        _state == MunicipalVerificationViewState.offline ||
        _state == MunicipalVerificationViewState.disabled;
    final formEnabled = _state == MunicipalVerificationViewState.loaded;
    // widget.status is fixed at whatever it was when this screen opened, so
    // without this the header would keep showing the pre-rejection status
    // (e.g. "Submitted") even after the report's actually been rejected.
    // "Verified" has no exact equivalent in ReportStatus (it moves straight
    // to pending-assignment rather than getting its own status), so that
    // case is left showing widget.status.
    final effectiveStatus = _state == MunicipalVerificationViewState.rejected
        ? ReportStatus.rejected
        : widget.status;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
                  if (_state == MunicipalVerificationViewState.offline)
                    const _OfflineBanner(),
                  Expanded(
                    child: switch (_state) {
                      MunicipalVerificationViewState.loading =>
                        const _LoadingSkeleton(),
                      MunicipalVerificationViewState.loaded =>
                        _VerificationForm(
                          data: _data,
                          enabled: true,
                          checked: _checked,
                          onToggle: _toggleChecklistItem,
                          reasonController: _reasonController,
                          onQuickReasonSelected: _selectQuickReason,
                        ),
                      MunicipalVerificationViewState.offline =>
                        _VerificationForm(
                          data: _data,
                          enabled: false,
                          checked: _checked,
                          onToggle: _toggleChecklistItem,
                          reasonController: _reasonController,
                          onQuickReasonSelected: _selectQuickReason,
                          disabledCaption: 'Checklist disabled while offline.',
                        ),
                      MunicipalVerificationViewState.disabled => _VerificationForm(
                        data: _data,
                        enabled: false,
                        checked: _checked,
                        onToggle: _toggleChecklistItem,
                        reasonController: _reasonController,
                        onQuickReasonSelected: _selectQuickReason,
                        // The approved frame reuses the Offline caption verbatim
                        // here too, which reads as a copy/paste leftover (this
                        // state shows no offline banner) — using accurate, generic
                        // copy instead of a factually wrong "while offline" claim.
                        disabledCaption:
                            'This report is no longer available for review.',
                      ),
                      MunicipalVerificationViewState.verified => AppStateMessage(
                        icon: AppIcons.success,
                        badgeColor: AppColors.success,
                        title: 'Report Verified Successfully',
                        message:
                            'The report is now ready for maintenance assignment.',
                        primaryActionLabel: 'Assign Maintenance Team',
                        onPrimaryAction: widget.onAssignTeam,
                        secondaryActionLabel: 'Back to Dashboard',
                        onSecondaryAction: widget.onNavigateToDashboard,
                        bordered: true,
                      ),
                      MunicipalVerificationViewState.rejected =>
                        AppStateMessage(
                          icon: AppIcons.success,
                          badgeColor: AppColors.success,
                          title: 'Report Rejected',
                          message:
                              'The citizen has been notified with the provided '
                              'reason.',
                          primaryActionLabel: 'Back to Inbox',
                          onPrimaryAction: widget.onBackToInbox,
                          secondaryActionLabel: 'Return to Dashboard',
                          onSecondaryAction: widget.onNavigateToDashboard,
                          bordered: true,
                        ),
                      MunicipalVerificationViewState.failed => AppStateMessage(
                        icon: AppIcons.warning,
                        badgeColor: AppColors.error,
                        primaryActionColor: AppColors.error,
                        title: 'Verification Failed',
                        message:
                            'We couldn\'t submit the verification. Check your '
                            'connection and try again.',
                        primaryActionLabel: 'Try again',
                        onPrimaryAction: _submitVerify,
                        secondaryActionLabel: 'Back to Report',
                        onSecondaryAction: () => setState(
                          () => _state = MunicipalVerificationViewState.loaded,
                        ),
                        bordered: true,
                      ),
                      MunicipalVerificationViewState.error => AppStateMessage(
                        icon: AppIcons.warning,
                        badgeColor: AppColors.error,
                        primaryActionColor: AppColors.error,
                        title: 'Something went wrong',
                        message:
                            'We encountered a network issue while loading this '
                            'report. Please try again.',
                        primaryActionLabel: 'Try again',
                        onPrimaryAction: _retryLoad,
                        secondaryActionLabel: 'Return to Dashboard',
                        onSecondaryAction: widget.onNavigateToDashboard,
                        bordered: true,
                      ),
                      MunicipalVerificationViewState.permissionDenied =>
                        AppStateMessage(
                          icon: AppIcons.permissionDenied,
                          badgeColor: AppColors.primary,
                          title: 'Access Restricted',
                          message:
                              'You do not have permission to verify or reject '
                              'reports for this district.',
                          primaryActionLabel: 'Return to Dashboard',
                          onPrimaryAction: widget.onNavigateToDashboard,
                          bordered: true,
                        ),
                    },
                  ),
                  if (showActionBar)
                    _ActionBar(
                      canVerify: formEnabled && _allConfirmed,
                      canReject: formEnabled,
                      onVerify: _submitVerify,
                      onReject: _submitReject,
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: 'Verify Report',
              referenceId: widget.referenceId,
              onBack: widget.onBack,
              trailing: ReportStatusBadge(status: effectiveStatus),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offline banner
// ---------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            AppIcons.offline,
            size: AppIconSize.sm,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No internet connection — changes will sync when you\'re '
              'back online',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form (Default / Offline / Disabled share this — only `enabled` differs)
// ---------------------------------------------------------------------------

class _VerificationForm extends StatelessWidget {
  const _VerificationForm({
    required this.data,
    required this.enabled,
    required this.checked,
    required this.onToggle,
    required this.reasonController,
    required this.onQuickReasonSelected,
    this.disabledCaption,
  });

  final VerificationData data;
  final bool enabled;
  final Set<int> checked;
  final ValueChanged<int> onToggle;
  final TextEditingController reasonController;
  final ValueChanged<QuickRejectionReason> onQuickReasonSelected;
  final String? disabledCaption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(data.locationSummary, style: textTheme.bodySmall),
              if (data.confidence != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _CompactConfidenceSummary(confidence: data.confidence!),
              ],
              const SizedBox(height: AppSpacing.md),
              _LabeledValue(
                label: 'CATEGORY',
                child: Text(data.category.label, style: textTheme.titleSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              _LabeledValue(
                label: 'CITIZEN',
                child: Row(
                  children: [
                    // Reuses Report Review's citizen-avatar treatment
                    // (light primary tint) rather than this frame's solid
                    // violet fill, so the same entity reads consistently
                    // across screens.
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        data.citizenName
                            .trim()
                            .split(RegExp(r'\s+'))
                            .map((p) => p.isEmpty ? '' : p[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(data.citizenName, style: textTheme.titleSmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OfficerContactRow(
                officerName: data.officerName,
                officerPhone: data.officerPhone,
                label: 'Citizen',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outline),
            borderRadius: AppComponentRadius.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.reportVerified,
                    size: AppIconSize.md,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Verification Checklist', style: textTheme.titleSmall),
                ],
              ),
              for (var i = 0; i < data.checklist.length; i++)
                _ChecklistRow(
                  item: data.checklist[i],
                  isChecked: checked.contains(i),
                  enabled: enabled,
                  isFirst: i == 0,
                  onTap: enabled ? () => onToggle(i) : null,
                ),
              if (disabledCaption != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(disabledCaption!, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Reason for rejection',
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder(
              valueListenable: reasonController,
              builder: (context, value, _) =>
                  Text('${value.text.length}/500', style: textTheme.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: reasonController,
          enabled: enabled,
          maxLines: 4,
          maxLength: 500,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
          decoration: const InputDecoration(
            hintText: 'Explain why this report cannot be accepted...',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QuickRejectionReason.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final reason = QuickRejectionReason.values[index];
              final selected = reasonController.text == reason.label;
              return _QuickReasonChip(
                label: reason.label,
                selected: selected,
                onTap: enabled ? () => onQuickReasonSelected(reason) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactConfidenceSummary extends StatelessWidget {
  const _CompactConfidenceSummary({required this.confidence});

  final ReportConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final score = confidence.score ?? 0;
    final (label, color) = switch (score) {
      < 40 => ('Low', AppColors.error),
      < 70 => ('Moderate', AppColors.warning),
      _ => ('High', AppColors.success),
    };
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.allXl,
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '$score/95 confidence signal · '
            '${confidence.seconderCount ?? 0} community confirmations',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.isChecked,
    required this.enabled,
    required this.isFirst,
    this.onTap,
  });

  final ChecklistItem item;
  final bool isChecked;
  final bool enabled;
  final bool isFirst;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = !enabled;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          top: isFirst ? AppSpacing.md : AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: colorScheme.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: isChecked ? AppColors.success : colorScheme.outline,
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        AppIcons.success,
                        size: AppIconSize.sm,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: muted ? colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  Text(item.description, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReasonChip extends StatelessWidget {
  const _QuickReasonChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : colorScheme.outline,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — no actions shown, per the approved frame.
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainer;
    final highlight = Theme.of(context).colorScheme.surfaceContainerLow;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget block({double height = 120}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: AppRadius.allXs,
            ),
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        block(),
        block(height: 60),
        block(height: 60),
        block(height: 200),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action bar — Verify Report / Reject Report stacked vertically (unlike
// Report Review's side-by-side layout, matching the approved frame).
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canVerify,
    required this.canReject,
    required this.onVerify,
    required this.onReject,
  });

  final bool canVerify;
  final bool canReject;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // Verify only enables once every checklist item is confirmed
              // — the checklist exists to be completed before verifying.
              onPressed: canVerify ? onVerify : null,
              icon: const Icon(AppIcons.verify, size: AppIconSize.sm + 2),
              label: const Text('Verify Report'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // Rejecting doesn't require the checklist — always available
              // while the form is enabled.
              onPressed: canReject ? onReject : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(
                AppIcons.statusRejected,
                size: AppIconSize.sm + 2,
              ),
              label: const Text('Reject Report'),
            ),
          ),
        ],
      ),
    );
  }
}
