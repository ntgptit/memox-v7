import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
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
        Text(
          context.l10n.cardImportChooseSourceHeading,
          style: context.texts.labelLarge!.inked(context, AppInk.quiet),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SourceOptions(deckId: deckId, kind: kind),
        const SizedBox(height: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.lg),
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
    return MxCard.raised(
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

    return MxCard.raised(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            Icons.note_add_outlined,
            size: AppSpacing.xxl,
            color: AppInk.quiet.resolve(context),
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
