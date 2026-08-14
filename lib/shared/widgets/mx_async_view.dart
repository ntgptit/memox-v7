import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mx_loading_state.dart';

/// Renders the three cases of an [AsyncValue] with one loading treatment.
///
/// **What it centralises is a policy, not four lines of `switch`.** Every
/// `.when` call site silently inherits `skipLoadingOnRefresh`, and the default
/// is not obvious: on a *refresh* Riverpod keeps handing you the previous data
/// instead of the loading case. That is the behaviour we want — a resume that
/// re-reads the deck list must not flash a spinner over a populated screen — but
/// it should be a decision written down once, not a default nobody looked at in
/// three separate files.
///
/// Initial loading is unaffected by that flag: with no previous value there is
/// nothing to keep showing, so the first read always renders [MxLoadingState].
/// A screen therefore never shows stale data as if it were fresh.
///
/// **Loading is shared; error copy is not.** A spinner with a screen-reader label
/// is the same everywhere, so this widget owns it. The words on a failure are the
/// screen's to choose — "couldn't load your decks" is not "couldn't load this
/// deck", and a deck deleted elsewhere needs a way back rather than a retry that
/// will fail again. So [error] is a builder the caller supplies, and this widget
/// deliberately does not offer a default: a generic "something went wrong" is how
/// every screen ends up with the same unhelpful sentence.
///
/// Generic on `T` and knows no domain type, which is what keeps it in `shared/`.
///
/// A spinner rather than a shimmer skeleton, on purpose. Skeletons exist to mask
/// network latency; these reads are local SQLite and finish in single-digit
/// milliseconds, so a skeleton would render a fake layout for less than a frame
/// and then replace it — motion that says "slow" about something that is not.
/// Revisit if a read ever crosses a network (AD-05 defers that).
class MxAsyncView<T> extends StatelessWidget {
  const MxAsyncView({
    required this.value,
    required this.loadingLabel,
    required this.data,
    required this.error,
    this.loadingFrame,
    this.skipLoadingOnReload = false,
    super.key,
  });

  final AsyncValue<T> value;

  /// Already-localized. Required because a bare spinner announces nothing at
  /// all to a screen reader — the user is told neither that something is
  /// happening nor when it stops.
  final String loadingLabel;

  final Widget Function(T value) data;

  /// The failure itself must not reach the user. Map the `Failure` *type* to ARB
  /// copy inside this builder; its `message` is written for whoever reads a log
  /// and can name a table or carry private content.
  final Widget Function(Object error, StackTrace stackTrace) error;

  /// Chrome to put around the loading widget, when a screen needs some.
  ///
  /// Exists because a screen whose app-bar title comes from the loaded data
  /// cannot put one shell around all three branches — the title is not known
  /// yet while it loads. Without this, such a screen renders a bare spinner with
  /// no `Scaffold`: no background, no safe area, and on a pushed route the page
  /// below shows through, because the transition backdrop is transparent at rest.
  ///
  /// `null` means the spinner is used as-is, which is right whenever the caller
  /// already sits inside a shell.
  final Widget Function(Widget loading)? loadingFrame;

  /// Keep the previous value on screen while a **reload** runs, not only a
  /// refresh.
  ///
  /// Riverpod calls it a reload when a *dependency* changed rather than when
  /// something asked for a re-read, and the default here is `false` because for
  /// most screens those two are the same event: the deck list's dependency is
  /// the deck you are looking at, so a change means the previous value answers a
  /// question nobody is asking any more, and showing it would be showing the
  /// wrong deck's contents.
  ///
  /// Progress is the first screen where they come apart. Its dependency is
  /// `progressNowProvider` — the instant the windows are measured against — and
  /// that instant moves on **every app resume** and at local midnight. The
  /// question ("how am I doing?") has not changed at all; only the measurement
  /// point has. With this `false`, every resume replaced three populated
  /// sections with a full-screen spinner for as long as a full scan of
  /// `study_answers` takes, which UC-12's UI states and the wireframe's P8 both
  /// forbid in as many words.
  ///
  /// Opt-in rather than a changed default: the reasoning above is a property of
  /// one screen's dependency, and flipping it globally would let a genuinely
  /// stale value stay on screen everywhere else.
  final bool skipLoadingOnReload;

  @override
  Widget build(BuildContext context) {
    return value.when(
      // Both flags are stated rather than inherited, because the defaults differ
      // from each other and neither is obvious at a call site.
      //
      // Keep the previous value on screen while a refresh runs. Replacing a
      // populated list with a spinner every time the app resumes would be motion
      // in place of information.
      skipLoadingOnRefresh: true,
      // A reload is a dependency change, which usually means the previous value
      // answers a question nobody is asking any more — so `false` by default,
      // and the field's doc explains the one screen that is not like that.
      skipLoadingOnReload: skipLoadingOnReload,
      loading: _buildLoading,
      data: data,
      error: error,
    );
  }

  Widget _buildLoading() {
    final loading = MxLoadingState(semanticsLabel: loadingLabel);

    return loadingFrame?.call(loading) ?? loading;
  }
}
