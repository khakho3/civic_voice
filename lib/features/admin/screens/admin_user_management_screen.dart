import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/collapsible_list_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/admin_user_management_data.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-002 — User Management.
///
/// Approved states (Figma "02/User management" export): Default, Loading,
/// Empty ("No Users"), No Results, Offline, Error ("Unable to Load Users"),
/// Unauthorized — the same seven-state shape as every Ministry Supervisor
/// filter+list screen, including the search+chip chrome staying visible and
/// interactive across Default/Empty/No Results and disabled (not removed)
/// for Offline/Error/Unauthorized. Loaded content is wrapped in
/// [CollapsibleListHeader] so the chrome doesn't permanently eat vertical
/// space above the list.
///
/// Two export quirks, resolved by content rather than folder/file name:
/// - The frame filed under `loading/light-1.png` is actually the Empty
///   state's light variant (the real loading skeleton is `light.png`),
///   filling what would otherwise be a missing light reference for Empty.
/// - "no reults"/"unauthoized" are typo'd dark-only folders paired with
///   correctly-spelled light-only folders — the same kind of split-across-
///   two-folders slip already seen throughout the Ministry module.
///
/// Every state's header shows "CivicAdmin" instead of "User Management" —
/// a copy/paste-from-Dashboard artifact (Dashboard's own confirmed brand
/// text is "CivicVoice", not "CivicAdmin", so this isn't even internally
/// consistent with itself). [AdminScaffold]'s existing rule already handles
/// this correctly: only [AdminTab.dashboard] shows the brand mark, every
/// other tab shows its own title in the header instead — which is also why
/// the body here doesn't repeat "User Management" as its own headline the
/// way MIN-001-style brand-mark headers need one: with the header already
/// carrying the real title, a second copy in the body would just be
/// redundant, the same conclusion already reached for every other non-
/// Dashboard screen in the Ministry module.
///
/// The approved frame's four users carry made-up roles ("Moderator",
/// "Support", "Auditor") that don't correspond to anything in CivicVoice's
/// actual five-role system — [AppRole] already exists as the single source
/// of truth for role iconography everywhere else in the app, so the mock
/// data and the "Admins"/"Staff" filter chips are built against that
/// instead. Citizens don't get accounts *provisioned* by an admin (they
/// self-register), but they're still moderatable — flagged or deactivated
/// for abuse, say — so a citizen appears in the mock list too, just outside
/// both the "Admins" and "Staff" chip buckets.
enum AdminUserManagementViewState {
  loading,
  loaded,
  empty,
  noResults,
  offline,
  error,
  unauthorized,
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({
    super.key,
    this.initialState = AdminUserManagementViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onOpenUserDetails,
    this.onNotificationsTap,
  });

  final AdminUserManagementViewState initialState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  /// Opens ADM-003 User Details for the tapped user — the spec's only exit
  /// point. Nullable: ADM-003 isn't built yet.
  final ValueChanged<AdminUserItem>? onOpenUserDetails;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late AdminUserManagementViewState _state = widget.initialState;
  List<AdminUserItem> _users = mockAdminUsers();
  final TextEditingController _searchController = TextEditingController();
  AdminUserFilter _filter = AdminUserFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _state = AdminUserManagementViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = AdminUserManagementViewState.loaded);
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _filter = AdminUserFilter.all;
      _state = AdminUserManagementViewState.loaded;
    });
  }

  void _toggleActive(AdminUserItem user) {
    setState(() {
      _users = [
        for (final u in _users)
          if (u == user)
            u.copyWith(
              status: u.status == AdminUserStatus.inactive
                  ? AdminUserStatus.active
                  : AdminUserStatus.inactive,
            )
          else
            u,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Empty/No Results keep the chrome fixed (not collapsible) rather than
    // wrapping it in CollapsibleListHeader like Loaded does: their content
    // is a short, centered state card with nothing to scroll, so there's no
    // scroll gesture to drive a collapse in the first place. Offline/Error/
    // Unauthorized go a step further and disable the chrome entirely.
    final chromeEnabled =
        _state == AdminUserManagementViewState.empty ||
        _state == AdminUserManagementViewState.noResults;

    // The approved Default frame's own subtitle ("Manage citizen access and
    // administrative permissions.") is wrong on its own terms: citizens
    // self-register and aren't managed here at all — every user this
    // screen actually lists (Admin/Moderator/Support/Auditor) is
    // admin-provisioned platform staff, the same population Dashboard's own
    // "User Management" row already describes accurately. Reused that
    // copy here instead, and dropped the frame's separate short-vs-long
    // subtitle split along with it — one accurate line beats two, one of
    // which was wrong.
    const subtitle = 'Manage administrator and staff accounts.';

    return AdminScaffold(
      selectedTab: AdminTab.users,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.roles) widget.onNavigateToRoles?.call();
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      body: switch (_state) {
        AdminUserManagementViewState.loading => const _LoadingSkeleton(),
        AdminUserManagementViewState.loaded => Padding(
          padding: EdgeInsets.only(
            top: AdminScaffold.contentPadding(context).top,
          ),
          child: CollapsibleListHeader(
            header: _FilterChrome(
              subtitle: subtitle,
              controller: _searchController,
              filter: _filter,
              enabled: true,
              onQueryChanged: (q) => setState(() => _query = q),
              onFilterSelected: (f) => setState(() => _filter = f),
            ),
            child: _UserList(
              users: _users,
              query: _query,
              filter: _filter,
              onClearFilters: _clearFilters,
              onToggleActive: _toggleActive,
              onOpenUserDetails: widget.onOpenUserDetails,
            ),
          ),
        ),
        _ => Column(
          children: [
            SizedBox(height: AdminScaffold.contentPadding(context).top),
            _FilterChrome(
              subtitle: subtitle,
              controller: _searchController,
              filter: _filter,
              enabled: chromeEnabled,
              onQueryChanged: chromeEnabled
                  ? (q) => setState(() => _query = q)
                  : null,
              onFilterSelected: chromeEnabled
                  ? (f) => setState(() => _filter = f)
                  : null,
            ),
            Expanded(
              child: switch (_state) {
                AdminUserManagementViewState.loading ||
                AdminUserManagementViewState.loaded => const SizedBox.shrink(),
                AdminUserManagementViewState.empty => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.team,
                    badgeColor: AppColors.primary,
                    title: 'No Users',
                    message:
                        'Platform users will appear here once accounts '
                        'are available.',
                    primaryActionLabel: 'Refresh',
                    onPrimaryAction: _retry,
                  ),
                ),
                AdminUserManagementViewState.noResults => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.noFilterMatch,
                    badgeColor: AppColors.primary,
                    title: 'No Results',
                    message: 'No users match the current search or filters.',
                    primaryActionLabel: 'Clear Filters',
                    onPrimaryAction: _clearFilters,
                  ),
                ),
                AdminUserManagementViewState.offline => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.offline,
                    badgeColor: AppColors.error,
                    title: 'You\'re offline',
                    message: 'Check your connection and retry loading users.',
                    primaryActionLabel: 'Retry connection',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                AdminUserManagementViewState.error => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppStateMessage(
                    icon: AppIcons.warning,
                    badgeColor: AppColors.error,
                    title: 'Unable to Load Users',
                    message:
                        'The user management service could not return '
                        'account data right now.',
                    primaryActionLabel: 'Try again',
                    onPrimaryAction: _retry,
                    primaryActionColor: AppColors.error,
                  ),
                ),
                AdminUserManagementViewState.unauthorized => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: const AppStateMessage(
                    icon: AppIcons.permissionDenied,
                    badgeColor: AppColors.error,
                    title: 'Unauthorized Access',
                    message:
                        'Administrative privileges are required to manage '
                        'users.',
                  ),
                ),
              },
            ),
          ],
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chrome — title/subtitle + search field + status chips
// ---------------------------------------------------------------------------

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({
    required this.subtitle,
    required this.controller,
    required this.filter,
    required this.enabled,
    this.onQueryChanged,
    this.onFilterSelected,
  });

  final String subtitle;
  final TextEditingController controller;
  final AdminUserFilter filter;
  final bool enabled;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<AdminUserFilter>? onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onQueryChanged,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search users',
                border: InputBorder.none,
                prefixIcon: Icon(
                  AppIcons.search,
                  size: AppIconSize.md,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          AppIcons.close,
                          size: AppIconSize.md,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: enabled
                            ? () {
                                controller.clear();
                                onQueryChanged?.call('');
                              }
                            : null,
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AdminUserFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final option = AdminUserFilter.values[index];
                return _FilterChip(
                  label: option.label,
                  selected: option == filter,
                  onTap: enabled ? () => onFilterSelected?.call(option) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.primary : colorScheme.surfaceContainer,
      shape: const StadiumBorder(),
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User list
// ---------------------------------------------------------------------------

class _UserList extends StatelessWidget {
  const _UserList({
    required this.users,
    required this.query,
    required this.filter,
    required this.onClearFilters,
    required this.onToggleActive,
    this.onOpenUserDetails,
  });

  final List<AdminUserItem> users;
  final String query;
  final AdminUserFilter filter;
  final VoidCallback onClearFilters;
  final ValueChanged<AdminUserItem> onToggleActive;
  final ValueChanged<AdminUserItem>? onOpenUserDetails;

  @override
  Widget build(BuildContext context) {
    // The full scaffold contentPadding, not just the raw safe-area inset —
    // this list sits behind the floating bottom nav (AdminScaffold stacks
    // it on top via Align, not a Column sibling that would push content
    // out of the way), so the bottom padding has to reserve the nav bar's
    // own height too or the last card ends up tucked behind it.
    final bottomInset = AdminScaffold.contentPadding(context).bottom;
    final filtered = users
        .where((u) => filter.matches(u) && u.matchesSearch(query))
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        if (filtered.isEmpty)
          _InlineEmptyHint(onClear: onClearFilters)
        else
          for (final user in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _UserCard(
                user: user,
                onToggleActive: () => onToggleActive(user),
                onOpenDetails: onOpenUserDetails == null
                    ? null
                    : () => onOpenUserDetails!(user),
              ),
            ),
      ],
    );
  }
}

class _InlineEmptyHint extends StatelessWidget {
  const _InlineEmptyHint({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            AppIcons.noFilterMatch,
            size: AppIconSize.lg,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No users match your search or filter.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onToggleActive,
    this.onOpenDetails,
  });

  final AdminUserItem user;
  final VoidCallback onToggleActive;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final deactivated = user.status == AdminUserStatus.inactive;

    return GlassCard(
      // The whole card opens User Details — replaces the approved frame's
      // separate "Administrative actions" footer row (divider and all),
      // which didn't actually say anything a plain chevron doesn't already
      // say, and just added a second, redundant "tap for more" affordance
      // alongside the kebab menu's own. One tap target for details, one for
      // the quick inline action — not two competing for the same job.
      onTap: onOpenDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AppIconSize.lg / 2,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  user.initials,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<void>(
                icon: Icon(
                  AppIcons.more,
                  size: AppIconSize.md,
                  color: colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onToggleActive,
                    child: Text(
                      deactivated ? 'Reactivate account' : 'Deactivate account',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                // Wrap, not a plain Row: some role labels ("Municipal
                // Officer", "Ministry Supervisor") are long enough on a
                // narrow phone that forcing both pills onto one line would
                // overflow — letting the status pill flow to a second line
                // keeps everything readable instead. Its own row (full
                // card width, not squeezed next to the avatar) so it has
                // the room those longer labels need.
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Pill(
                      icon: user.role.icon,
                      label: user.role.label,
                      color: AppColors.primary,
                    ),
                    _Pill(label: user.status.label, color: user.status.color),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.label, required this.color});

  final IconData? icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(height: 24, width: 200),
        const SizedBox(height: AppSpacing.sm),
        block(height: 16, width: 260),
        const SizedBox(height: AppSpacing.md),
        block(height: 48, radius: 12),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            block(width: 56, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 80, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 64, height: 32, radius: 20),
            const SizedBox(width: AppSpacing.xs),
            block(width: 80, height: 32, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 6; i++) ...[
          block(height: 64, radius: 12),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
