/// Fixed option lists for ADM-007's dropdown fields — small, closed sets
/// with no real-world source of truth to model as anything richer than a
/// plain string list (unlike [AppRole]/[AdminTier], which gate real
/// behavior elsewhere in the app, these are purely cosmetic mock choices).
const List<String> kLanguageOptions = ['English', 'French', 'Spanish'];
const List<String> kSessionTimeoutOptions = [
  '15 minutes',
  '30 minutes',
  '60 minutes',
];
const List<String> kAuditLogRetentionOptions = [
  '3 months',
  '6 months',
  '12 months',
  '24 months',
];
const List<String> kBackupScheduleOptions = ['Daily', 'Weekly', 'Monthly'];

/// The outcome of a "Save Changes" attempt — separate from
/// [AdminSystemSettingsViewState] (the screen's own load state) the same
/// way Role Management's Validation/Success frames were kept out of its
/// top-level state enum: these are transient results of an in-place
/// interaction, not distinct ways the whole screen can render.
///
/// No [validationError] value — every field here is a switch or a
/// closed-set dropdown, always populated, so there's nothing left that
/// could ever actually fail validation (the one free-text field that
/// could, "Platform Name," was dropped — see [SystemSettingsData]'s own
/// doc comment). [failed] itself has no reachable trigger through normal
/// interaction either — there's no backend here to actually fail a save
/// against — so, like every other screen's `initialState` preview
/// mechanism, it's only reachable via
/// [AdminSystemSettingsScreen.initialSaveState] for building/testing the
/// "Update Failed" copy.
enum SystemSettingsSaveState { idle, saving, saved, failed }

/// All the fields on ADM-007 System Settings.
///
/// The approved frame's "Platform Name" field was dropped entirely — this
/// app has exactly one deployment ("CivicVoice," the national platform
/// being pitched), so an editable platform name has no real admin who'd
/// ever need to touch it. If this ever becomes a genuinely white-labelled,
/// multi-deployment product, that's the point to reconsider adding it back.
class SystemSettingsData {
  const SystemSettingsData({
    required this.defaultLanguage,
    required this.maintenanceMode,
    required this.enforceTwoFactor,
    required this.sessionTimeout,
    required this.auditLogging,
    required this.auditLogRetention,
    required this.backupSchedule,
    required this.publicStatusPage,
  });

  final String defaultLanguage;

  /// Not yet backed by anything — flipping it doesn't actually restrict
  /// access anywhere in the app (that would mean a real platform-wide
  /// lockout banner/gate, a separate feature of its own). Rendered with a
  /// "Coming Soon" badge rather than presented as live — see
  /// [AdminSystemSettingsScreen]'s own doc comment.
  final bool maintenanceMode;
  final bool enforceTwoFactor;
  final String sessionTimeout;
  final bool auditLogging;
  final String auditLogRetention;
  final String backupSchedule;

  /// Same "not yet backed by anything real" caveat as [maintenanceMode] —
  /// there's no actual public status page in this app yet.
  final bool publicStatusPage;

  SystemSettingsData copyWith({
    String? defaultLanguage,
    bool? maintenanceMode,
    bool? enforceTwoFactor,
    String? sessionTimeout,
    bool? auditLogging,
    String? auditLogRetention,
    String? backupSchedule,
    bool? publicStatusPage,
  }) {
    return SystemSettingsData(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      enforceTwoFactor: enforceTwoFactor ?? this.enforceTwoFactor,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      auditLogging: auditLogging ?? this.auditLogging,
      auditLogRetention: auditLogRetention ?? this.auditLogRetention,
      backupSchedule: backupSchedule ?? this.backupSchedule,
      publicStatusPage: publicStatusPage ?? this.publicStatusPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SystemSettingsData &&
      other.defaultLanguage == defaultLanguage &&
      other.maintenanceMode == maintenanceMode &&
      other.enforceTwoFactor == enforceTwoFactor &&
      other.sessionTimeout == sessionTimeout &&
      other.auditLogging == auditLogging &&
      other.auditLogRetention == auditLogRetention &&
      other.backupSchedule == backupSchedule &&
      other.publicStatusPage == publicStatusPage;

  @override
  int get hashCode => Object.hash(
    defaultLanguage,
    maintenanceMode,
    enforceTwoFactor,
    sessionTimeout,
    auditLogging,
    auditLogRetention,
    backupSchedule,
    publicStatusPage,
  );
}

/// Placeholder content matching the approved ADM-007 design, used until a
/// real settings service is wired up.
SystemSettingsData mockSystemSettings() {
  return const SystemSettingsData(
    defaultLanguage: 'English',
    maintenanceMode: false,
    enforceTwoFactor: true,
    sessionTimeout: '30 minutes',
    auditLogging: true,
    auditLogRetention: '12 months',
    backupSchedule: 'Daily',
    publicStatusPage: true,
  );
}
