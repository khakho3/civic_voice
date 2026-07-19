import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/citizen/models/report_draft.dart';

/// Small, device-local persistence for UX state that must survive navigation
/// and process restarts. Authentication credentials remain Firebase's job.
class AppCacheService {
  AppCacheService._();

  static final instance = AppCacheService._();

  static const _onboardingCompleteKey = 'onboarding_complete_v1';
  static const _reportDraftKey = 'citizen_report_draft_v1';

  SharedPreferences? _preferences;
  ReportDraft? _reportDraft;

  bool get onboardingComplete =>
      _preferences?.getBool(_onboardingCompleteKey) ?? false;
  ReportDraft? get reportDraft => _reportDraft;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _reportDraft = null;
    final encoded = _preferences?.getString(_reportDraftKey);
    if (encoded == null) return;
    try {
      final decoded = ReportDraft.fromMap(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      final existingPhotos = <String>[];
      for (final path in decoded.photoPaths) {
        if (await File(path).exists()) existingPhotos.add(path);
      }
      _reportDraft = decoded.copyWith(photoPaths: existingPhotos);
      if (existingPhotos.length != decoded.photoPaths.length) {
        await _preferences?.setString(
          _reportDraftKey,
          jsonEncode(_reportDraft!.toMap()),
        );
      }
    } catch (_) {
      await _preferences?.remove(_reportDraftKey);
    }
  }

  Future<void> markOnboardingComplete() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setBool(_onboardingCompleteKey, true);
  }

  Future<void> saveReportDraft(ReportDraft draft) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    _reportDraft = draft;
    await preferences.setString(_reportDraftKey, jsonEncode(draft.toMap()));
  }

  Future<ReportDraft> saveReportPhotos(
    ReportDraft draft,
    List<String> sourcePaths,
  ) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final photoDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}report_draft_photos',
    );
    await photoDirectory.create(recursive: true);

    final persisted = <String>[];
    for (var index = 0; index < sourcePaths.length; index++) {
      final source = File(sourcePaths[index]);
      if (!await source.exists()) continue;
      if (source.path.startsWith(photoDirectory.path)) {
        persisted.add(source.path);
        continue;
      }
      final extensionIndex = source.path.lastIndexOf('.');
      final extension = extensionIndex < 0
          ? '.jpg'
          : source.path.substring(extensionIndex);
      final target = File(
        '${photoDirectory.path}${Platform.pathSeparator}'
        '${DateTime.now().microsecondsSinceEpoch}_$index$extension',
      );
      await source.copy(target.path);
      persisted.add(target.path);
    }

    final retained = persisted.toSet();
    for (final oldPath in _reportDraft?.photoPaths ?? const <String>[]) {
      if (!retained.contains(oldPath) &&
          oldPath.startsWith(photoDirectory.path)) {
        try {
          await File(oldPath).delete();
        } catch (_) {
          // An OS cache cleanup may already have removed it.
        }
      }
    }

    final saved = draft.copyWith(photoPaths: persisted);
    await saveReportDraft(saved);
    return saved;
  }

  Future<void> clearReportDraft() async {
    final cachedPaths = _reportDraft?.photoPaths ?? const <String>[];
    _reportDraft = null;
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.remove(_reportDraftKey);
    for (final path in cachedPaths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Submission succeeded; stale cache cleanup must never block routing.
      }
    }
  }
}
