import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

/// One explanation reused in task detail and editing, driven by server data.
class ReturnedWorkNotice extends StatelessWidget {
  const ReturnedWorkNotice({super.key, required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Returned for rework',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppSemanticColors.of(context).warningText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(reason),
      ],
    ),
  );
}
