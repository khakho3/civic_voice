import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_role_management_data.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-004 — Role Management.
///
/// The approved Figma export shows an admin-creatable list of arbitrary
/// "roles" (Super Admin/Moderator/Field Officer, each with a free-text
/// permission-tag list edited inline, plus an "Add Role" flow) — rebuilt
/// here as a fixed two-tier system ([AdminTier.admin]/[AdminTier.superAdmin])
/// instead, for two reasons:
///
/// - The export's own permission vocabulary ("Edit Post", "Content Ban")
///   doesn't correspond to anything in CivicVoice — there's no "post" or
///   community-moderation surface in this app, the same kind of
///   copy-pasted-from-elsewhere content already caught once this session in
///   ADM-002's fake "Moderator/Support/Auditor" account roles.
/// - An open-ended, admin-creatable permission system needs somewhere that
///   actually enforces it, and this app has no backend — nothing here can
///   ever be more than descriptive. The one real, scoped need is
///   differentiating privilege *within* the System Administrator account
///   pool itself (not every admin should be able to delete records or
///   reassign other admins' tiers) — a closed two-value set handles that
///   without pretending to be general-purpose RBAC.
///
/// This screen is read-only: it documents what each tier can do, it
/// doesn't create or edit tiers (there's nothing to add — the set is
/// closed) and it doesn't assign a tier to a specific account either.
/// Promoting/demoting an admin between tiers belongs on ADM-003 User
/// Details (not built yet), the same way User Management's own
/// activate/deactivate action lives on the account, not here.
///
/// Approved states kept from the export: Loading, Offline, Error
/// ("Something went wrong"), Unauthorized. No Empty state — [AdminTier] is
/// a fixed, always-populated enum, so "no tiers exist" can't happen (same
/// reasoning as [AdminDashboardScreen] having no Empty state of its own).
///
/// Export quirks, resolved by content rather than folder/file name (the
/// same kind of split-across-two-folders slip seen throughout this app):
/// "erro" (dark only) pairs with "error" (light only) as Error's two theme
/// variants.
///
/// Error/Offline/Unauthorized render as a floating card over a dimmed
/// title block in the export — inconsistent with every other screen in
/// this module (a full [AppStateMessage] swap, title fully visible, same
/// as [AdminDashboardScreen]/`AdminUserManagementScreen`). Normalized to
/// match.
enum AdminRoleManagementViewState {
  loading,
  loaded,
  offline,
  error,
  unauthorized,
}

class AdminRoleManagementScreen extends StatefulWidget {
  const AdminRoleManagementScreen({
    super.key,
    this.initialState = AdminRoleManagementViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToSettings,
    this.onOpenSystemActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
  });

  final AdminRoleManagementViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToSettings;

  /// Opens ADM-006 System Activity — also this screen's own "View Detailed
  /// Logs" destination, same shared-destination pattern as Dashboard's
  /// Activity Monitoring card. Nullable: ADM-006 isn't built yet.
  final VoidCallback? onOpenSystemActivity;

  /// Forwarded to [AdminScaffold]'s drawer. Nullable: ADM-008 isn't built
  /// yet.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminRoleManagementScreen> createState() =>
      _AdminRoleManagementScreenState();
}

class _AdminRoleManagementScreenState extends State<AdminRoleManagementScreen> {
  late AdminRoleManagementViewState _state = widget.initialState;

  void _retry() {
    setState(() => _state = AdminRoleManagementViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = AdminRoleManagementViewState.loaded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.roles,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenSystemActivity: widget.onOpenSystemActivity,
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminRoleManagementViewState.loading => const _LoadingSkeleton(),
        _ => _RoleManagementBody(
          state: _state,
          onRetry: _retry,
          onOpenSystemActivity: widget.onOpenSystemActivity,
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _RoleManagementBody extends StatelessWidget {
  const _RoleManagementBody({
    required this.state,
    required this.onRetry,
    this.onOpenSystemActivity,
  });

  final AdminRoleManagementViewState state;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSystemActivity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chromeInset = AdminScaffold.contentPadding(context);
    final dimmed =
        state == AdminRoleManagementViewState.offline ||
        state == AdminRoleManagementViewState.error ||
        state == AdminRoleManagementViewState.unauthorized;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Opacity(
          opacity: dimmed ? 0.5 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Access Control', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Privilege tiers for System Administrator accounts.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (state) {
          AdminRoleManagementViewState.loading ||
          AdminRoleManagementViewState.loaded => _LoadedContent(
            onOpenSystemActivity: onOpenSystemActivity,
          ),
          AdminRoleManagementViewState.offline => AppStateMessage(
            icon: AppIcons.offline,
            badgeColor: AppColors.error,
            title: 'You\'re offline',
            message: 'Check your connection and retry loading role management.',
            primaryActionLabel: 'Retry connection',
            onPrimaryAction: onRetry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
          AdminRoleManagementViewState.error => AppStateMessage(
            icon: AppIcons.warning,
            badgeColor: AppColors.error,
            title: 'Something went wrong',
            message: 'Unable to load system roles right now.',
            primaryActionLabel: 'Retry',
            onPrimaryAction: onRetry,
            primaryActionColor: AppColors.error,
            bordered: true,
          ),
          AdminRoleManagementViewState.unauthorized => const AppStateMessage(
            icon: AppIcons.permissionDenied,
            badgeColor: AppColors.error,
            title: 'Unauthorized Access',
            message: 'Administrative privileges are required to manage roles.',
            bordered: true,
          ),
        },
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded content — tier cards, Security Audit callout, permissions table
// ---------------------------------------------------------------------------

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({this.onOpenSystemActivity});

  final VoidCallback? onOpenSystemActivity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tiers = [AdminTier.superAdmin, AdminTier.admin];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tier in tiers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TierCard(tier: tier),
          ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppIconSize.lg,
                    height: AppIconSize.lg,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.shieldAlert,
                      size: AppIconSize.sm + 2,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Audit Required',
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last full permission audit was 14 days ago. '
                          'Review logs for anomalies.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: onOpenSystemActivity,
                  child: const Text('View Detailed Logs'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Permissions Check', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              const _PermissionTable(tiers: tiers),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionTable extends StatelessWidget {
  const _PermissionTable({required this.tiers});

  final List<AdminTier> tiers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget headerCell(String label, {int flex = 1}) => Expanded(
      flex: flex,
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            headerCell('Permission Type', flex: 2),
            for (final tier in tiers) headerCell(tier.label, flex: 1),
          ],
        ),
        const Divider(height: AppSpacing.lg),
        for (var i = 0; i < PermissionType.values.length; i++) ...[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  PermissionType.values[i].label,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final tier in tiers)
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Icon(
                      tier.permissions[PermissionType.values[i]] ?? false
                          ? AppIcons.success
                          : AppIcons.statusRejected,
                      size: AppIconSize.md,
                      color: tier.permissions[PermissionType.values[i]] ?? false
                          ? AppColors.statusResolved
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          if (i != PermissionType.values.length - 1)
            const Divider(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tier card
// ---------------------------------------------------------------------------

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});

  final AdminTier tier;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppIconSize.lg,
                height: AppIconSize.lg,
                decoration: BoxDecoration(
                  color: tier.tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tier.icon,
                  size: AppIconSize.sm + 2,
                  color: tier.tint,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.label,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tier.scope,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(tier.description, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final label in tier.grantedPermissionLabels) _TagChip(label),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
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
    final chromeInset = AdminScaffold.contentPadding(context);

    Widget block({double? width, double height = 16, double? radius}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: BorderRadius.circular(radius ?? 4),
            ),
          );
        },
      );
    }

    Widget cardBlock() => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              block(width: 32, height: 32, radius: 16),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(height: 14, width: 120),
                    const SizedBox(height: AppSpacing.xs),
                    block(height: 12, width: 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          block(height: 12),
          const SizedBox(height: AppSpacing.xs),
          block(height: 12, width: 180),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              block(height: 28, width: 90, radius: 14),
              const SizedBox(width: AppSpacing.xs),
              block(height: 28, width: 90, radius: 14),
            ],
          ),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(height: 24, width: 220),
        const SizedBox(height: AppSpacing.sm),
        block(height: 14),
        const SizedBox(height: AppSpacing.xs),
        block(height: 14, width: 260),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(),
        const SizedBox(height: AppSpacing.sm),
        cardBlock(),
        const SizedBox(height: AppSpacing.lg),
        block(height: 140, radius: 12),
      ],
    );
  }
}
