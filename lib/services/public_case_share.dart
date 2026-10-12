import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// The only report fields a public share may carry (F08). This mirrors the
/// server-defined public allowlist: reference, title, category, status,
/// locality, assembly and lifecycle dates. Reporter identity and phone,
/// guest flag, free-text description, precise coordinates, staff contacts,
/// trust/confidence flags and rejection/send-back/resolution working notes
/// are deliberately not representable here, so a caller cannot leak them.
@immutable
class PublicCaseSummary {
  const PublicCaseSummary({
    required this.reference,
    required this.title,
    required this.status,
    this.category,
    this.locality,
    this.assembly,
    this.submittedAt,
    this.resolvedAt,
  });

  /// The public case reference people quote (never an internal id).
  final String reference;
  final String title;

  /// Lifecycle status name as the client enum spells it (`submitted`,
  /// `underReview`, `assigned`, `inProgress`, `pendingApproval`, `resolved`,
  /// `rejected`).
  final String status;
  final String? category;
  final String? locality;
  final String? assembly;
  final DateTime? submittedAt;
  final DateTime? resolvedAt;
}

/// What a share attempt actually established. Opening a sheet is not proof
/// of delivery, so only [shared] claims success.
enum PublicShareOutcome {
  /// The platform reports the person picked a share target.
  shared,

  /// The person closed the sheet. A choice, not a failure: stay quiet.
  dismissed,

  /// The platform shared but cannot say what the person did. Stay quiet.
  unknown,

  /// The summary and link were copied to the clipboard.
  copied,

  /// Sharing or copying failed; offer recovery.
  failed,
}

/// The ready-to-send share content.
@immutable
class PublicSharePayload {
  const PublicSharePayload({
    required this.subject,
    required this.text,
    required this.url,
  });

  final String subject;
  final String text;

  /// The canonical public case page, or null while no public origin is
  /// configured (the public site/projection is a deployment dependency).
  final Uri? url;

  /// Text plus link, as one message.
  String get message => url == null ? text : '$text\n$url';
}

/// Signature of the platform share call, injectable for tests.
typedef PublicShareSender = Future<ShareResult> Function(ShareParams params);

/// Builds and sends the one public case share both Municipal Report
/// Progress and Resolution Details use, so the two cannot drift apart and
/// match what the web client sends.
abstract final class PublicCaseShare {
  const PublicCaseShare._();

  /// The approved public site origin, supplied at build time with
  /// `--dart-define=PUBLIC_SITE_URL=https://…`. Empty means no public site is
  /// live yet: shares then carry the summary without a link rather than a
  /// guessed domain.
  static const String configuredOrigin = String.fromEnvironment(
    'PUBLIC_SITE_URL',
  );

  static const Map<String, String> _statusLine = {
    'submitted': 'was just reported',
    'underReview': 'is being reviewed',
    'assigned': 'has been assigned to a repair team',
    'inProgress': 'is being worked on right now',
    'pendingApproval': 'has been completed and is awaiting confirmation',
    'resolved': 'has been fixed',
    'rejected': 'was closed without action',
  };

  /// Canonical public URL for [reference] under [origin], or null without
  /// a valid http(s) origin.
  static Uri? caseUrl(String reference, {String origin = configuredOrigin}) {
    final trimmed = origin.trim().replaceAll(RegExp(r'/+$'), '');
    final base = Uri.tryParse(trimmed);
    if (trimmed.isEmpty ||
        base == null ||
        !(base.scheme == 'https' || base.scheme == 'http') ||
        base.host.isEmpty) {
      return null;
    }
    return base.replace(
      pathSegments: [...base.pathSegments, 'case', reference],
    );
  }

  /// One sentence for whoever receives it: what happened, where, and the
  /// reference people quote.
  static String recipientText(PublicCaseSummary summary) {
    final what = _statusLine[summary.status] ?? 'has an update';
    final where = summary.locality == null || summary.locality!.isEmpty
        ? ''
        : ' at ${summary.locality}';
    return '${summary.title}$where $what — reported on CivicVoice '
        '(${summary.reference}).';
  }

  static PublicSharePayload payload(
    PublicCaseSummary summary, {
    String origin = configuredOrigin,
  }) {
    return PublicSharePayload(
      subject: 'CivicVoice · ${summary.reference}',
      text: recipientText(summary),
      url: caseUrl(summary.reference, origin: origin),
    );
  }

  /// Opens the native share sheet and reports the real outcome.
  static Future<PublicShareOutcome> share(
    PublicCaseSummary summary, {
    String origin = configuredOrigin,
    PublicShareSender? sender,
  }) async {
    final content = payload(summary, origin: origin);
    try {
      final result = await (sender ?? SharePlus.instance.share)(
        ShareParams(text: content.message, subject: content.subject),
      );
      return switch (result.status) {
        ShareResultStatus.success => PublicShareOutcome.shared,
        ShareResultStatus.dismissed => PublicShareOutcome.dismissed,
        ShareResultStatus.unavailable => PublicShareOutcome.unknown,
      };
    } catch (_) {
      return PublicShareOutcome.failed;
    }
  }

  /// Copies the summary and link — the recovery path after a failed share.
  static Future<PublicShareOutcome> copy(
    PublicCaseSummary summary, {
    String origin = configuredOrigin,
  }) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: payload(summary, origin: origin).message),
      );
      return PublicShareOutcome.copied;
    } catch (_) {
      return PublicShareOutcome.failed;
    }
  }

  /// Feedback for [outcome]; empty when the UI should stay quiet.
  static String outcomeMessage(PublicShareOutcome outcome) {
    return switch (outcome) {
      PublicShareOutcome.shared => 'Summary shared.',
      PublicShareOutcome.copied => 'Summary copied to clipboard.',
      PublicShareOutcome.failed =>
        'Could not share the report summary. Please try again.',
      PublicShareOutcome.dismissed || PublicShareOutcome.unknown => '',
    };
  }
}
