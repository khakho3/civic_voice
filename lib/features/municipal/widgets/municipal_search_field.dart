import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shared search-field shape for every Municipal Officer list screen
/// (Incoming Reports, Active Reports, Assign Team's team list, and any
/// future screen that needs one).
///
/// Deliberately uses only the app theme's `InputDecorationTheme` — no
/// per-instance `border`/`fillColor` overrides — so every search bar in the
/// module looks identical (same 12px radius, same fill, same focus/error
/// treatment) without each screen having to remember to match the others by
/// hand. Add new search UI here, not by copy-pasting a `TextField`.
class MunicipalSearchField extends StatelessWidget {
  const MunicipalSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.trailing,
  });

  final TextEditingController? controller;
  final String hintText;
  final bool enabled;

  /// An additional action shown alongside the built-in clear button (e.g.
  /// Active Reports' sort/filter shortcut) — not a substitute for it.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    return ListenableBuilder(
      listenable: controller ?? _staticListenable,
      builder: (context, _) {
        return TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(AppIcons.search, size: AppIconSize.md),
            suffixIcon: _buildSuffix(controller),
          ),
        );
      },
    );
  }

  Widget? _buildSuffix(TextEditingController? controller) {
    final hasClear = controller != null && controller.text.isNotEmpty;
    if (trailing == null && !hasClear) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?trailing,
        if (hasClear)
          IconButton(
            icon: const Icon(AppIcons.close, size: AppIconSize.md),
            onPressed: controller.clear,
          ),
      ],
    );
  }
}

/// A no-op [Listenable] to satisfy [ListenableBuilder] when [controller] is
/// null (e.g. a Loading state rendering a non-interactive placeholder).
final _staticListenable = _NeverNotifies();

class _NeverNotifies extends ChangeNotifier {}
