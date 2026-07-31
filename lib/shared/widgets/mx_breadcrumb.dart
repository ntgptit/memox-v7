import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// One step in an [MxBreadcrumb].
///
/// A plain value with no domain type in it: the widget is told a name and what to
/// do, and knows nothing about decks, files or anything else it might be pointing
/// at. That is what keeps this in `shared/` — a breadcrumb that knew a `DeckEntity`
/// would drag the deck domain into every widget test in the project.
///
/// [onTap] null marks the step the user is already on. It is not "disabled": there
/// is nowhere to go, so it is rendered as text rather than as a control that does
/// nothing.
@immutable
class MxBreadcrumbItem {
  const MxBreadcrumbItem({required this.label, this.onTap});

  /// Already-localized, or a user's own text. Components never reach for ARB.
  final String label;

  /// Null for the step that is already open.
  final VoidCallback? onTap;
}

/// The path from the top of a hierarchy down to where the user is now.
///
/// **Why this is not one of the existing components.** `MxNavigationBar` switches
/// between siblings at a fixed top level; a breadcrumb moves *up* an arbitrary
/// number of levels. `MxPillButton` is one of N views of the same content — a set,
/// not a sequence, and it has a selected state where a path has a last element.
/// `MxListTile` is a row. Nothing in `shared/widgets/` held "where am I, and how
/// do I get back up", so this is the missing piece.
///
/// **It scrolls horizontally and therefore cannot overflow.** A path can be ten
/// deep (BR-55 caps the deck tree there) and a 320-wide screen at `textScaler` 2.0
/// fits about one and a half names. The alternatives were both worse: wrapping
/// turns a deep path into five lines of chrome above the content it is meant to
/// help you scan, and collapsing the middle behind an ellipsis hides exactly the
/// steps a user goes to a breadcrumb to find. Scrolling hides nothing and costs
/// nothing when the path is short.
///
/// Left-aligned rather than pinned to the end, because the ancestors are the part
/// worth seeing: where you *are* is already the screen's title, and the last step
/// here repeats it only so the path has somewhere to terminate.
///
/// Every step is its own tap target at [AppSpacing.minimumTouchTarget], so a deep
/// path is a row of real controls rather than a line of text with hot spots in it.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({required this.items, this.semanticLabel, super.key});

  /// Ordered from the top of the hierarchy to the current step.
  ///
  /// An empty list renders nothing at all — not an empty bar. A path with one
  /// element says only "you are here", which the title already said, so a caller
  /// with nothing above the current step should not build this widget.
  final List<MxBreadcrumbItem> items;

  /// Names the strip for assistive technology — "deck path", not the path itself.
  ///
  /// Applied with `explicitChildNodes`, so it introduces the group without
  /// swallowing the steps: a screen reader announces the group and then each step
  /// as its own button, rather than reading one run-on string.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final (int index, MxBreadcrumbItem item)
                in items.indexed) ...<Widget>[
              if (index > 0) const _MxBreadcrumbSeparator(),
              _MxBreadcrumbStep(
                item: item,
                isCurrent: index == items.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One step: a button when there is somewhere to go, text when there is not.
class _MxBreadcrumbStep extends StatelessWidget {
  const _MxBreadcrumbStep({required this.item, required this.isCurrent});

  final MxBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    // The current step is the quiet one. It is where you already are, so drawing
    // it at full strength would make the least actionable thing on the strip the
    // loudest — and the ancestors are what the control is for.
    final style = context.texts.labelLarge?.copyWith(
      color: isCurrent
          ? context.colors.onSurfaceVariant
          : context.colors.onSurface,
      fontWeight: isCurrent ? FontWeight.w400 : FontWeight.w600,
    );

    final label = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minimumTouchTarget,
      ),
      child: Center(
        widthFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(item.label, style: style, maxLines: 1),
        ),
      ),
    );

    final tap = item.onTap;
    if (tap == null) return label;

    // `button: true` for the same reason `MxCard` needs it: an `InkWell`
    // contributes a tap action and focusability but not the button flag, so a
    // reader would announce the name and never say it can be activated.
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: label,
        ),
      ),
    );
  }
}

/// The mark between two steps.
///
/// Excluded from semantics: a chevron between names is punctuation, and a reader
/// announcing "chevron right" nine times on a deep path is noise the user has to
/// sit through. The grouping is carried by [MxBreadcrumb.semanticLabel] instead.
class _MxBreadcrumbSeparator extends StatelessWidget {
  const _MxBreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.chevron_right,
        size: AppIconSize.sm,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}
