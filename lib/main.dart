import 'package:flutter/material.dart';

import 'app/civic_voice_app.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadSavedTheme();
  runApp(const CivicVoiceApp());
}
