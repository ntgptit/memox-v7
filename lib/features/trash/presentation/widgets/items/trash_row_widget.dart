import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../domain/entities/trash_batch_entity.dart';
import '../../../domain/models/trash_item_type_model.dart';
import '../support/trash_labels_widget.dart';

/// One deletion, as a row (wireframe W2, T4).
///
/// Four facts and one action, in the order a reader asks for them: what it is,
/// when it went, where it was, how long is left. The path is the third line and
/// carries no affordance — it is context, not a destination (BR-267, T5).
///
/// **`Restore` is the row's trailing action and `Delete permanently` is in the
/// overflow** (T6). Rescuing data has to cost fewer taps than destroying it;
/// side by side, the two would be one mis-tap apart and only one of them is
/// reversible.
class TrashRowWidget extends StatelessWidget {
  const TrashRowWidget({
    required this.batch,
    required this.now,
    required this.isSelecting,
    required this.isSelected,
    required this.canSelect,
    required this.onRestore,
    required this.onMenu,
    required this.onToggleSelection,
    super.key,
  });

  final TrashBatchEntity batch;

  /// Read once by the screen and passed down, so every row on one frame
  /// measures its countdown against the same instant (AD-06, AD-13).
  final DateTime now;

  final bool isSelecting;
  final bool isSelected;

  /// False for a row of the kind the selection is not holding (BR-266). The row
  /// stays legible and stops responding, and the selection bar says why.
  final bool canSelect;

  final VoidCallback onRestore;

  /// Opens the row's overflow menu; what it holds is the screen's
  /// business (wireframe T6 keeps purge one tap behind Restore).
  final VoidCallback onMenu;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDimmed = isSelecting && !canSelect;

    return Semantics(
      // One node for the whole row: a screen reader should hear the item, its
      // kind, when it went and how long is left as one sentence rather than as
      // four unrelated labels (R5).
      container: true,
      selected: isSelecting ? isSelected : null,
      // **The exclusion is spoken, not only painted** (SC-C9-08). A row of the
      // kind this selection is not holding cannot be picked; before this it
      // said so with 38% opacity and nothing else, so a reader met it as an
      // ordinary selectable row.
      enabled: isDimmed ? false : null,
      label: <String>[
        batch.itemName,
        context.trashItemTypeLabel(batch.itemType),
        l10n.trashDeletedDaysAgo(_daysSince),
        l10n.trashDaysLeft(batch.daysLeftAt(now)),
      ].join(', '),
      // **The recession is an ink, not an `Opacity` layer** (SC-C9-08, and
      // A19-06 before it). This wrapped the whole row in `Opacity(0.38)` — the
      // literal value of `AppStateOpacity.disabledContent`, a token scoped by
      // its own docstring to a disabled label or glyph, applied here to a whole
      // row of body text, path and counts. Measured on `scheme.surface`, that
      // put the `bodySmall` lines at 1.70:1 light and 1.89:1 dark and the name
      // at 2.11 / 2.61.
      //
      // The structural half is worse than the numbers: an `Opacity` render
      // object composites *after* the palette, so the high-contrast schemes
      // returned byte-identical figures — every extra bit of ink they buy was
      // thrown away again for exactly the rows a user most needs to read past.
      // Routing through `AppInk.disabled` puts the state back inside the
      // palette, where `highContrastSemantics()` raises `onDisabled` from
      // 2.11 → 3.81 light and 2.62 → 5.12 dark.
      //
      // No value of the old opacity could have worked: 0.7 reaches 2.90 light
      // and 0.80 only 3.51, so nothing that still reads as dim clears 4.5:1
      // there.
      child: MxPressable(
        onTap: isSelecting && canSelect ? onToggleSelection : null,
        onLongPress: canSelect ? onToggleSelection : null,
        shape: MxPressableShape.none,
        child: Padding(
          // Leading: the screen gutter, not a fixed token — G1 requires the
          // chips, the notice and every row to share one left edge, and the
          // shell's gutter is 12 below 360dp and 16 above it.
          //
          // **Trailing: `xs`, and only while the row carries its buttons.**
          // The overflow button is a 48 box around a 24 glyph, so 4 + its own
          // 12 inset paints the kebab on the same 16 the leading edge uses;
          // the gutter outside it painted at 28 and made the row optically
          // 16 left / 28 right (G2). A selecting row has no trailing button
          // to absorb the difference, so it takes the real gutter on both
          // sides — which is why this is a conditional and not a constant.
          padding: EdgeInsets.only(
            left: mxScreenGutter(context),
            right: isSelecting ? mxScreenGutter(context) : AppSpacing.xs,
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  // `secondary`, aligning with the selected-mark decision
                  // recorded on the card tile and the import source step:
                  // dark `primary` measures 3.29:1 as a glyph.
                  child: MxIcon(
                    isSelected
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    ink: isDimmed ? AppInk.disabled : AppInk.secondary,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: MxIcon(
                    batch.itemType == TrashItemType.deck
                        ? Icons.folder_outlined
                        : Icons.style_outlined,
                  ),
                ),
              // The two leading icons above stay outside this exclusion
              // on purpose: a bare `Icon` self-excludes its glyph, so they
              // contribute no narration — but give one a `semanticLabel`
              // and it must move inside here, or the double narration
              // returns.
              // **Excluded, because the row's label already says all of
              // it.** Without this a reader hears the composed sentence,
              // then every fact again one Text at a time — the exact
              // double narration the card-history rows exclude for. The
              // Restore and menu buttons stay outside the exclusion: they
              // are independently actionable and keep their own labels.
              Expanded(
                child: ExcludeSemantics(
                  child: _Body(batch: batch, now: now, isDimmed: isDimmed),
                ),
              ),
              if (!isSelecting) ...<Widget>[
                MxIconButton(
                  icon: Icons.restore,
                  semanticLabel: l10n.trashRestoreAction,
                  tooltip: l10n.trashRestoreAction,
                  onPressed: onRestore,
                ),
                MxIconButton(
                  icon: Icons.more_vert,
                  semanticLabel: l10n.trashRowMenuTitle,
                  tooltip: l10n.trashRowMenuTitle,
                  onPressed: onMenu,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Whole days since the deletion, floored — the row says "today" for anything
  /// under one.
  int get _daysSince => now.difference(batch.deletedAt).inDays;
}

class _Body extends StatelessWidget {
  const _Body({required this.batch, required this.now, required this.isDimmed});

  final TrashBatchEntity batch;
  final DateTime now;

  /// Whether this row is of the kind the current selection is not holding.
  ///
  /// Every rung below collapses to [AppInk.disabled] when it is, which is what
  /// makes the recession a palette fact the high-contrast schemes can raise
  /// rather than a paint-time layer they cannot see (SC-C9-08).
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // One decision, read five times: the row recedes as a whole or not at all.
    // The countdown loses its urgency tint with the rest — an accent on a row
    // that cannot be acted on is a signal pointing nowhere.
    final AppInk quiet = isDimmed ? AppInk.disabled : AppInk.quiet;
    final AppInk urgent = isDimmed ? AppInk.disabled : AppInk.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          batch.itemName,
          style: context.texts.titleMedium!.inked(
            context,
            isDimmed ? AppInk.disabled : AppInk.stated,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        // **`Wrap`, not `Row`.** R1 asks for two things at once — the age may
        // ellipsize, the countdown may not — and a `Row` can only give one of
        // them: the non-flex countdown took its full intrinsic width and
        // overflowed the row outright at 320dp with a large text scale
        // ("Deleted forever today" is ~250dp there). Wrapping puts the
        // countdown on its own line instead, which costs a line and truncates
        // nothing.
        Wrap(
          // **`sm` between two facts, not `xs`.** `xs` is the gap between an
          // icon and its label (`app_spacing.dart`); spent between two whole
          // sentences it left them 4dp apart with nothing else to part them,
          // and the row read as one run of text — "Deleted 2 days ago 28 days
          // left". `deck_workload_line_widget.dart:103` is the same `Wrap` of
          // meta facts on an entity row and separates them at `sm`.
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Text(
              l10n.trashDeletedDaysAgo(now.difference(batch.deletedAt).inDays),
              style: context.texts.bodySmall!.inked(context, quiet),
            ),
            // **The boundary the ink cannot carry alone.** The countdown is
            // the accent and the age is quiet, but in light those two are 11.5
            // ΔE2000 apart (against 26.2 in dark), so on the theme the screen
            // ships in first the colour shift is not a separator. W2 spells
            // the row with a middle dot — `Deleted 2 days ago · 27 days left`
            // — and this is it. Quiet, so the punctuation stays behind both
            // facts; it narrates nothing, because `_Body` sits inside the
            // row's `ExcludeSemantics` and the row's own label joins the same
            // facts with commas.
            Text(
              _inlineSeparator,
              style: context.texts.bodySmall!.inked(context, quiet),
            ),
            // **The one number allowed to carry urgency** (T4). Everything else
            // on the row is neutral, so the countdown is what the eye finds.
            Text(
              l10n.trashDaysLeft(batch.daysLeftAt(now)),
              style: context.texts.bodySmall!.inked(context, urgent),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${l10n.trashOriginLabel}  ${context.trashOriginPath(batch)}',
          style: context.texts.bodySmall!.inked(context, quiet),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (batch.itemType == TrashItemType.deck) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.trashBatchContents(batch),
            style: context.texts.bodySmall!.inked(context, quiet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// The separator between the row's two inline meta facts.
///
/// Punctuation, not copy: a middle dot reads the same in every language this
/// app ships, so it is a constant here rather than a translated string — the
/// spelling `card_history_event_widget.dart`, `deck_summary_metrics_widget.dart`
/// and `starter_library_screen.dart` already use between inline facts.
///
/// Bare, without the spaces those three carry, because there the dot sits
/// inside one text run and the spaces are its whole separation; here the
/// `Wrap` pays `sm` on each side of it.
const String _inlineSeparator = '·';
