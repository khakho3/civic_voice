import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shared, permission-scoped Profile editor. It deliberately exposes only a
/// display name: phones, roles, jurisdictions, and credentials remain owned
/// by their existing native rules rather than a generic profile form.
class ProfileNameEditSheet extends StatefulWidget {
  const ProfileNameEditSheet({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final Future<void> Function(String name) onSave;

  @override
  State<ProfileNameEditSheet> createState() => _ProfileNameEditSheetState();
}

class _ProfileNameEditSheetState extends State<ProfileNameEditSheet> {
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Enter your name.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(name);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = 'Unable to save your changes. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        insets.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              autofocus: false,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
