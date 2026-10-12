import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The small avatar-mounted Profile edit pencil: a 24px gold disc with a
/// 16px dark-ink pencil, inside a full 48px touch target. The only edit
/// entry on a Profile — there is no duplicate kebab/menu edit command.
class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  /// How far the 48px touch target extends past the 24px disc on each side.
  static const double hitOverhang =
      (AppDimensions.controlHeightStandard - AppIconSize.standard) / 2;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final enabled = onPressed != null;
    return Tooltip(
      message: 'Edit profile',
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Edit profile',
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppDimensions.controlHeightStandard,
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onPressed,
              radius: AppDimensions.controlHeightStandard / 2,
              child: Center(
                child: Container(
                  width: AppIconSize.standard,
                  height: AppIconSize.standard,
                  decoration: BoxDecoration(
                    color: enabled
                        ? semantic.actionFill
                        : Theme.of(context).colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.edit,
                    size: AppIconSize.sm,
                    color: enabled
                        ? semantic.onAction
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
