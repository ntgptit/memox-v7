import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/progress_range_model.dart';

part 'progress_range_controller.g.dart';

/// Which window the screen is currently reading (BR-194).
///
/// **A view choice that costs no query.** Both windows ride on every row of one
/// read, so switching is a field access — no reload, no spinner, and no way for
/// the two windows to describe two different snapshots of the tree.
///
/// **Shared across levels rather than held per level.** Drilling from the library
/// into a deck keeps the window the user chose: the question they are asking has
/// not changed, only which deck it is about. A `family` on the deck id would
/// silently reset the selector on every tap.
///
/// `autoDispose` — the generator default — so leaving the Progress branch
/// entirely returns the selector to [ProgressRange.initial] rather than
/// preserving a choice from a session the user has since left behind.
@riverpod
class ProgressRangeChoice extends _$ProgressRangeChoice {
  @override
  ProgressRange build() => ProgressRange.initial;

  /// A command, not a setter: it is invoked from a callback, never from
  /// `build()`.
  void select(ProgressRange range) => state = range;
}
