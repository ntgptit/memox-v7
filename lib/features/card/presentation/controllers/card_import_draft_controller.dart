import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/models/card_transfer_mapping_model.dart';
import '../../domain/models/card_transfer_field_model.dart';
import '../providers/card_import_use_case_provider.dart';
import '../states/card_import_state.dart';
import 'card_import_query_controller.dart';

part 'card_import_draft_controller.g.dart';

/// The import wizard's draft, as **seven one-value notifiers** rather than one
/// draft object (UC-10, wireframe M4.12).
///
/// Deliberate, and the CQS taxonomy is why: an input-state notifier is one
/// value and one way to change it, and a wizard is exactly a set of such
/// values — the step, the source kind, the pasted text, the picked file, the
/// sheet, the header flag, the duplicate policy. One draft notifier holding
/// all seven would be the God Controller `notifier_kinds_test.dart` counts
/// against; seven small ones cost seven families and buy that each value has
/// one owner, one reset story, and a build that states its own dependencies.
///
/// All are keyed by deck id, so two decks' drafts cannot bleed into each
/// other, and `resetCardImportDraft` below is the one place "Import another
/// file" enumerates them.
@riverpod
class CardImportStepChoice extends _$CardImportStepChoice {
  @override
  CardImportStep build(String deckId) => CardImportStep.source;

  /// Steps move only through this — the stepper itself is not tappable onto
  /// an unvalidated step (wireframe I2); the primary actions call this.
  void go(CardImportStep step) => state = step;
}

@riverpod
class CardImportSourceChoice extends _$CardImportSourceChoice {
  @override
  CardImportSourceKind build(String deckId) => CardImportSourceKind.upload;

  void choose(CardImportSourceKind kind) => state = kind;
}

/// The pasted rows. Written when the user asks for a preview — never per
/// keystroke (wireframe I4) — and kept across a parse failure, so bad rows
/// cost a correction, not a re-paste.
@riverpod
class CardImportPastedText extends _$CardImportPastedText {
  @override
  String build(String deckId) => '';

  void update(String text) => state = text;
}

/// The picked file, with the pick flow as its one mutator: the outcome of a
/// pick *is* this value. Cancel keeps everything (UC-10 A5); an unsupported
/// file keeps the previous file and carries the refusal (E1).
@riverpod
class CardImportFilePickChoice extends _$CardImportFilePickChoice {
  @override
  CardImportFilePick build(String deckId) => const CardImportFilePick();

  Future<void> pick() async {
    try {
      final file = await ref.read(pickCardImportSourceUseCaseProvider)();
      if (!ref.mounted || file == null) return;
      state = state.withFile(file);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.withFailure(failure);
    }
  }
}

/// The chosen XLSX sheet name; null means the document's default (UC-10 A2).
@riverpod
class CardImportSheetChoice extends _$CardImportSheetChoice {
  @override
  String? build(String deckId) => null;

  void select(String? name) => state = name;
}

/// Whether the first row is a header (UC-10 A3). Defaults on, as most
/// exported spreadsheets carry one.
@riverpod
class CardImportHeaderChoice extends _$CardImportHeaderChoice {
  @override
  bool build(String deckId) => true;

  void update({required bool hasHeader}) => state = hasHeader;
}

/// Include-duplicates (BR-170). Defaults off: skipping is the safe reading of
/// "import this file again".
@riverpod
class CardImportDuplicateChoice extends _$CardImportDuplicateChoice {
  @override
  bool build(String deckId) => false;

  void update({required bool shouldIncludeDuplicates}) =>
      state = shouldIncludeDuplicates;
}

/// The column mapping (UC-10 step 4).
///
/// Builds its default by watching the parsed document: header on → auto-map
/// by name, header off → empty, so the user assigns by position. Watching
/// rather than being told means a sheet or header change resets the mapping
/// with no call site to forget — a mapping made for one sheet's columns
/// applied to another's is the same trap as a selection surviving a filter
/// change (BR-167's reasoning, one feature over).
@riverpod
class CardImportMappingDraft extends _$CardImportMappingDraft {
  @override
  CardTransferMapping build(String deckId) {
    final document = ref.watch(cardImportDocumentProvider(deckId));
    final hasHeader = ref.watch(cardImportHeaderChoiceProvider(deckId));
    final sheetName = ref.watch(cardImportSheetChoiceProvider(deckId));

    final sheet = document.value?.sheetNamed(sheetName);
    if (sheet == null || sheet.rows.isEmpty || !hasHeader) {
      return const CardTransferMapping.empty();
    }

    return CardTransferMapping.fromHeader(sheet.rows.first.cells);
  }

  void assign(int column, CardTransferField? field) =>
      state = state.assign(column, field);
}
