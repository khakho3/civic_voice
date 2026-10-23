import 'dart:io';

import '../../../services/api_client.dart';
import '../models/maintenance_task.dart';

typedef MaintenanceUpdate =
    Future<Map<String, dynamic>> Function(
      String id,
      Map<String, String> fields,
      List<String> photos,
    );

/// One in-flight write per task. Server responses, not local selections, own
/// the resulting lifecycle. Auth/team ownership is rechecked by the caller.
class MaintenanceUpdateService {
  final Set<String> _saving = {};

  bool _hasNewEvidence(MaintenanceTask task, Object? value) {
    if (value is! List ||
        value.length != task.resolutionPhotoUrls.length + 3 ||
        value.any((url) => url is! String || url.trim().isEmpty)) {
      return false;
    }
    // The API appends evidence on each send-back/resubmission cycle. Historic
    // photos must stay intact, and cannot substitute for the three new ones.
    final urls = value.cast<String>().map(ApiClient.assetUrl).toList();
    for (var i = 0; i < task.resolutionPhotoUrls.length; i++) {
      if (urls[i] != task.resolutionPhotoUrls[i]) return false;
    }
    final added = urls.skip(task.resolutionPhotoUrls.length).toSet();
    return added.length == 3 && !added.any(task.resolutionPhotoUrls.contains);
  }

  static Future<void> validate({
    required MaintenanceTaskStatus status,
    required String notes,
    required List<String> photos,
    bool checkFiles = true,
  }) async {
    if (notes.length > 2000) {
      throw const FormatException(
        'Work notes must be at most 2000 characters.',
      );
    }
    if ((status == MaintenanceTaskStatus.completed ||
            status == MaintenanceTaskStatus.failed) &&
        notes.trim().length < 10) {
      throw const FormatException(
        'Describe the work or field issue in at least 10 characters.',
      );
    }
    if (status != MaintenanceTaskStatus.completed) return;
    if (photos.length != 3 || photos.toSet().length != 3) {
      throw const FormatException(
        'Attach three new completion evidence photos.',
      );
    }
    // The Firebase-free design preview has synthetic image paths. Live saves
    // always check the actual files before sending either workflow request.
    if (!checkFiles) return;
    for (final path in photos) {
      if (!RegExp(
        r'\.(jpe?g|png|webp|heic|heif)$',
        caseSensitive: false,
      ).hasMatch(path)) {
        throw const FormatException('Choose supported completion photo files.');
      }
      try {
        final file = File(path);
        final size = await file.length();
        if (size <= 0 || size > 10 * 1024 * 1024) {
          throw const FormatException(
            'Each completion photo must be nonempty and at most 10 MB.',
          );
        }
      } on FileSystemException {
        throw const FormatException(
          'A completion photo is missing. Add it again.',
        );
      }
    }
  }

  Future<MaintenanceTask> save(
    MaintenanceTask task, {
    required MaintenanceTaskStatus status,
    required String notes,
    required List<String> photos,
    required MaintenanceUpdate update,
    required void Function() checkOwnership,
  }) async {
    final id = task.apiId ?? task.id;
    if (!task.needsEvidence ||
        status == MaintenanceTaskStatus.pendingApproval) {
      throw StateError('This task cannot accept this update. Refresh Tasks.');
    }
    if (!_saving.add(id)) throw StateError('This task is already being saved.');
    try {
      final frozenPhotos = List<String>.unmodifiable(photos);
      await validate(status: status, notes: notes, photos: frozenPhotos);
      checkOwnership();
      Future<MaintenanceTask> send(
        Map<String, String> fields,
        List<String> files,
      ) async {
        checkOwnership();
        final result = await update(id, fields, files);
        checkOwnership();
        final evidence = result['resolutionPhotoUrls'];
        if (result['id'] != id ||
            result['assignedTeamId'] != task.teamId ||
            result['status'] != fields['status'] ||
            (fields['status'] == 'PENDING_APPROVAL' &&
                (result['progressPercent'] != 100 ||
                    result['resolutionNotes'] != notes.trim() ||
                    !_hasNewEvidence(task, evidence)))) {
          throw const ApiException(
            statusCode: 502,
            message: 'Task update was not confirmed. Refresh Tasks.',
          );
        }
        return MaintenanceTask.fromApi(result);
      }

      final submitting = status == MaintenanceTaskStatus.completed;
      if (submitting && task.status == MaintenanceTaskStatus.assigned) {
        await send(const {'status': 'IN_PROGRESS'}, const []);
      }
      return await send({
        'status': submitting ? 'PENDING_APPROVAL' : 'IN_PROGRESS',
        if (submitting) ...{
          'progressPercent': '100',
          'resolutionNotes': notes.trim(),
          'maintenanceFailureNotes': '',
        } else if (status == MaintenanceTaskStatus.failed)
          'maintenanceFailureNotes': notes.trim()
        else if (notes.trim().isNotEmpty)
          'resolutionNotes': notes.trim(),
      }, submitting ? frozenPhotos : const []);
    } finally {
      _saving.remove(id);
    }
  }
}
