import 'package:flutter/material.dart';

import '../../../core/navigation/tab_route.dart';
import '../../../services/session_actions.dart';
import 'citizen_alerts_screen.dart';
import 'citizen_dashboard_screen.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';

/// The soft-crossfade [tabRoute] for each Citizen bottom-nav destination —
/// every screen's own `onDestinationSelected` needs the exact same five
/// widget constructions (only Profile's `onLogOut` wiring makes that
/// non-trivial), so they're defined once here instead of nine times.
Route<void> citizenDashboardTabRoute(BuildContext context) => tabRoute(
  context,
  (_) => const CitizenDashboardScreen(),
  routeName: CitizenDashboardScreen.routeName,
);

Route<void> citizenReportsTabRoute(BuildContext context) => tabRoute(
  context,
  (_) => const CitizenReportsScreen(),
  routeName: CitizenReportsScreen.routeName,
);

Route<void> citizenCreateReportTabRoute(BuildContext context) => tabRoute(
  context,
  (_) => const CreateReportScreen(),
  routeName: CreateReportScreen.routeName,
);

Route<void> citizenAlertsTabRoute(BuildContext context) => tabRoute(
  context,
  (_) => const CitizenAlertsScreen(),
  routeName: CitizenAlertsScreen.routeName,
);

Route<void> citizenProfileTabRoute(BuildContext context) => tabRoute(
  context,
  (profileContext) => CitizenProfileScreen(
    onAbout: () => Navigator.of(profileContext).pushNamed('/about'),
    onRegister: () => Navigator.of(profileContext).pushNamed('/registration'),
    onLogOut: () => signOut(profileContext),
  ),
  routeName: CitizenProfileScreen.routeName,
);
