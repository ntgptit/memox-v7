import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_form_sheet.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/tag_catalog_failure.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';
import '../../../domain/models/tag_name_model.dart';
import '../../controllers/tag_catalog_controller.dart';
import '../../controllers/tag_write_controller.dart';
import '../../states/tag_catalog_state.dart';
import '../support/tag_labels_widget.dart';

/// Opens the rename form for one tag (UC-18, wireframe M4.14 W4).
///
/// `showMxFormSheet` resets the controller from the tap that opens the sheet —
/// never from a life-cycle callback — so a reopened form starts clean without
/// racing an `autoDispose` disposal.
Future<void> showTagRenameSheet(
  BuildContext context, {
  required TagCatalogEntry tag,
  required void Function(TagRenameOutcome outcome) onDone,
}) => showMxFormSheet(
  context,
  reset: (container) =>
      container.read(tagRenameProvider(tag.id).notifier).reset(),
  builder: (sheetContext, ref, close) =>
      _RenameForm(tag: tag, onClose: close, onDone: onDone),
);

class _RenameForm extends ConsumerStatefulWidget {
  const _RenameForm({
    required this.tag,
    required this.onClose,
    required this.onDone,
  });

  final TagCatalogEntry tag;
  final VoidCallback onClose;
  final void Function(TagRenameOutcome outcome) onDone;

  @override
  ConsumerState<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends ConsumerState<_RenameForm> {
  late final TextEditingController _input =
      TextEditingController(text: widget.tag.name)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.tag.name.length,
        );

  /// The typed name, folded — recomputed as the user types so the merge
  /// disclosure can appear **before** they confirm (M4.14 W4 item 3).
  String _draft = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.tag.name;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// The tag the typed name would merge into, or null.
  ///
  /// **Derived from the catalog the screen already holds, and it is disclosure
  /// only.** The authoritative decision belongs to the transaction, which reads
  /// the folded name at the moment of the write (BR-234) — this cannot be that,
  /// because a sheet open for thirty seconds is describing a database from
  /// thirty seconds ago. What it can do is stop the user finding out afterwards.
  ///
  /// Folded through `TagName`, never `toLowerCase()` by hand: the identity BR-93
  /// defines has one owner, and comparing by hand here would make this a second.
  ///
  /// The typed side goes through `parse`, so a name the field is about to
  /// refuse — blank, too long, carrying a control character — discloses nothing:
  /// there is no merge to disclose for a rename that cannot happen. The stored
  /// side goes through `fold`, because a row already in the database is not
  /// input being validated.
  TagCatalogEntry? _mergeTarget(List<TagCatalogEntry> catalog) {
    final parsed = TagName.parse(_draft).name;
    if (parsed == null) return null;

    for (final entry in catalog) {
      if (entry.id == widget.tag.id) continue;
      if (parsed.folded == TagName.fold(entry.name)) return entry;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = tagRenameProvider(widget.tag.id);
    final rename = ref.watch(provider);
    final catalog =
        ref.watch(allTagsProvider).value ?? const <TagCatalogEntry>[];
    final target = _mergeTarget(catalog);
    final failure = rename.submit.failure;

    ref.listen<TagRenameSubmitState>(provider, (previous, next) {
      if (!next.submit.shouldClose || (previous?.submit.shouldClose ?? false)) {
        return;
      }
      widget.onClose();
      final outcome = next.outcome;
      if (outcome != null) widget.onDone(outcome);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.lg,
      children: <Widget>[
        Text(context.l10n.tagRenameTitle, style: context.texts.titleMedium),
        MxTextField(
          controller: _input,
          label: context.l10n.tagRenameFieldLabel,
          maxLength: TagName.maxLength,
          shouldAutofocus: true,
          isEnabled: !rename.submit.isSubmitting,
          errorText: context.tagProblemLabel(rename.submit.problem),
          onChanged: (value) => setState(() => _draft = value),
          onSubmitted: (_) => _submit(),
        ),
        if (target != null) _MergeNotice(targetName: target.name),
        if (failure != null)
          _FailureBand(message: context.tagCatalogWriteFailure(failure)),
        // `MxButtonPair` keeps the stacking `OverflowBar` was here for — a
        // button is a non-flex child of a `Row`, so its label cannot wrap, and
        // at textScale 2.0 `Cancel` + `Merge tags` measure 346dp, over the
        // column at 360dp and below (M4.14 G9, R) — and draws the two at one
        // size, which the bar's per-label sizing could not.
        MxButtonPair(
          secondary: MxActionButton(
            label: context.l10n.commonCancelAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: rename.submit.isSubmitting ? null : widget.onClose,
          ),
          primary: MxActionButton(
            // The label is the last thing read before the action happens, so
            // it says which of the two will happen (M4.14 W4 item 4).
            // Relabelled while a failure is showing: the only way to retry
            // was to notice the button was still enabled and press the same
            // word again, which reads as "it did not register my tap".
            label: failure != null
                ? context.l10n.retryAction
                : target == null
                ? context.l10n.tagRenameAction
                : context.l10n.tagMergeAction,
            isLoading: rename.submit.isSubmitting,
            onPressed: rename.submit.canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }

  void _submit() =>
      ref.read(tagRenameProvider(widget.tag.id).notifier).submit(_input.text);
}

/// The merge disclosure (BR-234, M4.14 W4 item 3).
///
/// Info, not warning: a merge is a thing the user asked for by typing the other
/// name, and dressing it in error colours would make the ordinary case look
/// broken. It names the **target**, because "this will merge" without saying
/// into what is not a disclosure.
class _MergeNotice extends StatelessWidget {
  const _MergeNotice({required this.targetName});

  final String targetName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Announced when it appears: a sighted user sees the band arrive as they
      // type, and a reader has to be told.
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: <Widget>[
          const MxIcon(Icons.merge, size: MxIconSize.sm),
          Expanded(
            child: Text(
              context.l10n.tagMergeNotice(targetName),
              style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            ),
          ),
        ],
      ),
    );
  }
}

/// A write that failed, in the sheet — the form keeps what was typed (M4.14 W4
/// item 6).
///
/// **A band, not a red line of text.** W4 item 6 says "dải lỗi … có Try again",
/// and this app has settled on one grammar for an in-flow failure: an
/// `errorContainer` card, flat, `md` padding, a warning glyph, a title and a
/// message, with the recovery as a control rather than a sentence. Three
/// widgets already speak it — `card_export_error_band_widget.dart` in this very
/// feature, plus the Settings and reminder bands unified at D24. A fourth
/// dialect one sheet away is the seam that pass was about.
///
/// The recovery here is the sheet's own primary, which relabels itself to
/// `Retry` while a failure is showing — the same move
/// `card_export_action_bar_widget.dart` makes, and the reason this band carries
/// no button of its own.
class _FailureBand extends StatelessWidget {
  const _FailureBand({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: MxCard.feedback(
        tone: MxCardFeedbackTone.danger,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const MxIcon(
              Icons.error_outline,
              ink: AppInk.onErrorContainer,
              size: MxIconSize.mdCompact,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.tagWriteErrorTitle,
                    style: context.texts.titleSmall!.inked(
                      context,
                      AppInk.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: context.texts.bodySmall!.inked(
                      context,
                      AppInk.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
