import 'package:civic_voice/services/public_case_share.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

const _summary = PublicCaseSummary(
  reference: 'CV-2026-000123',
  title: 'Broken streetlight',
  status: 'inProgress',
  category: 'Street Lighting',
  locality: 'Adum',
  assembly: 'Kumasi Metropolitan Assembly',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recipient copy is status-aware and leads with what happened', () {
    expect(
      PublicCaseShare.recipientText(_summary),
      'Broken streetlight at Adum is being worked on right now — reported '
      'on CivicVoice (CV-2026-000123).',
    );
    for (final status in [
      'submitted',
      'underReview',
      'assigned',
      'pendingApproval',
      'resolved',
      'rejected',
    ]) {
      final text = PublicCaseShare.recipientText(
        PublicCaseSummary(reference: 'R', title: 'T', status: status),
      );
      expect(text, isNot(contains('has an update')), reason: status);
    }
  });

  test('no public origin means no guessed link', () {
    final payload = PublicCaseShare.payload(_summary, origin: '');
    expect(payload.url, isNull);
    expect(payload.message, payload.text);
    expect(PublicCaseShare.caseUrl('CV-1', origin: 'not a url'), isNull);
  });

  test('a configured origin yields the canonical case URL', () {
    final url = PublicCaseShare.caseUrl(
      'CV-2026-000123',
      origin: 'https://example.org/',
    );
    expect(url.toString(), 'https://example.org/case/CV-2026-000123');
  });

  test(
    'share outcomes map platform results without inferring delivery',
    () async {
      Future<PublicShareOutcome> run(ShareResultStatus status) =>
          PublicCaseShare.share(
            _summary,
            origin: '',
            sender: (_) async => ShareResult('', status),
          );
      expect(await run(ShareResultStatus.success), PublicShareOutcome.shared);
      expect(
        await run(ShareResultStatus.dismissed),
        PublicShareOutcome.dismissed,
      );
      expect(
        await run(ShareResultStatus.unavailable),
        PublicShareOutcome.unknown,
      );

      final failed = await PublicCaseShare.share(
        _summary,
        origin: '',
        sender: (_) async => throw PlatformException(code: 'share_failed'),
      );
      expect(failed, PublicShareOutcome.failed);

      expect(PublicCaseShare.outcomeMessage(PublicShareOutcome.dismissed), '');
      expect(PublicCaseShare.outcomeMessage(PublicShareOutcome.unknown), '');
      expect(
        PublicCaseShare.outcomeMessage(PublicShareOutcome.failed),
        isNotEmpty,
      );
    },
  );

  test('the sent text carries only allowlisted public fields', () async {
    ShareParams? sent;
    await PublicCaseShare.share(
      _summary,
      origin: 'https://example.org',
      sender: (params) async {
        sent = params;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    expect(sent!.text, contains('CV-2026-000123'));
    expect(sent!.text, contains('https://example.org/case/CV-2026-000123'));
    expect(sent!.subject, 'CivicVoice · CV-2026-000123');
  });
}
