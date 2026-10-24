import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/session_actions.dart' as session;
import 'confirm_dialog.dart';
import 'kebab_menu_button.dart';

Future<void> _confirmLogout(
  BuildContext context,
  Future<void> Function(BuildContext) endSession,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Log out?',
    message: "You'll need to sign back in to access CivicVoice.",
    confirmLabel: 'Log Out',
    destructive: true,
  );
  if (confirmed && context.mounted) await endSession(context);
}

/// Account actions retain the shared native popup positioning and motion.
class AccountMenuButton extends StatefulWidget {
  const AccountMenuButton({super.key, this.onProfile, this.onSignOut});
  final VoidCallback? onProfile;
  final Future<void> Function(BuildContext)? onSignOut;
  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton> {
  bool _pending = false;
  Future<void> _logout() async {
    if (_pending) return;
    setState(() => _pending = true);
    try {
      await _confirmLogout(context, widget.onSignOut ?? session.signOut);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: _pending,
    child: KebabMenuButton<String>(
      enabled: !_pending,
      tooltip: 'Account options',
      onSelected: (value) {
        if (value == 'profile') {
          widget.onProfile?.call();
        } else {
          _logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          enabled: widget.onProfile != null,
          child: const Row(
            children: [
              Icon(AppIcons.profile),
              SizedBox(width: AppSpacing.sm),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                AppIcons.logOut,
                color: AppSemanticColors.of(context).errorText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppSemanticColors.of(context).errorText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Pinned drawer action, sharing the profile page's confirmation and teardown.
class AccountLogoutButton extends StatefulWidget {
  const AccountLogoutButton({super.key, this.onSignOut});
  final Future<void> Function(BuildContext)? onSignOut;
  @override
  State<AccountLogoutButton> createState() => _AccountLogoutButtonState();
}

class _AccountLogoutButtonState extends State<AccountLogoutButton> {
  bool _pending = false;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      AppIcons.logOut,
      color: AppSemanticColors.of(context).errorText,
    ),
    title: Text(
      'Log Out',
      style: TextStyle(color: AppSemanticColors.of(context).errorText),
    ),
    enabled: !_pending,
    onTap: _pending
        ? null
        : () async {
            setState(() => _pending = true);
            try {
              await _confirmLogout(
                context,
                widget.onSignOut ?? session.signOut,
              );
            } finally {
              if (mounted) setState(() => _pending = false);
            }
          },
  );
}
