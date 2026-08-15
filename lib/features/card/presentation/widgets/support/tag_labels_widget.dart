import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../../domain/failures/tag_catalog_failure.dart';
import '../../../domain/failures/tag_validation_failure.dart';

/// Copy for everything that can go wrong with a tag name, and for a catalog
/// write that failed.
///
/// **One mapping, two surfaces.** The editor's add-tag field and the catalog's
/// rename sheet validate through the same `TagName.parse` and receive the same
/// [TagValidationProblem]s, so a second `switch` would be a second answer to
/// "what does `nameTooLong` say" — and the two would agree right up until one of
/// them was translated again. `support/` because it is display mapping used
/// across buckets (AD-15).
///
/// **Exhaustive on `TagValidationProblem`, deliberately.** No `_` branch: a new
/// problem must fail to compile here rather than arrive silently as no message
/// at all.
extension TagLabels on BuildContext {
  /// The error under a tag input, or null when the field is fine.
  ///
  /// `nameTaken` maps to null on purpose and it is the one that needs saying:
  /// on the add path reuse is silent (BR-93), and on the rename path a taken
  /// name is not an error either — it is a merge, disclosed before the user
  /// confirms (BR-234, M4.14 W4). Nothing raises it as a field problem, and if
  /// something ever does, "no message" is the honest rendering of a rule that
  /// has no refusal behind it.
  String? tagProblemLabel(TagValidationProblem? problem) => switch (problem) {
    TagValidationProblem.nameEmpty => l10n.cardTagEmptyError,
    TagValidationProblem.nameTooLong => l10n.cardTagTooLongError,
    TagValidationProblem.tooManyTags => l10n.cardTagTooManyError,
    TagValidationProblem.nameHasControlCharacter =>
      l10n.cardTagControlCharacterError,
    TagValidationProblem.nameTaken => null,
    null => null,
  };

  /// A rename or delete that failed on the write rather than on the field.
  ///
  /// The vanished-tag case gets its own line: it is not an error the user
  /// caused, and telling them the tag is already gone is more useful than
  /// "something went wrong" (UC-18 E3).
  String tagCatalogWriteFailure(Failure failure) => mxWriteFailure(
    failure,
    onNotFound: (notFound) => switch (notFound.reason) {
      TagCatalogProblem.tagMissing => l10n.tagMissingError,
      _ => l10n.writeErrorMessage,
    },
    onConflict: (_) => l10n.writeErrorMessage,
  );
}
