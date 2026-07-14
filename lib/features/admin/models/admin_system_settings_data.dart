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
const List<String> kRegionOptions = [
  'Default region',
  'EU region',
  'US region',
];

/// The outcome of a "Save Changes" attempt — separate from
/// [AdminSystemSettingsViewState] (the screen's own load state) the same
/// way Role Management's Validation/Success frames were kept out of its
/// top-level state enum: these are transient results of an in-place
/// interaction, not distinct ways the whole screen can render.
///
/// [failed] has no reachable trigger through normal interaction — there's
/// no backend here to actually fail a save against — so, like every other
/// screen's `initialState` preview mechanism, it's only reachable via
/// [AdminSystemSettingsScreen.initialSaveState] for building/testing the
/// approved frame's "Update Failed" copy.
enum SystemSettingsSaveState { idle, saving, saved, failed, validationError }

/// All the fields on ADM-007 System Settings. The approved frame styles
/// "Platform Name" as a dropdown, but it's a name, not a choice from a
/// fixed set — modeled as free text instead, which also makes the
/// export's own "Platform name is required" validation copy meaningful
/// (a dropdown, always populated, can never actually be empty).
class SystemSettingsData {
  const SystemSettingsData({
    required this.platformName,
    required this.defaultLanguage,
    required this.maintenanceMode,
    required this.enforceTwoFactor,
    required this.sessionTimeout,
    required this.auditLogging,
    required this.auditLogRetention,
    required this.backupSchedule,
    required this.publicStatusPage,
    required this.regionalDataRouting,
  });

  final String platformName;
  final String defaultLanguage;
  final bool maintenanceMode;
  final bool enforceTwoFactor;
  final String sessionTimeout;
  final bool auditLogging;
  final String auditLogRetention;
  final String backupSchedule;
  final bool publicStatusPage;
  final String regionalDataRouting;

  SystemSettingsData copyWith({
    String? platformName,
    String? defaultLanguage,
    bool? maintenanceMode,
    bool? enforceTwoFactor,
    String? sessionTimeout,
    bool? auditLogging,
    String? auditLogRetention,
    String? backupSchedule,
    bool? publicStatusPage,
    String? regionalDataRouting,
  }) {
    return SystemSettingsData(
      platformName: platformName ?? this.platformName,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      enforceTwoFactor: enforceTwoFactor ?? this.enforceTwoFactor,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      auditLogging: auditLogging ?? this.auditLogging,
      auditLogRetention: auditLogRetention ?? this.auditLogRetention,
      backupSchedule: backupSchedule ?? this.backupSchedule,
      publicStatusPage: publicStatusPage ?? this.publicStatusPage,
      regionalDataRouting: regionalDataRouting ?? this.regionalDataRouting,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SystemSettingsData &&
      other.platformName == platformName &&
      other.defaultLanguage == defaultLanguage &&
      other.maintenanceMode == maintenanceMode &&
      other.enforceTwoFactor == enforceTwoFactor &&
      other.sessionTimeout == sessionTimeout &&
      other.auditLogging == auditLogging &&
      other.auditLogRetention == auditLogRetention &&
      other.backupSchedule == backupSchedule &&
      other.publicStatusPage == publicStatusPage &&
      other.regionalDataRouting == regionalDataRouting;

  @override
  int get hashCode => Object.hash(
    platformName,
    defaultLanguage,
    maintenanceMode,
    enforceTwoFactor,
    sessionTimeout,
    auditLogging,
    auditLogRetention,
    backupSchedule,
    publicStatusPage,
    regionalDataRouting,
  );
}

/// Placeholder content matching the approved ADM-007 design, used until a
/// real settings service is wired up.
SystemSettingsData mockSystemSettings() {
  return const SystemSettingsData(
    platformName: 'CivicVoice',
    defaultLanguage: 'English',
    maintenanceMode: false,
    enforceTwoFactor: true,
    sessionTimeout: '30 minutes',
    auditLogging: true,
    auditLogRetention: '12 months',
    backupSchedule: 'Daily',
    publicStatusPage: true,
    regionalDataRouting: 'Default region',
  );
}
