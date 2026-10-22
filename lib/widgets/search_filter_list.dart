import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'collapsible_list_header.dart';
import 'focused_search.dart';

/// One contract for a list's expanded search, compact rail and focused mode.
/// Filters remain reachable in both modes; summaries belong in [child].
class SearchFilterList extends StatelessWidget {
  const SearchFilterList({super.key, required this.header, required this.child})
    : headerBuilder = null;

  const SearchFilterList.builder({
    super.key,
    required this.headerBuilder,
    required this.child,
  }) : header = null;

  final SearchFilterHeader? header;
  final Widget Function(bool compact)? headerBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) => CollapsibleListHeader(
    header: header ?? headerBuilder!(false),
    collapsedHeader: header?.asCompact() ?? headerBuilder!(true),
    child: child,
  );
}

class SearchFilterHeader extends StatelessWidget {
  const SearchFilterHeader({
    super.key,
    required this.screenKey,
    required this.hintText,
    required this.query,
    required this.onQueryChanged,
    required this.results,
    this.filters,
    this.intro,
    this.enabled = true,
    this.compact = false,
  });

  final String screenKey;
  final String hintText;
  final String query;
  final ValueChanged<String>? onQueryChanged;
  final FocusedSearchResultsBuilder results;
  final Widget? filters;
  final Widget? intro;
  final bool enabled;
  final bool compact;

  SearchFilterHeader asCompact() => SearchFilterHeader(
    screenKey: screenKey,
    hintText: hintText,
    query: query,
    onQueryChanged: onQueryChanged,
    results: results,
    filters: filters,
    enabled: enabled,
    compact: true,
  );

  @override
  Widget build(BuildContext context) {
    final search = SearchTriggerField(
      hintText: hintText,
      query: query,
      compact: compact,
      enabled: enabled,
      onClear: onQueryChanged == null ? null : () => onQueryChanged!(''),
      onOpen: () async {
        final value = await showFocusedSearch(
          context,
          screenKey: screenKey,
          hintText: hintText,
          initialQuery: query,
          results: results,
        );
        if (context.mounted && value != null) onQueryChanged?.call(value);
      },
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: compact
          ? Row(
              children: [
                search,
                if (filters != null) Expanded(child: filters!),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (intro != null) ...[
                  intro!,
                  const SizedBox(height: AppSpacing.sm),
                ],
                search,
                if (filters != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  filters!,
                ],
              ],
            ),
    );
  }
}
