import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_checkbox_row.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_form_sheet.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';
import '../../../domain/models/tag_filter_model.dart';
import '../../controllers/card_list_tag_filter_controller.dart';
import '../../controllers/tag_catalog_controller.dart';

/// How much of the screen the tag list may claim before it scrolls inside the
/// sheet.
///
/// Half, so the title, the OR line and the action row are all still on screen
/// with a hundred tags loaded (M4.14 G8). A fraction rather than a fixed height
/// because the thing being bounded is *the rest of the sheet*, which grows with
/// the text scale.
const double _kTagListViewportFraction = 0.5;

/// Toggling one tag in the draft, and the two commands the action row runs.
///
/// Free functions rather than closures written inline in `build()`. `ref.read`
/// is the right call — these are commands — but written inline it sits
/// lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription.
void _selectDraft(WidgetRef ref, String deckId, TagFilter next) =>
    ref.read(cardListTagFilterDraftProvider(deckId).notifier).select(next);

/// Applies the draft, **minus any tag that no longer exists**.
///
/// A tag deleted or merged away while the filter was on (BR-234, BR-235) leaves
/// an id that matches nothing, so the list stays empty with no visible reason:
/// the row is not in the sheet either, so there is nothing to untick. Filtering
/// the draft against the catalog this sheet just rendered heals it on the next
/// `Apply` — which is the one moment the two sets are provably in hand at once.
void _applyDraft(
  WidgetRef ref,
  String deckId,
  TagFilter draft,
  List<TagCatalogEntry> catalog,
) => ref
    .read(cardListTagFilterProvider(deckId).notifier)
    .apply(draft.retaining(<String>{for (final entry in catalog) entry.id}));

/// Opens the multi-tag filter for one deck's card list (UC-18, M4.14 W6).
///
/// **A draft, seeded from the applied selection on open** (M4.14 T5). Applying
/// on every tap would re-read the list once per checkbox and reset the window
/// each time (BR-232) — N reads for one intention, with the list jumping behind
/// a sheet the user has not finished with.
///
/// Seeding happens through `showMxFormSheet`'s `reset`, which runs from the tap
/// rather than a life-cycle callback, for the reason that function documents.
Future<void> showCardTagFilterSheet(BuildContext context, String deckId) =>
    showMxFormSheet(
      context,
      reset: (container) => container
          .read(cardListTagFilterDraftProvider(deckId).notifier)
          .select(container.read(cardListTagFilterProvider(deckId))),
      builder: (sheetContext, ref, close) =>
          _TagFilterForm(deckId: deckId, onClose: close),
    );

class _TagFilterForm extends ConsumerWidget {
  const _TagFilterForm({required this.deckId, required this.onClose});

  final String deckId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cardListTagFilterDraftProvider(deckId));
    final tags = ref.watch(allTagsProvider);
    final hasTags = tags.value?.isNotEmpty ?? false;

    // **Three regions, and the gaps say so.** One `spacing: AppSpacing.lg` for
    // the whole column gave the title's own explanatory line the same 16dp as
    // the gap from the tag list down to the action row, so nothing bound the
    // header pair together and nothing divided the three regions — the defect
    // the export sheet in this unit already diagnosed in writing
    // (`card_export_sheet_widget.dart:272-280`: `lg` is also the gap between
    // two list rows, so groups had nothing separating them from their own
    // internals). `xs` is what pairs a sheet title with its subtitle
    // (`starter_install_widget.dart:133`, `study_resume_widget.dart:42`), `xl`
    // is the scale's step between sections of a screen, and `lg` opens an
    // action row (`card_export_sheet_widget.dart:245`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.l10n.tagFilterTitle, style: context.texts.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        // **The one place OR is spelled out.** Two tags widen the result, which
        // is the opposite of what the four state pills next to this control do,
        // and nothing else on the screen says so (BR-231, M4.14 W6 item 2).
        Text(
          context.l10n.tagFilterSubtitle,
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
        ),
        const SizedBox(height: AppSpacing.xl),
        MxAsyncView<List<TagCatalogEntry>>(
          value: tags,
          loadingLabel: context.l10n.tagCatalogLoadingLabel,
          error: (_, _) => MxErrorState(
            title: context.l10n.unexpectedErrorTitle,
            message: context.l10n.tagCatalogError,
            retryLabel: context.l10n.retryAction,
            onRetry: () => ref.invalidate(allTagsProvider),
          ),
          data: (catalog) => catalog.isEmpty
              ? const _NoTags()
              : _TagChoices(deckId: deckId, catalog: catalog, draft: draft),
        ),
        // No action row when there is nothing to choose: `Apply` over an empty
        // list applies the empty selection, which is what closing already does.
        // Its lead-in gap sits inside the same guard — left outside it, the
        // empty and the failed catalog would each end in 16dp of nothing.
        if (hasTags) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _Actions(
            deckId: deckId,
            draft: draft,
            catalog: tags.value ?? const <TagCatalogEntry>[],
            onClose: onClose,
          ),
        ],
      ],
    );
  }
}

/// The rows. The whole row toggles, not just its box (M4.14 G7), and the state
/// is carried by the checkbox and by `Semantics(checked:)` rather than by
/// colour.
class _TagChoices extends ConsumerWidget {
  const _TagChoices({
    required this.deckId,
    required this.catalog,
    required this.draft,
  });

  final String deckId;
  final List<TagCatalogEntry> catalog;
  final TagFilter draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      // The sheet already scrolls; this caps how much of it the list may claim
      // so the action row stays reachable without scrolling past a hundred tags
      // (M4.14 G8).
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height * _kTagListViewportFraction,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: catalog.length,
        itemBuilder: (itemContext, index) {
          final entry = catalog[index];

          return MxCheckboxRow(
            isChecked: draft.contains(entry.id),
            onToggle: () => _selectDraft(ref, deckId, draft.toggled(entry.id)),
            label: entry.name,
            subtitle: itemContext.l10n.tagCardCount(entry.cardCount),
          );
        },
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.deckId,
    required this.draft,
    required this.catalog,
    required this.onClose,
  });

  final String deckId;
  final TagFilter draft;
  final List<TagCatalogEntry> catalog;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(cardListTagDraftCountProvider(deckId)).value;

    // **`MxButtonPair`, which keeps what `OverflowBar` was here for and adds
    // what it could not do.** The bar was chosen because a button is a non-flex
    // child of a `Row`, so its label cannot wrap: at textScale 2.0 these two
    // measure 383dp against a 361dp column at 393dp, and 95dp over at 320dp — a
    // `RenderFlex overflowed`, not a tight fit (M4.14 G9, R). The pair stacks
    // at exactly that point, and where the bar sized each action to its own
    // label — `Clear` small beside `Apply · 128` — it splits the row evenly and
    // matches their heights.
    return MxButtonPair(
      secondary: MxActionButton(
        label: context.l10n.tagFilterClearAction,
        variant: MxActionButtonVariant.secondary,
        onPressed: draft.isActive
            ? () => _selectDraft(ref, deckId, TagFilter.none)
            : null,
      ),
      primary: MxActionButton(
        // The count answers the question the user actually has — "is this
        // going to show me anything?" — before they close the sheet to find
        // out (M4.14 T6). Until it lands the button is the bare verb rather
        // than a flickering zero.
        label: matches == null
            ? context.l10n.tagFilterApplyAction
            : context.l10n.tagFilterApplyActionCount(matches),
        onPressed: () {
          _applyDraft(ref, deckId, draft, catalog);
          onClose();
        },
      ),
    );
  }
}

/// No tags exist at all — the same answer the catalog gives (M4.14 W6 item 6).
class _NoTags extends StatelessWidget {
  const _NoTags();

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.sell_outlined,
      title: context.l10n.tagCatalogEmptyTitle,
      message: context.l10n.tagCatalogEmptyMessage,
    );
  }
}
