import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/fill_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'study_commit_stub.dart';
import 'study_widget_harness.dart';

/// The fixture and the three questions every `fill` test asks of the screen.
///
/// Shared between `fill_widget_test.dart` (the direction and what a submit
/// costs) and `fill_answer_surface_test.dart` (the card that is the field), so
/// the two halves cannot drift into testing two different screens.

/// One `fill` turn, in the shape the product actually stores (BR-08): `front`
/// holds the Korean term, `back` holds the gloss.
///
/// The suite before this one had `front: 'front-c1'` and graded against the
/// back, so every assertion in it was true of a card the app cannot hold and of
/// a direction the mode does not run in.
StudyTurnModel fillTurnOf(
  String id, {
  String front = '사과',
  String back = 'quả táo',
  String? hint,
  String? example,
  int round = 1,
}) => StudyTurnModel(
  item: StudyQueueItemEntity(
    sessionId: 's1',
    mode: StudyMode.fill,
    round: round,
    cardId: id,
    position: 0,
    status: StudyQueueItemStatus.pending,
    availableAt: 0,
    answersInSession: 0,
    remainingMs: null,
    isRevealed: false,
    direction: null,
  ),
  progress: StudyStageProgressModel(
    round: round,
    done: 0,
    total: 1,
    completedCardIds: const <String>[],
  ),
  card: StudyCardModel(
    id: id,
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: null,
    // The folded columns as the database holds them (BR-134): the same policy
    // `FillModeHandler.fold` applies, applied once at write time.
    frontFolded: front.trim().toLowerCase(),
    backFolded: back.trim().toLowerCase(),
  ),
);

/// Pumps the section on [turn] and hands back the list every graded outcome
/// lands in. Each write commits.
Future<List<FillOutcome>> pumpFill(
  WidgetTester tester,
  StudyTurnModel turn,
) async {
  final graded = <FillOutcome>[];
  await tester.pumpWidget(
    wrapForTest(
      FillAnswerSectionWidget(
        turn: turn,
        onGraded: (outcome) async {
          graded.add(outcome);

          return commitOf(turn.cardId);
        },
      ),
      isScrollable: false,
    ),
  );

  return graded;
}

/// The lower of the two cards — the one that is the field.
Finder fillAnswerCard() => find.byType(MxCard).last;

bool isFillFieldFocused(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
    false;

/// The Check button as a button rather than as its label, so a test can read
/// whether it is enabled.
Finder fillCheckButton() => find.ancestor(
  of: find.text('Check'),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);
