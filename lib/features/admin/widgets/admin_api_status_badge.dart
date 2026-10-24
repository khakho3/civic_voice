import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/admin_system_activity_data.dart';

/// The compact dashboard health badge. Sample state is explicit; live callers
/// supply only verified health. Reduced motion keeps the glow static.
class AdminApiStatusBadge extends StatefulWidget {
  const AdminApiStatusBadge({
    super.key,
    required this.stats,
    this.sample = false,
    this.onTap,
  });

  final SystemHealthStats? stats;
  final bool sample;
  final VoidCallback? onTap;

  @override
  State<AdminApiStatusBadge> createState() => _AdminApiStatusBadgeState();
}

class _AdminApiStatusBadgeState extends State<AdminApiStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  void _syncMotion() {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final online =
        !widget.sample &&
        widget.stats?.apiOnline == true &&
        widget.stats?.databaseOnline == true;
    if (online && !reduced) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AdminApiStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final live = !widget.sample;
    final online = stats?.apiOnline == true && stats?.databaseOnline == true;
    final unavailable = stats == null;
    final color = unavailable || !live
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : online
        ? AppSemanticColors.of(context).successText
        : AppSemanticColors.of(context).errorText;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final pulse = live && online && !reduceMotion
                      ? Curves.easeInOut.transform(_controller.value)
                      : 0.0;
                  return SizedBox(
                    width: 14,
                    height: 14,
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + pulse * 0.18,
                        child: Container(
                          key: const ValueKey('admin-api-status-dot'),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: live && online
                                      ? 0.2 + pulse * 0.25
                                      : 0,
                                ),
                                blurRadius: 4 + pulse * 6,
                                spreadRadius: live && online
                                    ? 1 + pulse * 4
                                    : 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'API: ${unavailable
                    ? 'Unavailable'
                    : !live
                    ? 'Sample'
                    : online
                    ? 'Online'
                    : 'Offline'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
