import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/detail_header.dart';

typedef AboutLinkLauncher = Future<bool> Function(Uri uri);
typedef PackageInfoLoader = Future<PackageInfo> Function();

/// Shared app information for every authenticated role.
class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    this.onBack,
    this.linkLauncher,
    this.packageInfoLoader,
  });

  final VoidCallback? onBack;

  /// Test seams keep platform plugins out of widget tests while production
  /// continues to use [launchUrl] and [PackageInfo.fromPlatform] directly.
  final AboutLinkLauncher? linkLauncher;
  final PackageInfoLoader? packageInfoLoader;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static final Uri _eraAxisUrl = Uri.parse('https://eraaxis.com');
  static final Uri _lecturerUrl = Uri.parse(
    'https://www.linkedin.com/in/mark-kofi-amoani-mensah-7a7072b1',
  );

  static final List<({String name, Uri uri})> _team = [
    (
      name: 'Kingsley Anorful',
      uri: Uri.parse('https://www.linkedin.com/in/kingsley-anorful-9070a3350'),
    ),
    (
      name: 'Amoako Kingsben Ofosu',
      uri: Uri.parse('https://www.linkedin.com/in/kingsben-amoako-765b23344'),
    ),
    (
      name: 'Abdul Aziz Hassan',
      uri: Uri.parse('https://www.linkedin.com/in/abdul-aziz-hassan-a2127536b'),
    ),
    (
      name: 'Abdul Latif Osmani Sani',
      uri: Uri.parse('https://www.linkedin.com/in/latif-sani-05b30b36b'),
    ),
    (
      name: 'Francis Kekeli Afun',
      uri: Uri.parse(
        'https://www.linkedin.com/in/francis-kekeli-afun-66262634a',
      ),
    ),
  ];

  late final Future<PackageInfo> _packageInfo =
      (widget.packageInfoLoader ?? PackageInfo.fromPlatform)();

  Future<void> _openLink(Uri uri) async {
    var launched = false;
    try {
      launched = await (widget.linkLauncher ?? launchUrl)(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                DetailHeader.topInset(context) + AppSpacing.lg,
                AppSpacing.md,
                bottomInset + AppSpacing.xl,
              ),
              children: [
                Center(
                  child: Semantics(
                    image: true,
                    label: 'CivicVoice logo',
                    child: Image.asset(
                      AppAssets.logoApp,
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'A direct line between citizens and the assemblies that serve them.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  "CivicVoice is a civic-issue reporting platform for Ghana's District Municipal, and Metropolitan Assemblies. It gives citizens a fast, transparent way to report public infrastructure problems — potholes, broken streetlights, damaged facilities — and follow them through review, assignment, and resolution.",
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "The platform is built to stay free of political interference: every report is judged on verifiable evidence, not opinion, and every citizen's voice carries the same weight. Municipal Officers, Maintenance Teams, and Ministry oversight all work from the same transparent record, so accountability isn't just promised — it's visible.",
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Built By', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CivicVoice was designed and built by a team of Computer Engineering students at Ghana Communication Technology University (GCTU), as part of our Mobile Computing and Mobile App Development coursework.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Connect with the team:',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final member in _team)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _openLink(member.uri),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        minimumSize: AppDimensions.touchTarget,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text('Acknowledgments', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'Special thanks to our lecturer, '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () => _openLink(_lecturerUrl),
                          child: Text(
                            'Mark Kofi Amoani Mensah',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text:
                            ', for the guidance and support provided throughout this project.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'Special thanks to ERA AXIS ('),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () => _openLink(_eraAxisUrl),
                          child: Text(
                            'eraaxis.com',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text:
                            ") for hosting the CivicVoice backend infrastructure and supporting this project's development.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox.shrink();
                    return Text(
                      'Version ${info.version} (${info.buildNumber})',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'About CivicVoice',
              onBack: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}
