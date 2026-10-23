import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/citizen/services/report_submission_store.dart';
import 'package:civic_voice/services/api_client.dart';

void main() {
  test(
    'a report response cannot repopulate the list after session clear',
    () async {
      String? owner = 'A';
      final service = ReportCrudService.forTesting(
        account: () => owner,
        token: () async => 'fixture',
        store: ReportSubmissionStore(),
      );
      final previous = ApiClient.baseUrl;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
      addTearDown(() async {
        ApiClient.baseUrl = previous;
        await server.close(force: true);
      });
      final received = Completer<void>(), release = Completer<void>();
      server.listen((request) async {
        received.complete();
        await release.future;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"reports":[{"id":"old-report","title":"Old account","status":"SUBMITTED","photos":[]}]}',
        );
        await request.response.close();
      });
      final pending = service.refresh();
      await received.future;
      service.clearSession();
      owner = 'B';
      release.complete();
      await pending;
      expect(service.reports.value, isEmpty);
    },
  );
  test(
    'a token from a cleared session cannot dispatch a report refresh',
    () async {
      String? owner = 'A';
      final token = Completer<String>();
      final service = ReportCrudService.forTesting(
        account: () => owner,
        token: () => token.future,
        store: ReportSubmissionStore(),
      );
      final pending = service.refresh();
      owner = null;
      service.clearSession();
      token.complete('old-token');
      await pending;
      expect(service.reports.value, isEmpty);
    },
  );
}
