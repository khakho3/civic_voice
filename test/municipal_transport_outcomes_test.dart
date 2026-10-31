import 'dart:convert';
import 'dart:io';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final claim in [true, false]) {
    Future<Map<String, dynamic>> request() => claim
        ? ApiClient.instance.claimReportReview(
            'fixture-record',
            idToken: 'fixture-token',
          )
        : ApiClient.instance.updateReport(
            'fixture-record',
            idToken: 'fixture-token',
            fields: const {'status': 'RESOLVED'},
          );
    for (final code in [403, 404, 409, 500]) {
      test(
        'municipal ${claim ? 'claim' : 'decision'} preserves HTTP $code',
        () async {
          var calls = 0;
          await http.runWithClient(
            () async {
              await expectLater(
                request(),
                throwsA(
                  isA<ApiException>()
                      .having((e) => e.statusCode, 'status', code)
                      .having((e) => e.message, 'message', 'Fixture rejection'),
                ),
              );
            },
            () => MockClient((request) async {
              calls++;
              expect(
                request.url.path,
                claim
                    ? '/api/reports/fixture-record/claim-review'
                    : '/api/reports/fixture-record',
              );
              expect(request.method, claim ? 'POST' : 'PATCH');
              return http.Response(
                jsonEncode({'error': 'Fixture rejection'}),
                code,
              );
            }),
          );
          expect(
            calls,
            1,
            reason: 'Uncertain decisions must not be automatically retried',
          );
        },
      );
    }
    test(
      'municipal ${claim ? 'claim' : 'decision'} returns acknowledged record',
      () async {
        final response = await http.runWithClient(
          request,
          () => MockClient(
            (_) async => http.Response(
              jsonEncode({
                'report': {
                  'id': 'fixture-record',
                  'status': claim ? 'UNDER_REVIEW' : 'RESOLVED',
                },
              }),
              200,
            ),
          ),
        );
        expect(response['id'], 'fixture-record');
        expect(response['status'], claim ? 'UNDER_REVIEW' : 'RESOLVED');
      },
    );
    test(
      'municipal ${claim ? 'claim' : 'decision'} reports lost connection',
      () async {
        await http.runWithClient(
          () async {
            await expectLater(
              request(),
              throwsA(
                isA<ApiException>().having((e) => e.statusCode, 'offline', 0),
              ),
            );
          },
          () => MockClient(
            (_) async => throw const SocketException('Fixture disconnect'),
          ),
        );
      },
    );
  }
}
