import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_draft.dart';

/// A write-ahead receipt intent, separate from the editable authoring cache.
/// Never replace it after an uncertain response: the server may have saved it.
class ReportSubmissionStore {
  ReportSubmissionStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static final instance = ReportSubmissionStore();
  final Future<Directory> Function() _directory;
  final Map<String, Future<ReportDraft>> _preparing = {};

  String _key(String owner) => 'report_submission_v1_$owner';

  Future<ReportDraft?> pending(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(owner));
    if (raw == null) return null;
    // A damaged receipt is a blocking recovery problem, not a fresh intent.
    final draft = ReportDraft.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    if (draft.submissionKey == null ||
        !RegExp(r'^[a-zA-Z0-9_-]{16,128}$').hasMatch(draft.submissionKey!)) {
      throw const FormatException('Saved submission needs recovery.');
    }
    return draft;
  }

  Future<ReportDraft> prepare(String owner, ReportDraft draft) {
    final existing = _preparing[owner];
    if (existing != null) return existing;
    final task = _prepare(owner, draft);
    _preparing[owner] = task;
    return task.whenComplete(() => _preparing.remove(owner));
  }

  Future<ReportDraft> _prepare(String owner, ReportDraft draft) async {
    final saved = await pending(owner);
    if (saved != null) return saved;
    if (draft.photoPaths.length < 2 || draft.photoPaths.length > 5) {
      throw const FormatException('Add 2 to 5 photos before submitting.');
    }
    final random = Random.secure();
    final key = List.generate(
      24,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final root = await _directory();
    final folder = await Directory(
      '${root.path}/report_submissions/$key',
    ).create(recursive: true);
    var persisted = false;
    try {
      final photos = <String>[];
      for (var index = 0; index < draft.photoPaths.length; index++) {
        final source = File(draft.photoPaths[index]);
        if (await source.length() == 0) {
          throw const FormatException('A report photo is empty. Add it again.');
        }
        // Keep the extension for upload MIME detection; names never identify
        // the submission. Copies cannot be removed by editable-draft cleanup.
        final suffix =
            RegExp(r'\.[A-Za-z0-9]{1,8}$').firstMatch(source.path)?.group(0) ??
            '.jpg';
        photos.add((await source.copy('${folder.path}/$index$suffix')).path);
      }
      final frozen = draft.copyWith(photoPaths: photos, submissionKey: key);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key(owner), jsonEncode(frozen.toMap()))) {
        throw const FileSystemException('Could not save submission recovery.');
      }
      persisted = true;
      return frozen;
    } finally {
      if (!persisted) await folder.delete(recursive: true);
    }
  }

  Future<void> verifyEvidence(ReportDraft draft) async {
    if (draft.photoPaths.length < 2 || draft.photoPaths.length > 5) {
      throw const FormatException('Saved submission evidence needs recovery.');
    }
    for (final path in draft.photoPaths) {
      if (!await File(path).exists() || await File(path).length() == 0) {
        throw const FormatException(
          'A saved photo is missing. Check My Reports before trying another report.',
        );
      }
    }
  }

  /// Clears only the acknowledged owner's matching intent. File cleanup is
  /// best effort, and never follows paths read from preferences for deletion.
  Future<void> acknowledge(String owner, String key) async {
    final saved = await pending(owner);
    if (saved?.submissionKey != key) return;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_key(owner))) {
      throw const FileSystemException('Could not clear submission recovery.');
    }
    try {
      final root = await _directory();
      await Directory(
        '${root.path}/report_submissions/$key',
      ).delete(recursive: true);
    } on FileSystemException {
      // Orphaned private evidence must not turn a confirmed receipt into error.
    }
  }
}
