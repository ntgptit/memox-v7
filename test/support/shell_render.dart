import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/app_router.dart';

/// One screen, mounted at its production location inside the real shell.
///
/// **Why this exists.** Eight rows of the screen gallery were pumped as
/// `ReviewApp(home: <Screen>)` — no router, and therefore no
/// `AppNavigationShell` and no `MxNavigationBar` — while every one of those
/// screens production-routes *inside* a `StatefulShellBranch`. The four-
/// destination bar is 80dp of the screen a user actually sees, and the safe area
/// under it is what decides where a list ends and where a FAB sits. A picture
/// without it is a picture of a frame the app never draws (EV-04,
/// `docs/reviews/impeccable-uiux-audit.md` §2).
///
/// The lesson was already written down in this repo, in the one demo file that
/// got it right: *"a bare pump loses the shell's navigation bar and its safe
/// area, and those are exactly the parts a layout review has to score"*
/// (`study_options_demo_test.dart`). It was applied in one file and not in its
/// siblings, so this helper is where it stops being a thing each file has to
/// remember.
///
/// **A router per call.** `GoRouter` carries navigation history, and a golden
/// suite builds one screen per theme; a shared router would let the light run
/// decide where the dark run starts. Disposed on tear-down for the same reason.
///
/// It supplies no `MaterialApp` — `ReviewApp` does, with the theme for the
/// brightness under test. A second one here would pin every render to one
/// theme and hide exactly the dark-mode drift a review pass exists to catch.
/// **It returns the routed widget, not a whole harness**, so it drops into the
/// `child:`/`screen:` slot every feature harness already has. The overrides stay
/// where they are — one owner per feature — and the only thing that changes at a
/// call site is *what is mounted*: the production route table instead of the
/// screen on its own.
Widget shellChild(String location) {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  return Router<Object>.withConfig(config: router);
}
