import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';
import 'busy_indicator.dart';
import 'confirm_dialog.dart';
import 'motion_feedback.dart';

/// Opens the shared, permission-scoped Profile editor (P02) and resolves to
/// whether a save succeeded.
///
/// It edits only the display name. Phones, roles, jurisdictions, team and
/// credentials stay owned by each role's administrator/backend rules and
/// are never offered here.
///
/// [onSave] persists the trimmed name and returns whether it succeeded;
/// a thrown error counts as failure. A failed save keeps the sheet open
/// with the entered name and an error, so nothing is lost. While saving,
/// Back and the barrier cannot dismiss the sheet. With [confirmDiscard],
/// leaving with unsaved changes asks first. [showValidationOnOpen] opens
/// with the empty-name error already shown (the approved Error preview).
Future<bool> showProfileNameEditSheet(
  BuildContext context, {
  required String initialName,
  required Future<bool> Function(String name) onSave,
  bool confirmDiscard = false,
  bool showValidationOnOpen = false,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ProfileNameEditSheet(
      initialName: initialName,
      onSave: onSave,
      confirmDiscard: confirmDiscard,
      showValidationOnOpen: showValidationOnOpen,
    ),
  );
  return saved ?? false;
}

class ProfileNameEditSheet extends StatefulWidget {
  const ProfileNameEditSheet({
    super.key,
    required this.initialName,
    required this.onSave,
    this.confirmDiscard = false,
    this.showValidationOnOpen = false,
  });

  final String initialName;
  final Future<bool> Function(String name) onSave;
  final bool confirmDiscard;
  final bool showValidationOnOpen;

  @override
  State<ProfileNameEditSheet> createState() => _ProfileNameEditSheetState();
}

class _ProfileNameEditSheetState extends State<ProfileNameEditSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  final FocusNode _nameFocus = FocusNode();
  bool _saving = false;
  late String? _fieldError = widget.showValidationOnOpen
      ? _requiredMessage
      : null;
  bool _saveFailed = false;

  static const _requiredMessage = 'Full name is required.';
  int _shakes = 0;

  bool get _dirty => _nameController.text.trim() != widget.initialName.trim();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    AppHaptics.activate();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _fieldError = _requiredMessage;
        _saveFailed = false;
        _shakes++;
      });
      // First (and only) invalid field takes focus so the keyboard opens
      // on the thing to fix.
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _saving = true;
      _fieldError = null;
      _saveFailed = false;
    });
    bool ok;
    try {
      ok = await widget.onSave(name);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _saveFailed = true;
    });
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if (widget.confirmDiscard && _dirty) {
      final discard = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your unsaved profile changes will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!discard || !mounted) return;
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final initials = _nameController.text
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    return PopScope(
      // Back/barrier route through _cancel so saving and dirty states are
      // respected; the result is decided there.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: AppIconSize.xl,
                      height: AppIconSize.xl,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: semantic.actionFill.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: textTheme.titleMedium?.copyWith(
                          color: semantic.actionText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Edit profile',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          'Update the details you control.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_saveFailed) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: semantic.error.withValues(alpha: 0.10),
                      borderRadius: AppRadius.allSm,
                      border: Border.all(
                        color: semantic.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.warning,
                          size: AppIconSize.md,
                          color: semantic.errorText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Changes not saved. Check your connection and '
                            'try again.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ErrorShake(
                trigger: _shakes == 0 ? null : _shakes,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.profileRowSurface,
                    borderRadius: AppRadius.allMd,
                    border: Border.all(
                      color: _fieldError != null
                          ? semantic.error
                          : colorScheme.outline,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    // No soft keyboard on open: the person chooses to edit.
                    autofocus: false,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      errorText: _fieldError,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: semantic.focus,
                          width: AppDimensions.borderWidthFocused,
                        ),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: semantic.error),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: semantic.error,
                          width: AppDimensions.borderWidthFocused,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {
                      _fieldError = null;
                      _saveFailed = false;
                    }),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: BusyLabel(
                  busy: _saving,
                  busyLabel: 'Saving changes',
                  child: const Text('Save changes'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _saving ? null : _cancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
