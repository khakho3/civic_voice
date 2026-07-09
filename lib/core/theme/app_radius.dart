/// Civic Glass Design System — Corner Radius Tokens.
///
/// Source: CivicVoice Design System Requirements §19.7 (Radius System).
///
/// Rounded corners create the "soft and approachable" Civic Glass interface.
/// Always build [BorderRadius] from [AppRadius] — never a raw numeric literal.
library;

import 'package:flutter/widgets.dart';

/// Radius scale, in logical pixels — §19.7 "Radius Tokens".
abstract final class AppRadius {
  const AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);

  static const BorderRadius allXs = BorderRadius.all(radiusXs);
  static const BorderRadius allSm = BorderRadius.all(radiusSm);
  static const BorderRadius allMd = BorderRadius.all(radiusMd);
  static const BorderRadius allLg = BorderRadius.all(radiusLg);
  static const BorderRadius allXl = BorderRadius.all(radiusXl);
}

/// Component-to-radius mapping — §19.7 "Recommended Usage". Reference these
/// (not [AppRadius] directly) when styling the named component so the
/// mapping stays discoverable and centralized.
abstract final class AppComponentRadius {
  const AppComponentRadius._();

  static const BorderRadius button = AppRadius.allSm; // 12px
  static const BorderRadius inputField = AppRadius.allSm; // 12px
  static const BorderRadius card = AppRadius.allMd; // 16px
  static const BorderRadius dialog = AppRadius.allLg; // 20px
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: AppRadius.radiusXl,
    topRight: AppRadius.radiusXl,
  ); // 24px, top corners only
}
