import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../../states/card_import_state.dart';
import '../support/card_import_labels_widget.dart';
import 'card_import_source_summary_widget.dart';

/// Free functions for the same reason the screen's are: a `ref.read`
/// written inline in `build()` is indistinguishable from the unsubscribed
/// read the guard forbids.
void _chooseSourceKind(
  WidgetRef ref,
  String deckId,
  CardImportSourceKind kind,
) => ref.read(cardImportSourceChoiceProvider(deckId).notifier).choose(kind);

Future<void> _pickImportFile(WidgetRef ref, String deckId) =>
    ref.read(cardImportFilePickChoiceProvider(deckId).notifier).pick();

/// Removing the picked file (state 1's trailing X): invalidation puts the
/// pick notifier back to its built default — file gone, any pick failure
/// gone with it — and the derived document and preview fall out of existence
/// on their own, exactly the way `resetCardImportDraft` clears the whole
/// draft. No widget mutates provider state by hand.
void _removePickedFile(WidgetRef ref, String deckId) =>
    ref.invalidate(cardImportFilePickChoiceProvider(deckId));

/// Step 1 — choose a source (wireframe M4.12 W2).
///
/// The paste box's [TextEditingController] belongs to the *screen*, not this
/// section: the section unmounts when the wizard moves to Preview, and the
/// pasted rows must survive that round trip (I4).
class CardImportSourceStepWidget extends ConsumerWidget {
  const CardImportSourceStepWidget({
    required this.deckId,
    required this.pasteController,
    super.key,
  });

  final String deckId;
  final TextEditingController pasteController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(cardImportSourceChoiceProvider(deckId));
    final pick = ref.watch(cardImportFilePickChoiceProvider(deckId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The section-label grammar every Card Detail band opens with: the
        // tracked uppercase `sectionLabel` on quiet ink. `labelLarge` at
        // sentence case read as a row of content, not as the name of a group
        // — which mattered here more than anywhere, because everything under
        // it *is* one group: the choice, its work surface, its guidance.
        Text(
          context.l10n.cardImportChooseSourceHeading.toUpperCase(),
          style: context.textStyles.sectionLabel.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SourceOptions(deckId: deckId, kind: kind),
        const SizedBox(height: AppSpacing.md),
        if (kind == CardImportSourceKind.upload)
          _UploadPanel(deckId: deckId, pick: pick)
        else
          MxTextField(
            controller: pasteController,
            label: context.l10n.cardImportPasteLabel,
            hintText: context.l10n.cardImportPastePlaceholder('\n'),
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
          ),
        // `xl` between sections, `md` inside one (Card Detail's rhythm): the
        // options and the work surface are one decision, the info panel is
        // its quiet aside.
        const SizedBox(height: AppSpacing.xl),
        const _InfoPanel(),
      ],
    );
  }
}

/// The two source cards as one band.
///
/// **They fill the content column or they stack — they never sit inboard of
/// it.** A `Wrap` was the first shape here, and a Wrap sizes its children to
/// their *intrinsic* width: two 164dp cards left ~25dp of dead space at the
/// right of a 361dp column, so the row read as indented against every other
/// band while every gate stayed green (M99.19a review finding V9). Equal
/// halves are also what makes the pair read as a pair.
///
/// The choice is measured, like the stepper's: two columns need twice the
/// card's minimum plus the gap, under the live text scaler. Below that the
/// cards stack full-width rather than shrink into unreadable slivers (W7).
class _SourceOptions extends ConsumerWidget {
  const _SourceOptions({required this.deckId, required this.kind});

  final String deckId;
  final CardImportSourceKind kind;

  /// The narrowest a source card stays readable at 1.0× type: the glyph pair,
  /// the title, and a subtitle that must not wrap to three lines.
  static const double _minCardWidth = 164;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = _SourceOption(
      title: context.l10n.cardImportUploadOptionTitle,
      subtitle: context.l10n.cardImportUploadOptionSubtitle,
      icon: Icons.upload_file_outlined,
      isSelected: kind == CardImportSourceKind.upload,
      onTap: () => _chooseSourceKind(ref, deckId, CardImportSourceKind.upload),
    );
    final paste = _SourceOption(
      title: context.l10n.cardImportPasteOptionTitle,
      subtitle: context.l10n.cardImportPasteOptionSubtitle,
      icon: Icons.content_paste_outlined,
      isSelected: kind == CardImportSourceKind.paste,
      onTap: () => _chooseSourceKind(ref, deckId, CardImportSourceKind.paste),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final fitsSideBySide =
            constraints.maxWidth >= _minCardWidth * scale * 2 + AppSpacing.sm;
        if (!fitsSideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              upload,
              const SizedBox(height: AppSpacing.sm),
              paste,
            ],
          );
        }

        // `IntrinsicHeight` gives `stretch` a height to stretch to: the two
        // cards stay equal when one subtitle wraps and the other does not,
        // which is the difference between a pair and two loose boxes.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: upload),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: paste),
            ],
          ),
        );
      },
    );
  }
}

/// One source card. Selection is a border, a glyph and `selected` semantics —
/// never colour alone, and never a full primary fill (W2).
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // **Flat, not raised — the one shadow this column carried.** Card
    // Detail's rule (D20) is that two competing depths in one scroll view
    // read as a rendering fault, and these two cards were the only elevated
    // surfaces on the step. Flat is also this pair's *recorded* treatment:
    // `MxCard.option`'s own doc notes the owner decision (M99.70) that "the
    // import step keeps the hairline" where the export sheet keeps the
    // control edge — so the recipe here is `flat` + `isSelected`, not
    // `option`.
    return MxCard.flat(
      onTap: onTap,
      // Border, announcement and — the part this site got wrong — the token
      // all come from [MxCard.isSelected]: this card spelled `primary`, the
      // 2.90:1-in-dark border its sibling `card_export_format_options`
      // measured and moved off of. No background tint: the glyph and the
      // border carry the state.
      isSelected: isSelected,
      padding: MxCardPadding.compact,
      // No width constraint of its own: the band above decides whether this
      // card is half a row or a full one, and a minWidth here is what made
      // the pair size to their text instead of to the column.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MxIcon(
                icon,
                // Secondary, not primary: the same selected-mark token the
                // card tile's check uses — dark primary fails contrast as a
                // glyph on dark surfaces.
                ink: isSelected ? AppInk.secondary : AppInk.quiet,
              ),
              if (isSelected) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                const MxIcon(
                  Icons.check_circle,
                  ink: AppInk.secondary,
                  size: MxIconSize.sm,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.texts.titleSmall),
          Text(
            subtitle,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        ],
      ),
    );
  }
}

/// The upload half: a prompt and `Choose file`, or the picked file with a
/// Replace action. A failed pick renders its typed reason *and* keeps the
/// previous file on screen (UC-10 A5/E1).
class _UploadPanel extends ConsumerWidget {
  const _UploadPanel({required this.deckId, required this.pick});

  final String deckId;
  final CardImportFilePick pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = pick.file;
    final failure = pick.failure;

    if (file != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The compact summary replaces the whole upload panel once a file
          // exists (state 1): name, format, size and readiness in one card —
          // tap to replace, X to remove. The Source step reads as done.
          CardImportSourceSummaryWidget(
            title: file.name,
            subtitle: context.l10n.cardImportSourceStatusLine(
              context.l10n.cardImportFileMetaLabel(
                file.format.name.toUpperCase(),
                context.cardImportFileSizeLabel(file.bytes.length),
              ),
              context.l10n.cardImportFileReadyStatus,
            ),
            onReplace: () => _pickImportFile(ref, deckId),
            onRemove: () => _removePickedFile(ref, deckId),
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const MxIcon(
                  Icons.error_outline,
                  ink: AppInk.error,
                  size: MxIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.cardImportFailureLabel(failure),
                    style: context.texts.bodySmall!.inked(
                      context,
                      AppInk.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    // Flat like the rest of the column (D20), and the glyph sits in the
    // same quiet well the summary row and Card Detail's metrics use — a
    // 32px glyph floating free was the empty-state-hero shape this step is
    // told not to be: the panel is a work surface awaiting one action, not
    // a destination.
    return MxCard.flat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const MxIcon(Icons.note_add_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.cardImportChoosePrompt,
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const MxIcon(
                  Icons.error_outline,
                  ink: AppInk.error,
                  size: MxIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.cardImportFailureLabel(failure),
                    style: context.texts.bodySmall!.inked(
                      context,
                      AppInk.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Filled, like the concept: inside this panel the pick *is* the
          // primary move — the sticky bar's single-primary rule is about
          // the wizard's step actions, not this panel's.
          MxActionButton(
            label: context.l10n.cardImportChooseFileAction,
            icon: Icons.folder_open_outlined,
            onPressed: () => _pickImportFile(ref, deckId),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return MxCard.muted(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const MxIcon(Icons.info_outline, size: MxIconSize.sm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.cardImportInfoTitle,
                  style: context.texts.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.cardImportInfoBody, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.cardImportInfoBusinessHint,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
          Text(
            context.l10n.cardImportInfoTagsHint,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        ],
      ),
    );
  }
}
