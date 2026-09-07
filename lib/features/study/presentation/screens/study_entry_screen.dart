import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'study_session_screen.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_reading_column.dart';
import '../../../../shared/widgets/mx_sheet.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/failures/study_refusal_failure.dart';
import '../../domain/models/study_deck_context_model.dart';
import '../../domain/models/study_direction_model.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_review_options_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../controllers/study_deck_context_controller.dart';
import '../controllers/study_entry_controller.dart';
import '../controllers/study_resume_controller.dart';
import '../controllers/study_review_options_controller.dart';
import '../widgets/overlays/study_direction_chooser_widget.dart';
import '../widgets/overlays/study_mode_chooser_widget.dart';
import '../widgets/overlays/study_resume_widget.dart';
import '../widgets/sections/study_entry_section_widget.dart';

/// The way into a deck's study flow.
///
/// Replaces the placeholder that stood here since M3. It shows the two counts of
/// BR-150, and offers only the ways in that are actually open: with nothing due,
/// there is no review entry at all (BR-29, BR-145).
class StudyEntryScreen extends ConsumerStatefulWidget {
  const StudyEntryScreen({
    required this.deckId,
    required this.optionsRouteName,
    required this.homeRouteName,
    super.key,
  });

  final String deckId;

  /// The options route to push, named by whichever route table entry built this
  /// screen — `deckStudyOptions` in the Library branch, `studyDeckOptions` in
  /// the Study branch.
  ///
  /// **Passed in rather than worked out here.** This screen is mounted twice,
  /// and the two mounts differ in the only thing a route decides: which branch
  /// a push lands in. A single options route would move the bottom bar's
  /// selected tab whenever it was opened from the other branch, because
  /// `StatefulNavigationShell` takes its index from the branch that owns the
  /// matched route. The branch is the route's fact, so the route table is what
  /// says it; a screen guessing from its own location would be the same fact
  /// written down twice.
  final String optionsRouteName;

  /// Where this screen goes when its deck stops existing — the home of the
  /// branch it is mounted in.
  ///
  /// **Named by the route table for the same reason [optionsRouteName] is.**
  /// The screen is mounted twice and only the branch differs, so the honest
  /// landing differs too: from the Study tab the deck's disappearance leaves
  /// the user at Study Home, from the Library tab at the deck list. The screen
  /// cannot work that out without reading its own location, which is the fact
  /// the route already owns.
  ///
  /// **Not a pop.** `/decks/<id>/study` pops onto `/decks/<id>` — the deleted
  /// deck's own screen — so the one call that looks simplest lands on the next
  /// route up that is equally gone. A named destination is the only one that
  /// is deterministic from either mount.
  final String homeRouteName;

  @override
  ConsumerState<StudyEntryScreen> createState() => _StudyEntryScreenState();
}

class _StudyEntryScreenState extends ConsumerState<StudyEntryScreen> {
  String get deckId => widget.deckId;
  String get optionsRouteName => widget.optionsRouteName;

  /// Set the first time the unwind is scheduled, so it happens exactly once.
  ///
  /// The deleted-deck emission is sticky — the stream keeps reporting `null`,
  /// and the screen keeps being rebuilt while it waits for the frame — so
  /// without this the navigation would be requested on every rebuild between
  /// the deletion and the route actually changing.
  bool _isUnwinding = false;

  @override
  void initState() {
    super.initState();

    // After the first frame, because reading the resume controller closes any
    // session left by an earlier study day, and a write during build is what
    // Riverpod forbids.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_offerResume()),
    );
  }

  /// Offers the three paths, and only when there is something to resume.
  ///
  /// **Nothing open means nothing is shown** — not an empty sheet, not a sheet
  /// with one button. The other two paths already live on this screen, so a
  /// sheet with no session to continue would be a second copy of the screen
  /// behind it.
  ///
  /// Learning and reviewing go through the ordinary path from here. Ending the
  /// open session is not done at this call site on purpose: it lives inside
  /// `StartStudySessionUseCase`, where no caller can forget it (BR-103).
  Future<void> _offerResume() async {
    final open = await _openSession();
    if (open == null || !mounted) return;

    final choice = await showMxSheet<StudyResumeChoice>(
      context,
      builder: (sheetContext) => StudyResumeWidget(
        onChoice: (value) => Navigator.of(sheetContext).pop(value),
      ),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case StudyResumeChoice.resume:
        await _open(
          context,
          kind: open.kind,
          reviewMode: open.currentMode,
          shouldResume: true,
        );
      case StudyResumeChoice.learn:
        await _open(context, kind: StudySessionKind.learning);
      case StudyResumeChoice.review:
        final summary = await ref.read(studyEntryProvider(deckId).future);
        if (!mounted) return;
        await _chooseMode(context, ref, summary);
    }
  }

  /// The open session, or null when there is none — **and also when the read
  /// failed**.
  ///
  /// Not a swallowed error: the counts on this screen come from the same
  /// repository through `MxAsyncView`, so a storage failure is already on
  /// screen as an error state. What this catch prevents is a sheet thrown on
  /// top of that error, offering to continue a session nobody could read. The
  /// two other paths stay correct either way, because ending the open session
  /// happens inside `StartStudySessionUseCase`, not here.
  Future<StudySessionEntity?> _openSession() async {
    try {
      return await ref.read(studyResumeProvider(deckId).future);
    } on Object {
      return null;
    }
  }

  /// Leaves the route once the deck it is scoped to has been deleted.
  ///
  /// **Only while this branch is the one on screen.** `StatefulShellRoute`
  /// keeps every branch mounted — go_router wraps the inactive ones in
  /// `Offstage` + `TickerMode(enabled: false)` — so this screen is alive and
  /// rebuilding even while the user is in Library doing the deleting. A
  /// `goNamed` fired then would yank them out of the tab they are standing in,
  /// mid-gesture, to watch a screen leave. `TickerMode` is go_router's own
  /// signal for "this branch is the visible one", and reading
  /// it in `build` registers the dependency: when the user comes back to
  /// Study, that flip rebuilds this widget and the unwind runs then.
  ///
  /// **After the frame, not during it.** The trigger is a stream emission
  /// arriving mid-build, and `goNamed` rebuilds the router; doing that inside
  /// a build is the error Flutter names rather than a race worth taking.
  void _unwindAfterFrame() {
    if (_isUnwinding) return;
    _isUnwinding = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(widget.homeRouteName);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read once and used twice: `MxAsyncView` renders it, and the error face
    // asks the same snapshot whether the retry it was given is still running.
    // A second `watch` inside the error closure would be two reads of one fact.
    final entry = ref.watch(studyEntryProvider(deckId));

    final deckContext = ref.watch(studyDeckContextProvider(deckId));
    // `AsyncData(null)` and nothing else. `AsyncError` keeps whatever value it
    // had, so `hasValue`/`value == null` would read a failed read as a deleted
    // deck and navigate away from an error the user could have retried.
    final bool isDeckGone = switch (deckContext) {
      AsyncData<StudyDeckContextModel?>(value: null) => true,
      _ => false,
    };
    // Read unconditionally, so the dependency is registered on every build and
    // a branch becoming visible is what re-runs this.
    final bool isBranchVisible = TickerMode.valuesOf(context).enabled;
    if (isDeckGone && isBranchVisible) _unwindAfterFrame();

    // **The deck, not the product** (SC-C9-09, SC-C9-15). This was
    // `context.l10n.appTitle` — the only `appTitle` among the eighteen
    // `MxContentShell` titles in `lib/features/`, and a string whose own ARB
    // description scopes it to the `MaterialApp` title and the Android task
    // switcher. Arriving from a named deck row, the back stack read
    // `Study → MemoX`, and nothing on the screen said whose two counts these
    // were.
    //
    // **Read separately from the counts, deliberately.** AD-13's one-read rule
    // is about two facts a screen renders *together*; these are two different
    // subjects with two different lifetimes — the counts are a `watch()`
    // stream over card state, the name is a property of the deck row — so
    // folding the name into the count query would re-emit it on every answer.
    // `card_list_screen.dart` titles from its own deck-context read for the
    // same reason.
    return MxContentShell(
      title: deckContext.value?.deckName ?? context.l10n.studyEntryTitle,
      actions: <Widget>[
        MxIconButton(
          icon: Icons.tune,
          semanticLabel: context.l10n.studyOptionsTitle,
          onPressed: () => unawaited(_openOptions(context)),
        ),
      ],
      // Every branch below owns its gutters — the loaded body through the
      // gutter it pads itself with, the error face through `MxErrorState`'s own
      // `AppSpacing.xl` — so the shell's default would pad each of them twice.
      padding: EdgeInsets.zero,
      // The counts and the two entry points read as one block, which they
      // stop being when stretched.
      body: Align(
        alignment: Alignment.topCenter,
        child: MxReadingColumn(
          child: MxAsyncView<StudyEntrySummaryModel>(
            value: entry,
            // Names what is loading, not the product. This announced "MemoX", which
            // tells a screen-reader user neither that something is happening nor
            // what — every other loading site in the app names its subject.
            loadingLabel: context.l10n.studyEntryLoadingLabel,
            error: (_, _) => Semantics(
              // **Announced, because it can arrive in place.** The counts come from
              // a stream, so a read that fails while this screen is already open
              // swaps the two ways in for this face and moves nothing the eye is
              // drawn to. Two of the app's sixteen whole-screen failure faces carry
              // this today — `study_home_screen.dart` is one — so it is the grammar
              // the app is moving towards rather than one already settled.
              liveRegion: true,
              container: true,
              child: MxErrorState(
                // **Names the failure, and claims nothing about the deck.** This
                // face was `appTitle` over `studyNothingDueMessage`, so a user
                // whose read had just failed was told their deck was finished —
                // a claim the screen cannot support, and one that sends them away
                // instead of letting them try again.
                title: context.l10n.unexpectedErrorTitle,
                message: context.l10n.studyEntryErrorMessage,
                retryLabel: context.l10n.retryAction,
                onRetry: () => ref.invalidate(studyEntryProvider(deckId)),
                // Without the flag the tap repaints the identical face:
                // `invalidate` is a refresh, and `MxAsyncView` holds the previous
                // value through a refresh, so nothing says the app noticed.
                isRetrying: entry.isRefreshing,
              ),
            ),
            data: (summary) => Padding(
              // The screen gutter, not a fixed `lg`: below 360dp every other screen
              // narrows to `md`, and this one used to widen to 28 instead.
              padding: EdgeInsets.all(mxScreenGutter(context)),
              child: StudyEntrySectionWidget(
                summary: summary,
                onLearn: () =>
                    unawaited(_open(context, kind: StudySessionKind.learning)),
                onReview: () => unawaited(_chooseMode(context, ref, summary)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the chooser, or goes straight in when there is only one mode.
  ///
  /// BR-146: with a single available mode the chooser is a question with one
  /// answer, so `sm2` decks skip it entirely — and land instead on the direction
  /// question, which for those decks is the one real choice a review has
  /// (BR-203).
  Future<void> _chooseMode(
    BuildContext context,
    WidgetRef ref,
    StudyEntrySummaryModel summary,
  ) async {
    final options = await ref.read(studyReviewOptionsProvider(deckId).future);
    final modes = options.modes;
    if (modes.isEmpty || !context.mounted) return;
    if (modes.length == 1) {
      return _startReview(context, options: options, mode: modes.single);
    }

    final chosen = await showMxSheet<StudyMode>(
      context,
      builder: (sheetContext) => StudyModeChooserWidget(
        modes: modes,
        summary: summary,
        onModeSelected: (mode) => Navigator.of(sheetContext).pop(mode),
      ),
    );

    if (chosen == null || !context.mounted) return;

    return _startReview(context, options: options, mode: chosen);
  }

  /// Starts a review in [mode], asking for a direction first when the deck's
  /// algorithm and the mode make that a real question (BR-203).
  ///
  /// **The eligibility question is the model's, not this screen's.** A widget
  /// spelling out "reviewing and sm2 and self_assess" is the copy that forgets a
  /// term, and the term it forgets is the one that puts a chooser in front of an
  /// `eight_box` deck.
  Future<void> _startReview(
    BuildContext context, {
    required StudyReviewOptionsModel options,
    required StudyMode mode,
  }) {
    if (!options.isDirectionChoiceRequiredFor(mode)) {
      return _open(context, kind: StudySessionKind.reviewing, reviewMode: mode);
    }

    // **Scroll-controlled and status-bar-safe by the route owner** (A20.1
    // P1-01). Both used to be this call's own flags, argued here: Flutter
    // caps an ordinary sheet at 9/16 of the display, and at 320dp × 2.0 this
    // content is roughly 916dp against a cap of 319, so `Start review` sat
    // below the fold; and once the cap was gone the 16dp top gutter was less
    // than a modern cutout. `showMxSheet` makes both decisions for every
    // sheet, so they cannot be forgotten by the next one.
    return showMxSheet<void>(
      context,
      // The choice is locked for the session (BR-207), so it is confirmed rather
      // than taken on a tap — and a sheet that dismisses on a background tap
      // would still be dismissible, which is the correct way out of a question
      // the user has decided not to answer.
      builder: (sheetContext) => StudyDirectionChooserWidget(
        onSubmit: (direction) =>
            _startWithDirection(sheetContext, mode: mode, direction: direction),
      ),
    );
  }

  /// Confirms the review is still open to be started, then opens it.
  ///
  /// **The re-read is not ceremony, and it checks two things because UC-15 has
  /// two error flows.** The sheet has been on screen, and in that time a
  /// scheduler change or a Reset elsewhere can have taken `self_assess` away
  /// (E1, BR-13, BR-83) — or the last due card can have been answered, which
  /// BR-145 refuses (E2). Both used to reach the user the same wrong way: the
  /// sheet popped first, so the refusal surfaced as a full-screen error on the
  /// session screen, with the choice lost and no way back to it.
  ///
  /// The authoritative refusal still happens inside `openSession`'s transaction —
  /// this is the user-facing one, and it is what UC-15 promises.
  ///
  /// Returns null when the session was opened, and the failure otherwise — the
  /// chooser renders it and keeps the selection.
  Future<Object?> _startWithDirection(
    BuildContext sheetContext, {
    required StudyMode mode,
    required StudySessionDirection direction,
  }) async {
    try {
      ref
        ..invalidate(studyReviewOptionsProvider(deckId))
        ..invalidate(studyEntryProvider(deckId));

      final options = await ref.read(studyReviewOptionsProvider(deckId).future);
      if (!options.isDirectionChoiceRequiredFor(mode)) {
        return const ConflictFailure(
          message: 'This deck no longer offers that review',
          reason: StudyRefusalReason.modeNotSupportedByScheduler,
        );
      }

      final summary = await ref.read(studyEntryProvider(deckId).future);
      if (summary.dueCount <= 0) {
        return const ConflictFailure(
          message: 'Nothing to review',
          reason: StudyRefusalReason.nothingDueToReview,
        );
      }
    } on Object catch (error) {
      return error;
    }

    // The sheet outliving this await is the ordinary case; it going away is the
    // user having dismissed it, and there is then nothing to report to.
    if (!mounted || !sheetContext.mounted) return null;

    Navigator.of(sheetContext).pop();
    if (!mounted) return null;

    await _open(
      context,
      kind: StudySessionKind.reviewing,
      reviewMode: mode,
      direction: direction,
    );

    return null;
  }

  /// Opens a session, and refreshes this screen on both sides of it.
  ///
  /// **Before**, because both reads describe the deck as it stands *now*:
  /// leaving them cached would let a later visit offer to continue a session
  /// this one just ended, and the resume would fail on a session the database
  /// no longer has.
  ///
  /// **After**, because a session is exactly the thing that changes them. Coming
  /// back from finishing four cards to a screen still saying three are new is
  /// the summary and the counts disagreeing about the same minute — and the
  /// summary is the one that just told the truth.
  Future<void> _open(
    BuildContext context, {
    required StudySessionKind kind,
    StudyMode? reviewMode,

    /// The recall direction chosen for this session (BR-203). Null for every
    /// path the rule does not cover, and for a resume (BR-207).
    StudySessionDirection? direction,
    bool shouldResume = false,
  }) async {
    _refresh();

    // **The root navigator, so the session is the whole screen.** Pushed on the
    // branch navigator it sat inside the shell and kept the bottom bar, which
    // offers two ways out of a session that BR-82 says has exactly one: the ✕,
    // which ends it as `abandoned`/`user_exit`. A tab switch left the session
    // open and the app then offered to resume something the user thought they
    // had walked away from.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => StudySessionScreen(
          deckId: deckId,
          kind: kind,
          reviewMode: reviewMode,
          direction: direction,
          shouldResume: shouldResume,
        ),
      ),
    );

    if (!mounted) return;
    _refresh();
  }

  /// Opens the options, and re-reads on the way back.
  ///
  /// The card limit is one of the two numbers this screen is about, so coming
  /// back from changing it to a screen still showing the old one would be the
  /// same disagreement as returning from a session — see [_open].
  ///
  /// **By name, not by `MaterialPageRoute`** (A8 P2-15). The imperative push
  /// put the options on the branch navigator with no location, so the router
  /// went on naming this screen for as long as the options were the thing on
  /// screen. The route is a child of whichever entry route built this screen,
  /// so the pushed page still renders inside the shell and Back still lands
  /// here — `pushNamed` returns a future that completes on the pop, which is
  /// what keeps the refresh below.
  Future<void> _openOptions(BuildContext context) async {
    await context.pushNamed(
      optionsRouteName,
      pathParameters: <String, String>{RoutePathParams.deckId: deckId},
    );

    if (!mounted) return;
    _refresh();
  }

  void _refresh() {
    ref.invalidate(studyResumeProvider(deckId));
    ref.invalidate(studyEntryProvider(deckId));
    // **The title is not in this list any more, and that is the fix rather
    // than an omission.** It used to be invalidated here because the read was
    // a one-shot `Future` and `StatefulShellRoute.indexedStack` keeps this
    // branch mounted, so nothing else ever re-ran it. That covered exactly one
    // path — a rename made through this screen's own options round-trip — and
    // left the app bar stale after a rename made anywhere else. The read is a
    // `watch()` now, so it follows the row.
  }
}
