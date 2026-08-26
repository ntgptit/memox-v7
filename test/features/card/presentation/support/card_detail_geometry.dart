import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_state_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_history_section_widget.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'fake_card_detail_repository.dart';

/// The fixtures and finders both Card Detail geometry files measure against.
///
/// **Shared rather than copied.** The relations split across two files when the
/// guard's size ceiling caught the first one; a second copy of `loaded()` is how
/// two files end up measuring two different cards and calling it one contract.

FakeCardDetailRepository loaded({
  int events = 3,
  bool hasMore = false,
  bool isFlagged = false,
  SchedulerType scheduler = SchedulerType.eightBox,
  int? currentBox = 3,
}) => FakeCardDetailRepository()
  ..seededDetail = fakeCardDetail(
    front: '안녕하세요',
    back: 'hello',
    example: 'an example sentence',
    tagNames: <String>['greeting'],
    isFlagged: isFlagged,
    schedulerType: scheduler,
    currentBox: currentBox,
    easeFactor: scheduler == SchedulerType.sm2 ? 2.5 : null,
    intervalDays: scheduler == SchedulerType.sm2 ? 6 : null,
    repetitions: scheduler == SchedulerType.sm2 ? 2 : null,
    // Distinct counts, so a value can be found by its own text: with both at
    // zero the finder matches two widgets and the assertion is about
    // whichever one it happened to pick.
    answerCount: 7,
    lapseCount: 1,
  )
  ..pages.add(
    events == 0
        ? CardHistoryPageModel.empty
        : fakeHistoryPage(count: events, hasMore: hasMore),
  );

/// The three widths M4.15 W6 names, with the scaler each is checked at.
const surfaces = <(String, Size, double)>[
  ('320dp at 2.0', Size(320, 640), 2),
  ('390dp', Size(390, 844), 1),
  ('412dp', Size(412, 915), 1),
];

Finder heroCard() => find.descendant(
  of: find.byType(CardDetailSummaryWidget),
  matching: find.byType(MxCard),
);

Finder progressPanel() => find.descendant(
  of: find.byType(CardDetailStateWidget),
  matching: find.byType(MxCard),
);

Finder eventCards() => find.descendant(
  of: find.byType(CardHistorySectionWidget),
  matching: find.byType(MxCard),
);
