import 'package:flutter/material.dart';
import '../../../widgets/focused_search.dart';
export '../../../widgets/focused_search.dart' show FocusedSearchResult;

class MunicipalSearchField extends StatelessWidget {
  const MunicipalSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.trailing,
    required this.screenKey,
    required this.results,
  });
  final TextEditingController? controller;
  final String hintText;
  final bool enabled;
  final Widget? trailing;
  final String screenKey;
  final FocusedSearchResultsBuilder results;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller ?? _staticListenable,
    builder: (context, _) => Row(
      children: [
        Expanded(
          child: IgnorePointer(
            ignoring: !enabled,
            child: SearchTriggerField(
              hintText: hintText,
              query: controller?.text ?? '',
              onClear: controller?.clear,
              onOpen: () async {
                final query = await showFocusedSearch(
                  context,
                  screenKey: screenKey,
                  hintText: hintText,
                  initialQuery: controller?.text ?? '',
                  results: results,
                );
                if (context.mounted && query != null) controller?.text = query;
              },
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

final _staticListenable = ValueNotifier(false);
