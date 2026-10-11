import 'package:civic_voice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('brand action fills retain an accessible dark ink foreground', () {
    expect(
      _contrastRatio(AppColors.onPrimary, AppColors.primary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(AppColors.onPrimary, AppColors.primaryDark),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('light and dark themes use the approved charcoal and gold tokens', () {
    expect(AppColorsLight.canvas, const Color(0xFFFAFAF7));
    expect(AppColorsDark.canvas, const Color(0xFF101110));
    expect(AppColors.primary, const Color(0xFFFCD116));
    expect(AppColors.primaryDark, const Color(0xFFFFD84D));
    expect(AppColors.onPrimary, const Color(0xFF241C06));
  });

  test('outlined actions and focused inputs use the approved gold emphasis', () {
    expect(AppColors.controlBorder, const Color(0xFF82755B));
    expect(AppColors.focus, const Color(0xFF765400));
    expect(AppColors.primaryDark, const Color(0xFFFFD84D));
  });
}
