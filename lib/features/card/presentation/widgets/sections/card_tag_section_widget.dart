import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/entities/tag_entity.dart';
import '../../../domain/failures/tag_validation_failure.dart';
import '../../../domain/models/tag_name_model.dart';
import '../../controllers/card_tag_controller.dart';
import '../../states/card_tag_state.dart';
import '../support/tag_labels_widget.dart';

/// The editor's tag strip: the card's tags as removable chips, and a field that
/// adds one (UC-04 W5, BR-93, BR-94).
///
/// Edit-mode only — a tag links to a card, and a card that is not saved yet has
/// no id to link to. The chips read `cardTagsProvider`, so an add or a remove
/// shows without a reload; the field drives `CardTagEntry`, which reports the
/// same `savedAndContinue` a save-and-add form does, so the field clears and
/// stays open for the next tag.
///
/// **It says out loud that it saves on its own** (owner review, 2026-08-26).
/// This section sits below the form's fields, and the form's Save now sits
/// pinned under it — so without a word saying otherwise a reader has every
/// reason to think a typed tag is waiting on that button. It is not: the add
/// and the remove are each their own write, and the note under the heading is
/// the only thing that distinguishes the two halves of this screen.
class CardTagSectionWidget extends ConsumerStatefulWidget {
  const CardTagSectionWidget({required this.cardId, super.key});

  final String cardId;

  @override
  ConsumerState<CardTagSectionWidget> createState() =>
      _CardTagSectionWidgetState();
}

class _CardTagSectionWidgetState extends ConsumerState<CardTagSectionWidget> {
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The add button is enabled by what has been typed, so the section has to
    // rebuild as the field changes.
    _input.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _input
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  /// The field error, from the mapping the rename sheet also uses.
  ///
  /// It was a `switch` here until the catalog needed the same five answers
  /// (M99.30); `TagLabels.tagProblemLabel` is now the one copy, and it carries
  /// the note about why `nameTaken` has no message.
  String? _error(TagValidationProblem? problem) =>
      context.tagProblemLabel(problem);

  Widget _writeFailure(Failure failure) => Semantics(
    liveRegion: true,
    child: Text(
      context.mxWriteFailure(
        failure,
        onNotFound: (_) => context.l10n.writeErrorMessage,
        onConflict: (_) => context.l10n.writeErrorMessage,
      ),
      style: context.texts.bodySmall?.copyWith(color: context.colors.error),
    ),
  );

  void _submitTag() => ref
      .read(cardTagEntryProvider(widget.cardId).notifier)
      .submit(_input.text);

  @override
  Widget build(BuildContext context) {
    final cardId = widget.cardId;
    final tags = ref.watch(cardTagsProvider(cardId)).value ?? <TagEntity>[];
    final entry = ref.watch(cardTagEntryProvider(cardId));
    final remove = ref.watch(cardTagRemoveProvider(cardId));

    ref.listen<CardTagSubmitState>(cardTagEntryProvider(cardId), (
      previous,
      next,
    ) {
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _input.clear();
        ref.read(cardTagEntryProvider(cardId).notifier).reset();
      }
    });

    final isFull = tags.length >= kMaxTagsPerCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              context.l10n.cardEditorTagsLabel,
              style: context.texts.labelLarge,
            ),
            const Spacer(),
            // The counter appears only once a tag exists: at zero it is a limit
            // nobody is near, and showing 0 / 10 is noise (W5).
            if (tags.isNotEmpty)
              Text(
                context.l10n.cardEditorTagCount(tags.length, kMaxTagsPerCard),
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.cardEditorTagsSaveNote,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _chips(tags),
        ],
        const SizedBox(height: AppSpacing.sm),
        _entry(entry, isFull: isFull),
        if (entry.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _writeFailure(entry.failure!),
        ],
        if (remove.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _writeFailure(remove.failure!),
        ],
      ],
    );
  }

  /// The card's tags, each with the delete affordance that removes it.
  Widget _chips(List<TagEntity> tags) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: <Widget>[
      for (final tag in tags)
        Chip(
          label: Text(tag.name),
          onDeleted: () => ref
              .read(cardTagRemoveProvider(widget.cardId).notifier)
              .submit(tag.id),
          deleteButtonTooltipMessage: context.l10n.cardEditorTagRemoveSemantics(
            tag.name,
          ),
          // **The delete glyph gets a real touch target, and the
          // chip grows to hold it.** Material sizes that hit region
          // from the delete icon — `AppIconSize.sm`, so 16px for the
          // one control on this screen that removes something, a
          // third of the floor `AppSpacing.minimumTouchTarget` names.
          // `MaterialTapTargetSize.padded` does not fix it: the theme
          // already sets it, and it only pads the chip vertically.
          //
          // **The three values below are one calculation, which is
          // why they are set together.** `_RenderChip` sizes its
          // content box as `max(32 - padding.vertical +
          // labelPadding.vertical, labelHeight +
          // labelPadding.vertical)` and asserts the delete box is no
          // taller than it. Dropping the theme's vertical padding to
          // zero and giving the label 8 top and bottom makes that
          // `max(48, labelHeight + 16)` — so the content box *is* the
          // touch target, the chip measures 48 rather than the theme's
          // 32, and a 48-square delete box fits exactly. A large text
          // scale grows the first term; the delete box stays 48 and
          // still fits.
          deleteIconBoxConstraints: const BoxConstraints.tightFor(
            width: AppSpacing.minimumTouchTarget,
            height: AppSpacing.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          labelPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
    ],
  );

  /// The add-tag field, or the line that replaces it at the limit.
  ///
  /// **The field goes away rather than accepting a tag it will refuse.**
  /// BR-94's ceiling used to be discoverable only by typing an eleventh tag and
  /// reading the error afterwards; this states the rule and the way out of it
  /// before any of that (owner review, 2026-08-26).
  Widget _entry(CardTagSubmitState entry, {required bool isFull}) {
    if (isFull) {
      return Text(
        context.l10n.cardEditorTagLimitReached,
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }

    return MxTextField(
      controller: _input,
      label: context.l10n.cardEditorTagAddHint,
      hintText: context.l10n.cardEditorTagAddHint,
      maxLength: TagName.maxLength,
      textInputAction: TextInputAction.done,
      errorText: _error(entry.problem),
      isEnabled: !entry.isSubmitting,
      onSubmitted: (_) => _submitTag(),
      // The same submit the keyboard's done key runs, made visible. The field
      // had no button at all, so a user who typed a tag had nothing on screen
      // to press.
      suffixAction: IconButton(
        icon: const Icon(Icons.add),
        tooltip: context.l10n.cardEditorTagAddAction,
        onPressed: entry.isSubmitting || _input.text.trim().isEmpty
            ? null
            : _submitTag,
      ),
    );
  }
}
