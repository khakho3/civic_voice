import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// One (value, label) entry for [AppDropdownField].
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// The shared dropdown trigger + menu used everywhere a field needs a
/// picklist — replaces the raw `DropdownButton`, whose built-in menu
/// anchors to the *selected item's* position rather than to the button
/// itself (the "doesn't appear under the button" bug). Built on
/// [MenuAnchor] instead, which this widget explicitly anchors directly
/// below the trigger and width-matches to it.
///
/// Lists longer than [searchThreshold] entries automatically grow a search
/// field at the top of the menu that filters by label — no per-call-site
/// opt-in needed, so a long list (e.g. Ghana's assemblies) gets one for
/// free while short lists (e.g. a 3-option time range) stay plain.
class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.searchThreshold = 10,
    this.leadingIcon,
    this.expanded = true,
    this.glass = false,
  });

  /// Field caption shown above the trigger — null/omitted renders no label
  /// row at all (e.g. a compact inline filter control that's already
  /// self-explanatory from context), rather than reserving empty space.
  final String? label;
  final String hint;
  final T? value;
  final List<AppDropdownItem<T>> items;

  /// Null disables the field entirely — matches `DropdownButton`'s own
  /// null-onChanged-means-disabled convention, so existing call sites that
  /// conditionally disable (e.g. "no region chosen yet") port over as-is.
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final int searchThreshold;

  /// Optional glyph shown before the trigger's value/hint text — e.g. a
  /// calendar icon on a date-range picker. Menu rows stay text-only.
  final IconData? leadingIcon;

  /// True (default) fills the available width — the normal form-field
  /// look. False hugs the selected value's own natural width instead
  /// (e.g. a compact inline control next to a settings row's label) —
  /// stretching a short value like "Daily" to fill a full-width row turns
  /// it into an oversized pill with dead space before the chevron.
  final bool expanded;

  /// True tints the trigger with the glass surface token instead of the
  /// opaque `surfaceContainer` fill — for filter-context instances only
  /// (e.g. a time-range/date-range filter), where §19.10 explicitly
  /// permits glass. Defaults false because this same widget also backs
  /// plain form fields (Region/Assembly, Role, Status) — glass is
  /// prohibited there, so it's opt-in per call site, not a theme default.
  final bool glass;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final _menuController = MenuController();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _labelFor(T? value) {
    if (value == null) return null;
    for (final item in widget.items) {
      if (item.value == value) return item.label;
    }
    return null;
  }

  List<AppDropdownItem<T>> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final query = _query.toLowerCase();
    return widget.items
        .where((item) => item.label.toLowerCase().contains(query))
        .toList();
  }

  void _resetSearch() {
    if (_query.isNotEmpty) setState(() => _query = '');
    _searchController.clear();
  }

  void _select(AppDropdownItem<T>? item) {
    widget.onChanged?.call(item?.value);
    _menuController.close();
    _resetSearch();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final fillColor = widget.glass
        ? semantic.glassSurface
        : colorScheme.surfaceContainer;
    final hasError = widget.errorText != null;
    final enabled = widget.onChanged != null;
    final selectedLabel = _labelFor(widget.value);
    final showSearch = widget.items.length > widget.searchThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              controller: _menuController,
              consumeOutsideTap: true,
              style: const MenuStyle(
                alignment: Alignment.bottomLeft,
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              alignmentOffset: const Offset(0, AppSpacing.xs),
              onClose: _resetSearch,
              menuChildren: [
                _DropdownMenuContent<T>(
                  width: widget.expanded ? constraints.maxWidth : null,
                  items: _filteredItems,
                  selectedValue: widget.value,
                  showSearch: showSearch,
                  searchController: _searchController,
                  onQueryChanged: (query) => setState(() => _query = query),
                  onSelected: _select,
                ),
              ],
              builder: (context, controller, _) {
                return Material(
                  color: enabled
                      ? fillColor
                      : fillColor.withValues(alpha: fillColor.a * 0.5),
                  borderRadius: AppComponentRadius.inputField,
                  child: InkWell(
                    borderRadius: AppComponentRadius.inputField,
                    onTap: enabled
                        ? () => controller.isOpen
                              ? controller.close()
                              : controller.open()
                        : null,
                    child: Container(
                      height: AppDimensions.controlHeightStandard,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: hasError
                          ? BoxDecoration(
                              borderRadius: AppComponentRadius.inputField,
                              border: Border.all(color: AppColors.error),
                            )
                          : null,
                      child: Row(
                        mainAxisSize: widget.expanded
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            Icon(
                              widget.leadingIcon,
                              size: AppIconSize.sm,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (widget.expanded)
                            Expanded(
                              child: Text(
                                selectedLabel ?? widget.hint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: selectedLabel == null
                                      ? colorScheme.onSurfaceVariant
                                      : (enabled
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          else
                            Text(
                              selectedLabel ?? widget.hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                color: selectedLabel == null
                                    ? colorScheme.onSurfaceVariant
                                    : (enabled
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant),
                              ),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            AppIcons.chevronDown,
                            size: AppIconSize.sm,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: textTheme.labelSmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _DropdownMenuContent<T> extends StatelessWidget {
  const _DropdownMenuContent({
    required this.width,
    required this.items,
    required this.selectedValue,
    required this.showSearch,
    required this.searchController,
    required this.onQueryChanged,
    required this.onSelected,
  });

  /// Null for a non-expanded [AppDropdownField] — the menu then hugs its
  /// own content width instead of matching the trigger (whose own width
  /// is itself just hugging its content in that mode, so there's nothing
  /// meaningful to match). Compact dropdowns are always short lists, so
  /// this path also skips the scrolling ListView machinery entirely.
  final double? width;
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AppDropdownItem<T>?> onSelected;

  /// At most 6 rows visible before scrolling — enough to see a handful of
  /// options at a glance without letting a long list (Ghana has dozens of
  /// assemblies) push the menu off-screen.
  static const _maxVisibleRows = 6;

  double _menuListHeight(int itemCount) {
    final visibleRows = itemCount < _maxVisibleRows
        ? itemCount
        : _maxVisibleRows;
    return visibleRows * AppDimensions.controlHeightStandard +
        AppSpacing.xs * 2;
  }

  Widget _row(
    BuildContext context,
    AppDropdownItem<T> item,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final selected = item.value == selectedValue;
    return InkWell(
      onTap: () => onSelected(item),
      child: Container(
        alignment: Alignment.centerLeft,
        height: width == null ? AppDimensions.controlHeightStandard : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
            color: selected ? AppColors.primary : colorScheme.onSurface,
            fontWeight: selected ? AppFontWeight.semiBold : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final Widget itemsRegion;
    if (items.isEmpty) {
      itemsRegion = Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No matches',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else if (width != null) {
      // A fixed-height SizedBox (not shrinkWrap/intrinsic sizing) —
      // MenuAnchor's internal panel sizes itself via intrinsic height, and
      // a lazily-built ListView can't answer that without materializing
      // every child ("RenderShrinkWrappingViewport does not support
      // returning intrinsic dimensions"). Computing the height ourselves
      // from a fixed row extent sidesteps it.
      itemsRegion = SizedBox(
        height: _menuListHeight(items.length),
        child: ListView.builder(
          // Not primary — this nested list must not fight the ambient
          // PrimaryScrollController the host screen's own scroll view is
          // attached to ("PrimaryScrollController is attached to more
          // than one ScrollPosition").
          primary: false,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemExtent: AppDimensions.controlHeightStandard,
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _row(context, items[index], textTheme, colorScheme),
        ),
      );
    } else {
      // Non-expanded (compact/hug-content) mode: always a short list by
      // design, so a plain Column instead of a scrolling ListView — a
      // ListView's viewport can't report a sensible intrinsic width, which
      // this mode relies on (see AppDropdownField's own width handling).
      itemsRegion = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              _row(context, item, textTheme, colorScheme),
          ],
        ),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: onQueryChanged,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search…',
                prefixIcon: const Icon(AppIcons.search, size: AppIconSize.sm),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: AppComponentRadius.inputField,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        itemsRegion,
      ],
    );

    return Material(
      color: colorScheme.surface,
      elevation: AppElevation.level2,
      borderRadius: AppComponentRadius.inputField,
      clipBehavior: Clip.antiAlias,
      child: width != null ? SizedBox(width: width, child: content) : content,
    );
  }
}
