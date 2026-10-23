import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_update_service.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenanceTask task({String status = 'IN_PROGRESS'}) =>
    MaintenanceTask.fromApi({
      'id': 'task-id',
      'publicReference': 'CV-TEST',
      'status': status,
      'assignedTeamId': 'team-id',
    });
Map<String, dynamic> receipt(String status) => {
  'id': 'task-id',
  'publicReference': 'CV-TEST',
  'status': status,
  'assignedTeamId': 'team-id',
  if (status == 'PENDING_APPROVAL') ...{
    'progressPercent': 100,
    'resolutionNotes': 'Completed repairs.',
    'resolutionPhotoUrls': [
      '/uploads/resolutions/a.jpg',
      '/uploads/resolutions/b.jpg',
      '/uploads/resolutions/c.jpg',
    ],
  },
};
void main() {
  late Directory directory;
  late List<String> photos;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cv-completion-');
    photos = [
      for (var i = 0; i < 3; i++)
        (await File('${directory.path}/$i.jpg').writeAsBytes([1, 2, 3])).path,
    ];
  });
  tearDown(() => directory.delete(recursive: true));
  test(
    'completion starts assigned task then submits exactly three fresh files and 100 percent',
    () async {
      final writes = <Map<String, String>>[];
      final files = <List<String>>[];
      final service = MaintenanceUpdateService();
      final saved = await service.save(
        task(status: 'ASSIGNED'),
        status: MaintenanceTaskStatus.completed,
        notes: '  Repaired the drain.  ',
        photos: photos,
        checkOwnership: () {},
        update: (id, fields, paths) async {
          expect(id, 'task-id');
          writes.add(fields);
          files.add(paths);
          return {
            ...receipt(fields['status']!),
            if (fields.containsKey('resolutionNotes'))
              'resolutionNotes': fields['resolutionNotes'],
          };
        },
      );
      expect(writes, [
        {'status': 'IN_PROGRESS'},
        {
          'status': 'PENDING_APPROVAL',
          'progressPercent': '100',
          'resolutionNotes': 'Repaired the drain.',
          'maintenanceFailureNotes': '',
        },
      ]);
      expect(files, [[], photos]);
      expect(saved.status, MaintenanceTaskStatus.pendingApproval);
      expect(saved.needsEvidence, false);
    },
  );
  for (final badCount in [0, 2, 4]) {
    test('rejects $badCount completion photos before starting work', () async {
      var writes = 0;
      await expectLater(
        MaintenanceUpdateService().save(
          task(status: 'ASSIGNED'),
          status: MaintenanceTaskStatus.completed,
          notes: 'Completed repairs.',
          photos: List.filled(badCount, photos.first),
          checkOwnership: () {},
          update: (_, _, _) async {
            writes++;
            return receipt('PENDING_APPROVAL');
          },
        ),
        throwsFormatException,
      );
      expect(writes, 0);
    });
  }
  for (final problem in [
    'missing',
    'empty',
    'oversized',
    'unsupported',
    'duplicate',
  ]) {
    test('rejects $problem evidence before any request', () async {
      switch (problem) {
        case 'missing':
          await File(photos.first).delete();
        case 'empty':
          await File(photos.first).writeAsBytes([]);
        case 'oversized':
          final handle = await File(photos.first).open(mode: FileMode.write);
          await handle.truncate(10 * 1024 * 1024 + 1);
          await handle.close();
        case 'unsupported':
          photos[0] = (await File(
            '${directory.path}/data.txt',
          ).writeAsString('test')).path;
        case 'duplicate':
          photos[1] = photos[0];
      }
      var writes = 0;
      await expectLater(
        MaintenanceUpdateService().save(
          task(),
          status: MaintenanceTaskStatus.completed,
          notes: 'Completed repairs.',
          photos: photos,
          checkOwnership: () {},
          update: (_, _, _) async {
            writes++;
            return receipt('PENDING_APPROVAL');
          },
        ),
        throwsFormatException,
      );
      expect(writes, 0);
    });
  }
  test(
    'field issue leaves task open without resetting recorded progress or uploading draft photos',
    () async {
      final saved = await MaintenanceUpdateService().save(
        task(),
        status: MaintenanceTaskStatus.failed,
        notes: 'Need a replacement part.',
        photos: photos,
        checkOwnership: () {},
        update: (_, fields, files) async {
          expect(fields, {
            'status': 'IN_PROGRESS',
            'maintenanceFailureNotes': 'Need a replacement part.',
          });
          expect(files, isEmpty);
          return {
            ...receipt('IN_PROGRESS'),
            'maintenanceFailureNotes': 'Need a replacement part.',
          };
        },
      );
      expect(saved.status, MaintenanceTaskStatus.inProgress);
      expect(saved.needsEvidence, true);
      expect(saved.fieldIssueNotes, 'Need a replacement part.');
    },
  );
  for (final mismatch in [
    'id',
    'assignedTeamId',
    'status',
    'progressPercent',
    'resolutionNotes',
    'resolutionPhotoUrls',
  ]) {
    test(
      'rejects mismatched $mismatch instead of reporting completion',
      () async {
        await expectLater(
          MaintenanceUpdateService().save(
            task(),
            status: MaintenanceTaskStatus.completed,
            notes: 'Completed repairs.',
            photos: photos,
            checkOwnership: () {},
            update: (_, _, _) async => {
              ...receipt('PENDING_APPROVAL'),
              mismatch: mismatch == 'progressPercent' ? 50 : 'wrong',
            },
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }
  test('pending and resolved tasks cannot accept more evidence', () async {
    for (final status in ['PENDING_APPROVAL', 'RESOLVED']) {
      await expectLater(
        MaintenanceUpdateService().save(
          task(status: status),
          status: MaintenanceTaskStatus.completed,
          notes: 'Completed repairs.',
          photos: photos,
          checkOwnership: () {},
          update: (_, _, _) async => throw StateError('must not write'),
        ),
        throwsStateError,
      );
    }
  });
  test(
    'rapid duplicate save is blocked and ownership change prevents completion after start',
    () async {
      final service = MaintenanceUpdateService();
      final started = Completer<void>();
      final response = Completer<Map<String, dynamic>>();
      var owned = true;
      var writes = 0;
      Future<MaintenanceTask> save() => service.save(
        task(status: 'ASSIGNED'),
        status: MaintenanceTaskStatus.completed,
        notes: 'Completed repairs.',
        photos: photos,
        checkOwnership: () {
          if (!owned) throw StateError('changed');
        },
        update: (_, _, _) {
          writes++;
          started.complete();
          return response.future;
        },
      );
      final first = save();
      await started.future;
      await expectLater(save(), throwsStateError);
      owned = false;
      response.complete(receipt('IN_PROGRESS'));
      await expectLater(first, throwsStateError);
      expect(writes, 1);
    },
  );
  test(
    'transport fails on a missing attachment rather than sending fewer files',
    () async {
      await expectLater(
        ApiClient.instance.updateReport(
          'task-id',
          idToken: 'token',
          fields: {'status': 'PENDING_APPROVAL'},
          resolutionPhotoPaths: ['${directory.path}/missing.jpg'],
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );
  for (final badNotes in ['short', ' ' * 10, 'x' * 2001]) {
    test(
      'invalid completion notes never start a request (${badNotes.length})',
      () async {
        var calls = 0;
        await expectLater(
          MaintenanceUpdateService().save(
            task(status: 'ASSIGNED'),
            status: MaintenanceTaskStatus.completed,
            notes: badNotes,
            photos: photos,
            checkOwnership: () {},
            update: (_, _, _) async {
              calls++;
              return receipt('PENDING_APPROVAL');
            },
          ),
          throwsFormatException,
        );
        expect(calls, 0);
      },
    );
  }
  test(
    'completion crosses real multipart transport with all new files and explicit progress',
    () async {
      final original = ApiClient.baseUrl;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
      addTearDown(() async {
        ApiClient.baseUrl = original;
        await server.close(force: true);
      });
      server.listen((request) async {
        expect(request.method, 'PATCH');
        expect(request.uri.path, '/api/reports/task-id');
        expect(request.headers.value('authorization'), 'Bearer token');
        final body = await utf8.decoder.bind(request).join();
        expect(
          RegExp('name="resolutionPhotos"; filename=').allMatches(body).length,
          3,
        );
        expect(body, contains('name="status"\r\n\r\nPENDING_APPROVAL'));
        expect(body, contains('name="progressPercent"\r\n\r\n100'));
        expect(
          body,
          contains('name="resolutionNotes"\r\n\r\nCompleted repairs.'),
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'report': receipt('PENDING_APPROVAL')}),
        );
        await request.response.close();
      });
      final result = await MaintenanceUpdateService().save(
        task(),
        status: MaintenanceTaskStatus.completed,
        notes: 'Completed repairs.',
        photos: photos,
        checkOwnership: () {},
        update: (id, fields, files) => ApiClient.instance.updateReport(
          id,
          idToken: 'token',
          fields: fields,
          resolutionPhotoPaths: files,
        ),
      );
      expect(result.status, MaintenanceTaskStatus.pendingApproval);
    },
  );
  for (final appendNew in [true, false]) {
    test(
      'returned work ${appendNew ? "accepts appended new evidence" : "cannot reuse old evidence"}',
      () async {
        final old = [
          '/uploads/resolutions/old-a.jpg',
          '/uploads/resolutions/old-b.jpg',
          '/uploads/resolutions/old-c.jpg',
        ];
        final returned = MaintenanceTask.fromApi({
          ...receipt('IN_PROGRESS'),
          'resolutionPhotoUrls': old,
          'sendBackReason': 'Repair still incomplete.',
        });
        final saving = MaintenanceUpdateService().save(
          returned,
          status: MaintenanceTaskStatus.completed,
          notes: 'Completed repairs.',
          photos: photos,
          checkOwnership: () {},
          update: (_, _, _) async => {
            ...receipt('PENDING_APPROVAL'),
            'resolutionPhotoUrls': [
              ...old,
              if (appendNew)
                ...receipt('PENDING_APPROVAL')['resolutionPhotoUrls'] as List,
            ],
          },
        );
        if (appendNew) {
          expect((await saving).resolutionPhotoUrls.length, 6);
        } else {
          await expectLater(saving, throwsA(isA<ApiException>()));
        }
      },
    );
  }
}
