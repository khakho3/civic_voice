import 'package:flutter/foundation.dart';

import '../models/dashboard_view_state.dart';

class DashboardStateService {
  DashboardStateService._();

  static final DashboardStateService instance = DashboardStateService._();

  final ValueNotifier<DashboardViewState> state =
      ValueNotifier<DashboardViewState>(DashboardViewState.empty);

  void setState(DashboardViewState nextState) {
    state.value = nextState;
  }

  void reset() {
    state.value = DashboardViewState.empty;
  }
}
