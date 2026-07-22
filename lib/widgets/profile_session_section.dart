import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'profile_section.dart';

/// The shared profile sign-out group. Keeping Log Out in its own Session
/// section prevents it from competing visually with password and preference
/// controls.
class ProfileSessionSection extends StatelessWidget {
  const ProfileSessionSection({
    super.key,
    required this.onLogOut,
    this.details = const <Widget>[],
  });

  final VoidCallback? onLogOut;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      icon: AppIcons.shield,
      title: 'Session',
      children: [
        ...details,
        if (details.isNotEmpty) const Divider(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLogOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: const Text('Log Out'),
          ),
        ),
      ],
    );
  }
}
