import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
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
  void dispose() {
    _input.dispose();
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
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              context.l10n.cardEditorTagsLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            // The counter appears only once a tag exists: at zero it is a limit
            // nobody is near, and showing 0 / 10 is noise (W5).
            if (tags.isNotEmpty)
              Text(
                context.l10n.cardEditorTagCount(tags.length, kMaxTagsPerCard),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final tag in tags)
                Chip(
                  label: Text(tag.name),
                  onDeleted: () => ref
                      .read(cardTagRemoveProvider(cardId).notifier)
                      .submit(tag.id),
                  deleteButtonTooltipMessage: context.l10n
                      .cardEditorTagRemoveSemantics(tag.name),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        MxTextField(
          controller: _input,
          label: context.l10n.cardEditorTagAddHint,
          hintText: context.l10n.cardEditorTagAddHint,
          maxLength: TagName.maxLength,
          textInputAction: TextInputAction.done,
          errorText: _error(entry.problem),
          isEnabled: !entry.isSubmitting,
          onSubmitted: (value) =>
              ref.read(cardTagEntryProvider(cardId).notifier).submit(value),
        ),
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
}
