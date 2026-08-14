import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import '../features/card/presentation/support/fake_card_repository.dart';

/// Wraps one card screen in a `ProviderScope` over a fake repository, for the
/// visual audit.
///
/// **No `MaterialApp` here** — `auditMemoxScreen` supplies one, with the theme
/// for the brightness it is testing. Wrapping a second one would pin the screen
/// to a single theme and hide exactly the dark-mode drift the audit exists to
/// catch, which is what a first draft of this did: it hardcoded the light theme
/// and the dark pass reported light colours on a dark screen.
///
/// Rendered directly rather than through the router: the card screens read only
/// their controllers, and the audit measures a resting frame, so nothing taps
/// the FAB or a row and no `GoRouter` ancestor is needed.
Widget cardScreenWith(FakeCardRepository repository, Widget screen) {
  return ProviderScope(
    overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    child: screen,
  );
}

/// The same, for a screen that reads the detail contract instead (UC-12).
///
/// A separate wrapper rather than a second override on the one above: the
/// detail screen touches only `CardDetailRepository`, and handing it a fake of
/// the management contract as well would say the screen depends on twenty-six
/// methods it is forbidden to call (BR-182).
///
/// No router here either. Both of the screen's navigations happen on a tap, and
/// the audit measures a resting frame.
Widget cardDetailScreenWith(
  FakeCardDetailRepository repository,
  Widget screen,
) {
  return ProviderScope(
    overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
    child: screen,
  );
}
