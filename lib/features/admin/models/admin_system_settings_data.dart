/// Fixed option list for ADM-007's one remaining dropdown field — a small,
/// closed set with no real-world source of truth to model as anything
/// richer than a plain string list.
const List<String> kSessionTimeoutOptions = [
  '15 minutes',
  '30 minutes',
  '60 minutes',
];

/// The outcome of a "Save Changes" attempt — separate from
/// [AdminSystemSettingsViewState] (the screen's own load state) the same
/// way Role Management's Validation/Success frames were kept out of its
/// top-level state enum: these are transient results of an in-place
/// interaction, not distinct ways the whole screen can render.
///
/// No [validationError] value — every field here is a switch or a
/// closed-set dropdown, always populated, so there's nothing left that
/// could ever actually fail validation. [failed] is reachable for real now
/// (a network error, or the backend 403ing a non-Super-Admin session) —
/// [AdminSystemSettingsScreen.initialSaveState] remains as a preview/test
/// hook for the same "Update Failed" copy, same as every other screen's
/// `initialState` mechanism, not the only way to reach it anymore.
enum SystemSettingsSaveState { idle, saving, saved, failed }

/// All the fields on ADM-007 System Settings.
///
/// The approved frame's "Platform Name" field was dropped entirely — this
/// app has exactly one deployment ("CivicVoice," the national platform
/// being pitched), so an editable platform name has no real admin who'd
/// ever need to touch it. If this ever becomes a genuinely white-labelled,
/// multi-deployment product, that's the point to reconsider adding it back.
///
/// Also dropped, in a later pass: "Default Language" (no per-field state
/// left to hold — genuinely inert everywhere, same as every module's
/// profile "Language" row, not just disabled-looking), "Enforce two-factor
/// authentication" (2FA is out of scope for this system entirely), "Audit
/// log retention"/"Backup schedule" (no real storage or server-side backup
/// process for either to govern — see the removed "Data Retention"
/// section's own history).
class SystemSettingsData {
  const SystemSettingsData({
    required this.maintenanceMode,
    required this.sessionTimeout,
    required this.auditLogging,
    required this.publicStatusPage,
    required this.allowNewAccountCreation,
  });

  /// Genuinely inert (`Switch.onChanged: null` on the screen, not just a
  /// "Coming Soon" badge next to a still-live control) — no maintenance-
  /// lockout feature exists yet to actually flip.
  final bool maintenanceMode;

  /// Real: [IdleSessionTimer] reads this to decide how long the app can
  /// sit untouched before signing the session out.
  final String sessionTimeout;

  /// Real: gates whether [AdminSystemActivityScreen] shows its activity
  /// feed at all, via [AdminSystemSettingsDirectory].
  final bool auditLogging;

  /// Genuinely inert, same caveat as [maintenanceMode] — no public status
  /// page exists yet.
  final bool publicStatusPage;

  /// Real: gates whether Admin Create User's form actually submits, via
  /// [AdminSystemSettingsDirectory].
  final bool allowNewAccountCreation;

  /// Builds from civic_voice_api's GET/PATCH /api/admin/settings response.
  /// maintenanceMode/publicStatusPage aren't part of that payload at all
  /// (see the class doc comment — no backend feature exists for either),
  /// so they keep the same fixed display values [mockSystemSettings] always
  /// used; only the three real fields actually come from the server.
  factory SystemSettingsData.fromApi(Map<String, dynamic> json) {
    return SystemSettingsData(
      maintenanceMode: false,
      sessionTimeout: json['sessionTimeout'] as String? ?? '30 minutes',
      auditLogging: json['auditLogging'] as bool? ?? true,
      publicStatusPage: true,
      allowNewAccountCreation: json['allowNewAccountCreation'] as bool? ?? true,
    );
  }

  SystemSettingsData copyWith({
    bool? maintenanceMode,
    String? sessionTimeout,
    bool? auditLogging,
    bool? publicStatusPage,
    bool? allowNewAccountCreation,
  }) {
    return SystemSettingsData(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      auditLogging: auditLogging ?? this.auditLogging,
      publicStatusPage: publicStatusPage ?? this.publicStatusPage,
      allowNewAccountCreation:
          allowNewAccountCreation ?? this.allowNewAccountCreation,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SystemSettingsData &&
      other.maintenanceMode == maintenanceMode &&
      other.sessionTimeout == sessionTimeout &&
      other.auditLogging == auditLogging &&
      other.publicStatusPage == publicStatusPage &&
      other.allowNewAccountCreation == allowNewAccountCreation;

  @override
  int get hashCode => Object.hash(
    maintenanceMode,
    sessionTimeout,
    auditLogging,
    publicStatusPage,
    allowNewAccountCreation,
  );
}

/// Placeholder content matching the approved ADM-007 design, used until a
/// real settings service is wired up.
SystemSettingsData mockSystemSettings() {
  return const SystemSettingsData(
    maintenanceMode: false,
    sessionTimeout: '30 minutes',
    auditLogging: true,
    publicStatusPage: true,
    allowNewAccountCreation: true,
  );
}
