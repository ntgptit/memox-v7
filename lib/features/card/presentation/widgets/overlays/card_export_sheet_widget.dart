import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_export_request_model.dart';
import '../../../domain/models/card_export_result_model.dart';
import '../../../domain/models/card_export_scope_model.dart';
import '../../../domain/models/card_transfer_format_model.dart';
import '../../controllers/card_export_controller.dart';
import '../../controllers/card_selection_controller.dart';
import '../../states/card_export_state.dart';
import '../sections/card_export_action_bar_widget.dart';
import '../sections/card_export_content_lines_widget.dart';
import '../sections/card_export_error_band_widget.dart';
import '../sections/card_export_format_options_widget.dart';
import '../sections/card_export_scope_summary_widget.dart';
import '../support/card_export_labels_widget.dart';

/// A free function for the same reason every command in this feature is one:
/// a `ref.read` written inline in `build()` is indistinguishable — to the
/// guard and to a reader — from the unsubscribed read that silently stops a
/// widget updating.
Future<void> _submitExport(
  WidgetRef ref,
  String deckId,
  CardExportRequest request,
) => ref.read(exportCardsProvider(deckId).notifier).submit(request);

/// Tells a running export the user has left (M4.13 W4).
///
/// Deterministic where disposal is not: the provider's own disposal cancels
/// too, but only on whichever frame Riverpod gets to it, which for a small
/// deck can be *after* the hand-off has already happened. So every one of the
/// three ways out calls this — `Cancel` directly, and Back and the drag
/// gesture through the sheet's `PopScope`, on the frame the pop starts rather
/// than the frame the provider happens to die.
void _cancelExport(WidgetRef ref, String deckId) =>
    ref.read(exportCardsProvider(deckId).notifier).cancel();

/// Opens the export sheet (UC-11, wireframe M4.13).
///
/// **A modal bottom sheet, and deliberately not a route** (E1). Export asks
/// exactly one question — the format — and the scope is already answered by
/// the entry point. A full-screen route would drag a deep link, a `PopScope`,
/// a breadcrumb, a stepper and an entry in `app_router.dart` behind a
/// three-button panel, paying the import wizard's whole cost with no draft
/// state to justify it. The sheet also leaves the card list visible behind it,
/// so the `N cards` it names can be checked against the list on the spot.
///
/// Resolves to [CardExportResult.shared] when the OS took the file, and to
/// null when the user backed out — a dismissed *share* sheet is not an outcome
/// this future reports, because it is a cancel that leaves the export sheet
/// open (BR-181).
Future<CardExportResult?> showCardExportSheet(
  BuildContext context, {
  required String deckId,
  required CardExportScope scope,
  required int deckCardCount,
}) {
  // Cleared from the tap that opens the sheet, never from a life-cycle hook —
  // the reason `showMxFormSheet` does the same. A reopened sheet must not wear
  // the previous attempt's outcome, and this holds whatever the controller's
  // lifetime turns out to be.
  ProviderScope.containerOf(
    context,
  ).read(exportCardsProvider(deckId).notifier).reset();

  return showModalBottomSheet<CardExportResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => CardExportSheetWidget(
      deckId: deckId,
      scope: scope,
      deckCardCount: deckCardCount,
      onClose: (result) => Navigator.of(sheetContext).pop(result),
    ),
  );
}

/// Card list overflow → the whole deck (M4.13 W1). Never offered on an empty
/// deck: the caller hides the menu entry, and the domain refuses the request
/// anyway (UC-11 E5).
Future<void> exportDeckCards(
  BuildContext context, {
  required String deckId,
  required int deckCardCount,
}) => _runExport(
  context,
  deckId: deckId,
  scope: const CardExportWholeDeckScope(),
  deckCardCount: deckCardCount,
);

/// Selection bar → exactly the ids selection mode materialized (BR-174).
///
/// **The selection survives**, on success as much as on cancel: BR-167 clears
/// a selection after a successful *mutation*, and export is not one (BR-178).
/// Nothing here touches it.
Future<void> exportSelectedCards(
  BuildContext context,
  WidgetRef ref,
  String deckId,
) {
  final selection = ref.read(cardSelectionProvider(deckId));
  if (!selection.hasSelection) return Future<void>.value();

  return _runExport(
    context,
    deckId: deckId,
    scope: CardExportSelectionScope(selection.orderedIds),
    deckCardCount: selection.selectedCount,
  );
}

/// Shows the sheet and, if the OS took the file, says so — truthfully.
///
/// The confirmation never claims a save and never names a folder: the share
/// sheet does not tell the app what the user picked, so "saved to Downloads"
/// would be a sentence nothing can support and one the user would go looking
/// for (BR-181, E9).
Future<void> _runExport(
  BuildContext context, {
  required String deckId,
  required CardExportScope scope,
  required int deckCardCount,
}) async {
  final result = await showCardExportSheet(
    context,
    deckId: deckId,
    scope: scope,
    deckCardCount: deckCardCount,
  );
  if (result != CardExportResult.shared || !context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(context.l10n.cardExportSharedMessage)),
    );
}

/// The sheet itself: title, read-only scope, three formats, what the file
/// holds, what it does not, and one action row (M4.13 W2).
///
/// Deliberately absent: a scope selector (E2), a file-name field (BR-180
/// derives the name), an "include progress" toggle (BR-175 forbids it) and a
/// content preview (BR-181 — private data is not echoed onto a screen for
/// decoration).
///
/// **The chosen format lives here, not in the controller.** It is a selection,
/// not a command, and keeping it in the widget is what makes a failure keep it
/// for free: the controller can go to a failure and back without the request
/// the user is still looking at moving (E8).
class CardExportSheetWidget extends ConsumerStatefulWidget {
  const CardExportSheetWidget({
    required this.deckId,
    required this.scope,
    required this.deckCardCount,
    required this.onClose,
    super.key,
  });

  final String deckId;
  final CardExportScope scope;

  /// The deck's own card count; only the whole-deck scope reads it.
  final int deckCardCount;

  /// Called with [CardExportResult.shared] once the OS accepted the file, and
  /// with null when the user backed out. A callback rather than a
  /// `Navigator.pop` inside the sheet so the catalog can mount it without a
  /// route to pop.
  final ValueChanged<CardExportResult?> onClose;

  @override
  ConsumerState<CardExportSheetWidget> createState() => _CardExportSheetState();
}

class _CardExportSheetState extends ConsumerState<CardExportSheetWidget> {
  /// CSV, because E3 names CSV — not because it happens to be the first enum
  /// value.
  CardTransferFormat _format = CardTransferFormat.csv;

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(exportCardsProvider(widget.deckId));
    final phase = deriveCardExportPhase(submit);
    final count = cardExportScopeCount(widget.scope, widget.deckCardCount);
    final failure = submit.failure;

    // Reacts to the transition, not the value: reading the outcome alone would
    // fire on every rebuild that happens to see it and pop the sheet twice.
    ref.listen(exportCardsProvider(widget.deckId), (previous, next) {
      if (next.result != CardExportResult.shared) return;
      if (previous?.result == CardExportResult.shared) return;
      widget.onClose(CardExportResult.shared);
    });

    // `canPop: true` — this never blocks the exit. W4 wants Back and the drag
    // to close the sheet; what it forbids is the file leaving afterwards. The
    // callback is the only place Back and the drag can reach `cancel()` on the
    // frame the pop starts, which closes the window where a small deck
    // finishes its hand-off before disposal runs.
    return PopScope<CardExportResult?>(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _cancelExport(ref, widget.deckId);
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The body scrolls; the action row does not, so it stays in reach
              // when the sheet is taller than the screen (W6).
              Flexible(
                child: SingleChildScrollView(
                  child: _Body(
                    scope: widget.scope,
                    deckCardCount: widget.deckCardCount,
                    format: _format,
                    // The scope is gone, so the sheet has stopped being able to
                    // act on a format (W3 state 7). The options stay readable —
                    // they are the record of what was asked for — but a control
                    // that can no longer change anything must not still take
                    // taps.
                    isFormatEnabled: phase != CardExportPhase.invalidScope,
                    failure: failure,
                    onFormatSelected: (next) => setState(() => _format = next),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CardExportActionBarWidget(
                phase: phase,
                cardCount: count,
                onCancel: () {
                  _cancelExport(ref, widget.deckId);
                  widget.onClose(null);
                },
                onSubmit: phase == CardExportPhase.invalidScope
                    ? null
                    : () => _submitExport(
                        ref,
                        widget.deckId,
                        CardExportRequest(
                          deckId: widget.deckId,
                          scope: widget.scope,
                          format: _format,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything above the action row, as bands of one content column (W5).
///
/// **Three groups, and the gaps say so.** W2 lists eight items but they read as
/// three questions — what is being exported, in which format, and what the file
/// will and will not hold. Every gap here used to be `lg`, which is also the
/// gap between two list rows, so the three groups had nothing separating them
/// from their own internals. `AppSpacing.xl` is the scale's step "between
/// sections of a screen" and it is what divides them now; `md`/`sm`/`xs` stay
/// inside a group.
class _Body extends StatelessWidget {
  const _Body({
    required this.scope,
    required this.deckCardCount,
    required this.format,
    required this.isFormatEnabled,
    required this.failure,
    required this.onFormatSelected,
  });

  final CardExportScope scope;
  final int deckCardCount;
  final CardTransferFormat format;
  final bool isFormatEnabled;
  final Failure? failure;
  final ValueChanged<CardTransferFormat> onFormatSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final band = failure;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            l10n.cardExportEntryAction,
            style: context.texts.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CardExportScopeSummaryWidget(
          scope: scope,
          deckCardCount: deckCardCount,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.cardExportFormatHeading,
          style: context.texts.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CardExportFormatOptionsWidget(
          selected: format,
          isEnabled: isFormatEnabled,
          onSelected: onFormatSelected,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CardExportContentLinesWidget(),
        if (band != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          CardExportErrorBandWidget(failure: band),
        ],
      ],
    );
  }
}
