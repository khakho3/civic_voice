import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shared search-field shape for every Municipal Officer list screen
/// (Incoming Reports, Active Reports, Assign Team's team list, and any
/// future screen that needs one).
///
/// Otherwise uses only the app theme's `InputDecorationTheme` (border,
/// radius, focus/error treatment) — no per-instance overrides beyond the
/// one deliberate exception below — so every search bar in the module
/// looks identical without each screen having to remember to match the
/// others by hand. Add new search UI here, not by copy-pasting a
/// `TextField`.
///
/// [fillColor] is the one exception: §19.10 Glass Usage Rules names
/// "search containers" as a permitted glass surface, but the app's global
/// `inputDecorationTheme` can't be made glass itself — that same theme
/// backs every actual form field too (login, registration, report
/// details), and glass is explicitly *prohibited* on input-heavy forms.
/// So this search field carries its own `AppColorsLight/Dark.glassSurface`
/// fill instead of inheriting the form fill, rather than the global theme
/// trying to serve both permitted and prohibited surfaces at once.
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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
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
            filled: true,
            fillColor: semantic.glassSurface,
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
