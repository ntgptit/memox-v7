import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_text_button.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../controllers/deck_list_view_controller.dart';
import '../states/deck_list_view_state.dart';
import 'deck_level_summary_widget.dart';

/// Setting the panel's visibility, bound to a `ref`.
///
/// A free function rather than a closure written inline in `build()`. `ref.read`
/// is the right call — showing or hiding is a command, and a `watch` inside a
/// callback would subscribe the widget to a value it is about to set — but
/// written inline it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription.
VoidCallback _setSummaryVisible(WidgetRef ref, {required bool isVisible}) =>
    () => ref
        .read(deckSummaryVisibilityChoiceProvider.notifier)
        .setVisible(isVisible: isVisible);

/// The level summary, or the one line that brings it back.
///
/// **Something is always here.** A panel that vanished without trace would leave
/// the user no way back to it and no reason to believe it had ever been there;
/// the link is what makes dismissing it a preference rather than a loss.
class DeckSummarySectionWidget extends ConsumerWidget {
  const DeckSummarySectionWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A level with nothing in it has an empty state that says more than a
    // summary of nothing would, and nothing to bring back either.
    if (!DeckLevelSummaryWidget.hasContent(snapshot)) {
      return const SizedBox.shrink();
    }

    // **`auto` is resolved here, not in the notifier.** The notifier holds a
    // preference and knows nothing about any level; whether that preference puts
    // a panel on screen depends on the snapshot this widget was handed. Pushing
    // the snapshot into the notifier to resolve it there would make a global
    // choice carry one level's data, and the wrong level's the moment two are
    // alive during a route transition.
    final isVisible = switch (ref.watch(deckSummaryVisibilityChoiceProvider)) {
      DeckSummaryVisibility.shown => true,
      DeckSummaryVisibility.hidden => false,
      DeckSummaryVisibility.auto => DeckLevelSummaryWidget.hasDue(snapshot),
    };

    return Padding(
      // **`sm` above, redistributed from below — the total is fixed.** The
      // shell's strip pads only `xs` under the search field (a 320×2.0
      // overflow trade — see `_MxSubheader`), and with a top of zero here the
      // whole separation between the search pill and this card was 4px: two
      // same-width, same-radius surfaces reading as one glued blob. Taking the
      // `sm` out of the bottom instead of adding it keeps every body pixel
      // below this section where it was, so the last row's clearance from the
      // floating action — 7px, per the shell's own audit — is untouched. The
      // cost is the section break below going `xl` to `lg`; the toolbar still
      // reads as controls, not as the first row, because the rows carry their
      // own surfaces. `deck_list_spacing_test.dart` measures the gap above.
      //
      // **The bottom drops one step on a compact screen.** The other half of
      // the 17 pixels the breadcrumb strip cost the pinned chrome at 320 with
      // `textScaler` 2.0; the toolbar's own section break gives the first half.
      // Taken from below rather than above because the gap above is the one
      // `deck_list_spacing_test.dart` measures, and because moving body pixels
      // *up* only increases the last row's clearance from the floating action.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)
            ? AppSpacing.sm
            : AppSpacing.lg,
      ),
      child: isVisible
          ? DeckLevelSummaryWidget(
              snapshot: snapshot,
              onDismiss: _setSummaryVisible(ref, isVisible: false),
            )
          // No `Align` around it: `MxTextButton` starts its own label and takes
          // no padding, so the link lands on the same vertical line as the
          // cards below it. The `Align` existed to undo a centring that the
          // bare `TextButton`'s 64px minimum width imposed.
          : MxTextButton(
              label: context.l10n.deckSummaryShowAction,
              trailingIcon: Icons.expand_more,
              onPressed: _setSummaryVisible(ref, isVisible: true),
            ),
    );
  }
}
