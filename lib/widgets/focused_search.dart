import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_cache_service.dart';
import '../services/app_haptics.dart';
import 'confirm_dialog.dart';

/// One row in a focused-search result list.
@immutable
class FocusedSearchResult {
  const FocusedSearchResult({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onSelected,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Opens the result. Null renders a static, non-interactive row (e.g.
  /// Ministry's read-only results).
  final VoidCallback? onSelected;
}

/// Screen-specific matching: returns the rows for a non-empty [query]. The
/// screen decides whether its active filter chips apply.
typedef FocusedSearchResultsBuilder =
    List<FocusedSearchResult> Function(String query);

/// Opens the shared focused-search mode (F03) over the current screen and
/// resolves to the query the person submitted, or null if they closed it.
///
/// * Always shows a visible Close; Back and tapping the fog also close it,
///   and the dimmed screen underneath cannot be interacted with.
/// * With an empty query it lists this screen's recent searches
///   ([screenKey] scopes them) with per-entry removal and a Clear that
///   confirms first. History is recorded on submit and on result
///   activation — never per keystroke — trimmed and case-insensitively
///   de-duplicated.
/// * The list underneath is untouched, so its scroll position survives any
///   number of open/close cycles. Open it from a [SearchTriggerField] (not an
///   editable field) so closing never refocuses a text field and reopens
///   the keyboard.
/// * One short fade/settle; none under reduced motion.
Future<String?> showFocusedSearch(
  BuildContext context, {
  required String screenKey,
  required String hintText,
  required FocusedSearchResultsBuilder results,
  String initialQuery = '',
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close search',
    barrierColor: AppColors.scrimStrong.withValues(alpha: 0.48),
    transitionDuration: AppMotion.duration(context, AppMotionDuration.standard),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotionCurve.decelerate,
      ),
      child: child,
    ),
    pageBuilder: (context, _, _) => FocusedSearchPanel(
      screenKey: screenKey,
      hintText: hintText,
      results: results,
      initialQuery: initialQuery,
    ),
  );
}

/// The panel [showFocusedSearch] presents; public for tests and previews.
class FocusedSearchPanel extends StatefulWidget {
  const FocusedSearchPanel({
    super.key,
    required this.screenKey,
    required this.hintText,
    required this.results,
    this.initialQuery = '',
  });

  final String screenKey;
  final String hintText;
  final FocusedSearchResultsBuilder results;
  final String initialQuery;

  @override
  State<FocusedSearchPanel> createState() => _FocusedSearchPanelState();
}

class _FocusedSearchPanelState extends State<FocusedSearchPanel> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );
  late List<String> _history = AppCacheService.instance.searchHistory(
    widget.screenKey,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final term = value.trim();
    if (term.isEmpty) return;
    await AppCacheService.instance.recordSearch(widget.screenKey, term);
    if (mounted) Navigator.of(context).pop(term);
  }

  Future<void> _activate(FocusedSearchResult result) async {
    final select = result.onSelected;
    if (select == null) return;
    AppHaptics.activate();
    await AppCacheService.instance.recordSearch(widget.screenKey, _query.text);
    if (!mounted) return;
    Navigator.of(context).pop();
    select();
  }

  Future<void> _remove(String entry) async {
    final next = await AppCacheService.instance.removeSearch(
      widget.screenKey,
      entry,
    );
    if (mounted) setState(() => _history = next);
  }

  Future<void> _clearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear recent searches?',
      message: 'Your recent searches on this screen will be removed.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed) return;
    await AppCacheService.instance.clearSearchHistory(widget.screenKey);
    if (mounted) setState(() => _history = const []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _query.text.trim();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Material(
              color: colorScheme.surface,
              borderRadius: AppComponentRadius.card,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _query,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              prefixIcon: const Icon(
                                AppIcons.search,
                                size: AppIconSize.md,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _submit,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close search',
                          icon: const Icon(AppIcons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: query.isEmpty
                        ? _HistoryList(
                            history: _history,
                            onPick: (entry) {
                              _query.text = entry;
                              _query.selection = TextSelection.collapsed(
                                offset: entry.length,
                              );
                              setState(() {});
                            },
                            onRemove: _remove,
                            onClear: _clearAll,
                          )
                        : _ResultList(
                            query: query,
                            results: widget.results(query),
                            onActivate: _activate,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.history,
    required this.onPick,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> history;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Your recent searches will appear here.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Recent searches',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: AppFontWeight.medium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
        ),
        for (final entry in history)
          ListTile(
            leading: Icon(
              AppIcons.recentSearch,
              size: AppIconSize.md,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(entry, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => onPick(entry),
            trailing: IconButton(
              tooltip: 'Remove "$entry" from recent searches',
              icon: Icon(
                AppIcons.close,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => onRemove(entry),
            ),
          ),
      ],
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.query,
    required this.results,
    required this.onActivate,
  });

  final String query;
  final List<FocusedSearchResult> results;
  final ValueChanged<FocusedSearchResult> onActivate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    if (results.isEmpty) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No results for "$query".',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(result.title),
          subtitle: result.subtitle == null
              ? null
              : Text(
                  result.subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing:
              result.trailing ??
              (result.onSelected == null
                  ? null
                  : Icon(
                      AppIcons.chevronRight,
                      size: AppIconSize.sm,
                      color: colorScheme.onSurfaceVariant,
                    )),
          onTap: result.onSelected == null ? null : () => onActivate(result),
        );
      },
    );
  }
}

/// A search field that is really a button: it opens [showFocusedSearch]
/// instead of taking focus itself, so Back/Close from the focused mode can
/// never refocus an editable field. Shows the active query, with a clear
/// action, when one is applied.
class SearchTriggerField extends StatelessWidget {
  const SearchTriggerField({
    super.key,
    required this.hintText,
    required this.onOpen,
    this.query = '',
    this.onClear,
    this.compact = false,
  });

  final String hintText;
  final VoidCallback onOpen;

  /// The applied query; empty shows [hintText].
  final String query;

  /// Clears the applied query; shown only while [query] is non-empty.
  final VoidCallback? onClear;

  /// Icon-only trigger for the collapsed filter rail.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuery = query.trim().isNotEmpty;

    if (compact) {
      return IconButton(
        tooltip: hasQuery ? 'Search: $query' : hintText,
        icon: const Icon(AppIcons.search, size: AppIconSize.md),
        onPressed: onOpen,
      );
    }

    // Button semantics without excluding children, so the Clear action
    // stays reachable for screen readers.
    return Semantics(
      button: true,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.inputField,
        child: InkWell(
          borderRadius: AppComponentRadius.inputField,
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.controlHeightStandard,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    AppIcons.search,
                    size: AppIconSize.md,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasQuery ? query : hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: hasQuery
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hasQuery && onClear != null)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(AppIcons.close, size: AppIconSize.sm),
                      onPressed: onClear,
                    )
                  else
                    const SizedBox(width: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
