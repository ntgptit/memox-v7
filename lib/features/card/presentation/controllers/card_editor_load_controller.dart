import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/entities/card_entity.dart';
import '../providers/card_use_case_provider.dart';

part 'card_editor_load_controller.g.dart';

/// The card the editor prefills from in edit mode (UC-04 A1).
///
/// A future, not a stream — the mirror of `deckDeletionImpact`, and for the same
/// reason. The editor takes a snapshot when it opens and the user edits *that*; a
/// live stream would let an incoming change fight the text the user is typing.
/// A card deleted from elsewhere while the form is open surfaces as a
/// `NotFoundFailure` on save, which is where it matters (see `getCard`).
///
/// `noAutomaticRetry`: a prefill that failed should show its failure, not
/// silently re-run under the user — the editor renders the error and offers a
/// way back, exactly as the delete dialog does with its impact read.
@Riverpod(retry: noAutomaticRetry)
Future<CardEntity> cardToEdit(Ref ref, String cardId) =>
    ref.watch(getCardUseCaseProvider)(cardId);
