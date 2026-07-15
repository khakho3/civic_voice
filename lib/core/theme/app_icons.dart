/// Civic Glass Design System — Iconography Tokens.
///
/// Source: CivicVoice Design System Requirements §19.5 (Iconography System).
///
/// Rules enforced by these tokens (see source §19.5):
/// - Lucide is the only approved icon library; mixing icon libraries is
///   prohibited, so every icon in the app must be sourced from [AppIcons].
/// - Icons must always support the associated action or meaning and must not
///   be the sole indicator of meaning — pair with a label where clarity is
///   required (see §19.19 Accessibility Rules).
/// - Use [AppIconSize] for sizing; arbitrary icon sizes are prohibited.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Recommended icon sizes, in logical pixels — §19.5 "Recommended Icon Sizes".
abstract final class AppIconSize {
  const AppIconSize._();

  static const double sm = 16;
  static const double md = 20;
  static const double standard = 24;
  static const double lg = 32;
  static const double xl = 48;
}

/// Semantic Lucide icon tokens. Reference these by intent (e.g.
/// `AppIcons.reportSubmitted`) rather than importing `lucide_icons_flutter`
/// directly in feature code — this keeps the icon vocabulary centralized and
/// swappable from one place.
abstract final class AppIcons {
  const AppIcons._();

  // Navigation & chrome.
  static const IconData home = LucideIcons.house;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData menu = LucideIcons.menu;
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData close = LucideIcons.x;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsActive = LucideIcons.bellRing;
  static const IconData profile = LucideIcons.user;
  static const IconData settings = LucideIcons.settings;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData logOut = LucideIcons.logOut;

  // Common actions.
  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData camera = LucideIcons.camera;
  static const IconData upload = LucideIcons.upload;
  static const IconData download = LucideIcons.download;
  static const IconData copy = LucideIcons.copy;
  static const IconData share = LucideIcons.share2;
  static const IconData location = LucideIcons.mapPin;
  static const IconData myLocation = LucideIcons.crosshair;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData verify = LucideIcons.shieldCheck;

  // Report status — pair with the matching [AppColors] status color and a
  // text label; color/icon alone must never carry meaning (§19.3 Rule 3).
  static const IconData statusSubmitted = LucideIcons.sendHorizontal;
  static const IconData statusUnderReview = LucideIcons.clock;
  static const IconData statusAssigned = LucideIcons.userCheck;
  static const IconData statusInProgress = LucideIcons.loaderCircle;
  static const IconData statusResolved = LucideIcons.circleCheckBig;
  static const IconData statusRejected = LucideIcons.circleX;

  // Feedback & notification types — §19.17.
  static const IconData success = LucideIcons.circleCheck;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData info = LucideIcons.info;

  // State system — §19.18.
  static const IconData empty = LucideIcons.inbox;
  static const IconData offline = LucideIcons.wifiOff;
  static const IconData uploadFailed = LucideIcons.cloudOff;
  static const IconData imageUnavailable = LucideIcons.imageOff;
  static const IconData permissionDenied = LucideIcons.lock;

  // Forms & auth.
  static const IconData email = LucideIcons.mail;
  static const IconData password = LucideIcons.key;
  static const IconData phone = LucideIcons.phone;
  static const IconData visibilityOn = LucideIcons.eye;
  static const IconData visibilityOff = LucideIcons.eyeOff;
  static const IconData idCard = LucideIcons.idCard;

  // Role & module iconography (Screen Specifications Standard role prefixes).
  static const IconData citizen = LucideIcons.user;
  static const IconData municipalOfficer = LucideIcons.shieldCheck;
  static const IconData maintenanceTeam = LucideIcons.wrench;
  static const IconData ministrySupervisor = LucideIcons.landmark;
  static const IconData systemAdministrator = LucideIcons.building2;
  static const IconData team = LucideIcons.users;

  /// Same glyph as [ministrySupervisor] — the classic civic/government
  /// building silhouette (columns + dome) reads clearly as "a municipality"
  /// the way a generic office tower ([systemAdministrator]'s `building2`)
  /// doesn't; that one reads as a corporate/organization icon instead. Same
  /// reuse pattern as [citizen]/[profile] both aliasing the plain user icon.
  static const IconData municipality = LucideIcons.landmark;

  // Content & reporting.
  static const IconData report = LucideIcons.fileText;
  static const IconData reportVerified = LucideIcons.fileCheck2;
  static const IconData task = LucideIcons.clipboardList;
  static const IconData analytics = LucideIcons.barChart3;
  static const IconData badgeVerified = LucideIcons.badgeCheck;
  static const IconData criticalAlert = LucideIcons.octagonAlert;
  static const IconData navigate = LucideIcons.navigation;
  static const IconData pinned = LucideIcons.mapPinned;
  static const IconData rating = LucideIcons.star;
  static const IconData eta = LucideIcons.clock;
  static const IconData more = LucideIcons.ellipsisVertical;
  static const IconData sync = LucideIcons.refreshCcw;
  static const IconData chartBreakdown = LucideIcons.chartPie;
  static const IconData trendUp = LucideIcons.trendingUp;

  /// A document containing a small bar chart — "there's no report data to
  /// summarize yet", distinct from [empty] (a plain inbox, used for "no
  /// items in this list") since an analytics screen's empty state is about
  /// missing aggregate data, not a missing list.
  static const IconData noDataFile = LucideIcons.fileBarChart;

  /// A magnifying glass with an X — "your current filters exclude
  /// everything", distinct from [empty]/[noDataFile] (no data exists at
  /// all) since here the data exists but the active filter combination
  /// doesn't match any of it.
  static const IconData noFilterMatch = LucideIcons.searchX;

  static const IconData responseTime = LucideIcons.timer;
  static const IconData resolutionGauge = LucideIcons.gaugeCircle;
  static const IconData achievement = LucideIcons.trophy;
  static const IconData insight = LucideIcons.lightbulb;
  static const IconData pace = LucideIcons.zap;
  static const IconData focusArea = LucideIcons.target;
  static const IconData security = LucideIcons.lock;
  static const IconData language = LucideIcons.languages;
  static const IconData save = LucideIcons.save;

  // System Administrator module.
  static const IconData shield = LucideIcons.shield;
  static const IconData shieldAlert = LucideIcons.shieldAlert;
  static const IconData activityPulse = LucideIcons.activity;
  static const IconData roleManagement = LucideIcons.userCog;
  static const IconData activityLog = LucideIcons.history;
  static const IconData cloud = LucideIcons.cloud;
  static const IconData database = LucideIcons.database;
  static const IconData globe = LucideIcons.globe;
}
