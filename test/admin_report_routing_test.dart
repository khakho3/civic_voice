import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_report_routing.dart';
import 'package:civic_voice/features/admin/services/admin_routing_repository.dart';
import 'package:civic_voice/models/ghana_assemblies_data.dart';
import 'package:civic_voice/models/region.dart';

Map<String, dynamic> routingFixture({bool resolved = false}) => {
  'id': 'report-one',
  'publicReference': 'CV-ONE',
  'title': 'Broken road',
  'description': 'Road surface needs inspection.',
  'location': 'Recorded issue address',
  'community': null,
  'region': 'greaterAccra',
  'assembly': resolved ? 'Ga Central' : null,
  'latitude': 5.58,
  'longitude': -0.29,
  'status': 'SUBMITTED',
  'photoUrls': <String>['/uploads/reports/photo-one.png'],
  'createdAt': '2026-10-23T10:00:00.000Z',
  'updatedAt': resolved
      ? '2026-10-24T12:00:00.000Z'
      : '2026-10-23T10:00:00.000Z',
  'unresolved': !resolved,
  'canRoute': !resolved,
};
Map<String, dynamic> routingAck() => {
  'report': routingFixture(resolved: true),
  'municipalOfficers': 0,
  'auditRecorded': false,
};
const routingChange = RoutingChange(
  Region.greaterAccra,
  'Ga Central',
  'Confirmed the saved issue pin and address.',
);
void main() {
  test('all exact native geography names match the server naming contract', () {
    final server =
        jsonDecode(
              File(
                'test/fixtures/routing_jurisdictions.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(server.length, 16);
    expect(ghanaAssemblies.values.expand((v) => v).length, 261);
    for (final region in Region.values) {
      expect(
        ghanaAssemblies[region]!.map((a) => a.name).toSet(),
        (server[region.name] as List).toSet(),
      );
    }
  });
  test(
    'routing request preserves exact canonical values and original version',
    () {
      final report = RoutingReport.parse(routingFixture());
      expect(routingChange.body(report), {
        'region': 'greaterAccra',
        'assembly': 'Ga Central',
        'reason': routingChange.reason,
        'expectedUpdatedAt': '2026-10-23T10:00:00.000Z',
      });
      expect(
        const RoutingChange(
          Region.ashanti,
          'Ga Central',
          'A sufficiently long reason',
        ).valid,
        isFalse,
      );
      expect(
        const RoutingChange(
          Region.greaterAccra,
          'Ga Central Municipality',
          'A sufficiently long reason',
        ).valid,
        isFalse,
      );
      expect(
        const RoutingChange(Region.greaterAccra, 'Ga Central', 'short').valid,
        isFalse,
      );
    },
  );
  final bad = <Map<String, dynamic>>[
    {'id': '../bad'},
    {'latitude': 91},
    {'longitude': double.nan},
    {
      'photoUrls': ['file:///private'],
    },
    {
      'photoUrls': ['/uploads/reports/../other.png'],
    },
    {'canRoute': true, 'status': 'UNDER_REVIEW'},
    {'unresolved': false},
    {'updatedAt': '2026-02-30T10:00:00.000Z'},
    {'updatedAt': '2026-10-23T10:00:00Z'},
    {'description': true},
  ];
  for (var i = 0; i < bad.length; i++) {
    test('reject malformed routing snapshot $i', () {
      expect(
        () => RoutingReport.parse({...routingFixture(), ...bad[i]}),
        throwsFormatException,
      );
    });
  }
  test(
    'queue excludes resolved/duplicate/inconsistent pages and repeated empty cursors',
    () {
      for (final raw in [
        {
          'reports': [routingFixture(resolved: true)],
          'total': 1,
          'nextCursor': null,
        },
        {
          'reports': [routingFixture(), routingFixture()],
          'total': 2,
          'nextCursor': null,
        },
        {
          'reports': [routingFixture()],
          'total': 0,
          'nextCursor': null,
        },
        {'reports': [], 'total': 0, 'nextCursor': 'next-page'},
      ]) {
        expect(() => RoutingPage.parse(raw), throwsFormatException);
      }
    },
  );
  test(
    'zero officers and audit-off are valid acknowledgments, not geography input',
    () {
      final ack = RoutingAcknowledgment.parse(
        routingAck(),
        RoutingReport.parse(routingFixture()),
        routingChange,
      );
      expect(ack.municipalOfficers, 0);
      expect(ack.auditRecorded, isFalse);
      expect(
        ack.matchesFresh(RoutingReport.parse(routingFixture(resolved: true))),
        isTrue,
      );
    },
  );
  final ackChanges = <Map<String, dynamic>>[
    {'id': 'other'},
    {'publicReference': 'CV-OTHER'},
    {'assembly': 'Ga West'},
    {'photoUrls': <String>[]},
    {'latitude': 5.99},
    {'status': 'UNDER_REVIEW'},
    {'canRoute': true},
    {'updatedAt': '2026-10-23T10:00:00.000Z'},
  ];
  for (var i = 0; i < ackChanges.length; i++) {
    test('reject unrelated or unconfirmed routing acknowledgment $i', () {
      expect(
        () => RoutingAcknowledgment.parse(
          {
            ...routingAck(),
            'report': {...routingFixture(resolved: true), ...ackChanges[i]},
          },
          RoutingReport.parse(routingFixture()),
          routingChange,
        ),
        throwsFormatException,
      );
    });
  }
  test('no owner means no queue/detail requests or writes', () async {
    var reads = 0, writes = 0;
    final repo = AdminRoutingRepository(
      owner: () => null,
      credential: () async => 'fixture',
      list: (_, _, _) async {
        reads++;
        return {'reports': [], 'total': 0, 'nextCursor': null};
      },
      read: (_, _) async {
        reads++;
        return {'report': routingFixture()};
      },
      write: (_, _, _) async {
        writes++;
        return routingAck();
      },
    );
    final q = repo.queue('', null), d = repo.report('report-one');
    addTearDown(q.dispose);
    addTearDown(d.dispose);
    await q.load();
    await d.load();
    expect(reads, 0);
    await expectLater(
      repo.save(
        'fixture',
        RoutingReport.parse(routingFixture()),
        routingChange,
      ),
      throwsStateError,
    );
    expect(writes, 0);
  });
  test('late queue data cannot cross owner or jurisdiction changes', () async {
    String? owner = 'super-A';
    final pending = Completer<Map<String, dynamic>>();
    final repo = AdminRoutingRepository(
      owner: () => owner,
      credential: () async => 'fixture',
      list: (_, _, _) => pending.future,
    );
    final source = repo.queue('', null);
    addTearDown(source.dispose);
    final request = source.load();
    await Future<void>.delayed(Duration.zero);
    owner = 'super-B';
    pending.complete({
      'reports': [routingFixture()],
      'total': 1,
      'nextCursor': null,
    });
    await request;
    expect(source.data, isNull);
  });
  test(
    'ownership change while waiting for a credential blocks the write',
    () async {
      String? owner = 'super-A';
      var reads = 0, writes = 0;
      final token = Completer<String?>();
      final repo = AdminRoutingRepository(
        owner: () => owner,
        credential: () => reads++ == 0 ? Future.value('fixture') : token.future,
        read: (_, _) async => {'report': routingFixture()},
        write: (_, _, _) async {
          writes++;
          return routingAck();
        },
      );
      final source = repo.report('report-one');
      addTearDown(source.dispose);
      await source.load();
      final request = source.mutate((t, p) async {
        await repo.save(t, p, routingChange);
      });
      owner = null;
      token.complete('fixture');
      expect(await request, isFalse);
      expect(writes, 0);
      expect(source.data, isNull);
    },
  );
  test(
    'one write, matching ack and fresh read are all required for success',
    () async {
      var resolved = false, writes = 0, reads = 0;
      final pending = Completer<Map<String, dynamic>>();
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        read: (_, _) async {
          reads++;
          return {'report': routingFixture(resolved: resolved)};
        },
        write: (_, _, body) async {
          writes++;
          expect(
            body,
            routingChange.body(RoutingReport.parse(routingFixture())),
          );
          return pending.future;
        },
      );
      final source = repo.report('report-one');
      addTearDown(source.dispose);
      await source.load();
      RoutingAcknowledgment? ack;
      final request = source.mutate((t, p) async {
        ack = await repo.save(t, p, routingChange);
      }, verify: (r) => ack?.matchesFresh(r) ?? false);
      expect(
        await source.mutate((_, _) async {
          writes++;
        }),
        isFalse,
      );
      resolved = true;
      pending.complete(routingAck());
      expect(await request, isTrue);
      expect(writes, 1);
      expect(reads, 2);
      expect(source.data!.canRoute, isFalse);
    },
  );
  test(
    'uncertain saves retain lock until an authoritative reload, with no automatic retry',
    () async {
      var writes = 0;
      var acknowledged = false;
      var failRead = false;
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        read: (_, _) async {
          if (failRead) throw StateError('offline');
          return {'report': routingFixture(resolved: acknowledged)};
        },
        write: (_, _, _) async {
          writes++;
          acknowledged = true;
          failRead = true;
          return routingAck();
        },
      );
      final source = repo.report('report-one');
      addTearDown(source.dispose);
      await source.load();
      RoutingAcknowledgment? ack;
      expect(
        await source.mutate((t, p) async {
          ack = await repo.save(t, p, routingChange);
        }, verify: (r) => ack?.matchesFresh(r) ?? false),
        isFalse,
      );
      expect(source.uncertain, isTrue);
      expect(
        await source.mutate((_, _) async {
          writes++;
        }),
        isFalse,
      );
      expect(writes, 1);
      failRead = false;
      await source.load();
      expect(source.uncertain, isFalse);
      expect(source.data!.unresolved, isFalse);
    },
  );
  test(
    'an unchanged read after an ack is unconfirmed and locks another write',
    () async {
      final repo = AdminRoutingRepository(
        owner: () => 'super-A',
        credential: () async => 'fixture',
        read: (_, _) async => {'report': routingFixture()},
        write: (_, _, _) async => routingAck(),
      );
      final source = repo.report('report-one');
      addTearDown(source.dispose);
      await source.load();
      RoutingAcknowledgment? ack;
      expect(
        await source.mutate((t, p) async {
          ack = await repo.save(t, p, routingChange);
        }, verify: (r) => ack?.matchesFresh(r) ?? false),
        isFalse,
      );
      expect(source.uncertain, isTrue);
    },
  );
}
