import 'package:flutter/foundation.dart';

import '../models/admin_system_settings_data.dart';

/// Real, process-wide source of truth for ADM-007 System Settings — a
/// `ValueNotifier` singleton, the same pattern as every other `*Directory`
/// in this app. Promoted out of [AdminSystemSettingsScreen]'s own screen-
/// local `_original`/`_draft` state, which reset back to
/// [mockSystemSettings] every time the screen was left and reopened —
/// "Save Changes" not surviving navigating away was a real bug, not just a
/// cosmetic one, since [AdminSystemActivityScreen]'s audit-logging gate
/// and [IdleSessionTimer]'s session-timeout duration both need to read the
/// same saved settings from anywhere in the app, not just while this
/// screen happens to be mounted.
class AdminSystemSettingsDirectory {
  AdminSystemSettingsDirectory._();

  static final AdminSystemSettingsDirectory instance =
      AdminSystemSettingsDirectory._();

  final ValueNotifier<SystemSettingsData> settings = ValueNotifier(
    mockSystemSettings(),
  );
}
