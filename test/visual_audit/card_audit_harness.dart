import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/card/presentation/support/fake_tag_catalog_repository.dart';

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

/// The same wrapper for the tag catalog, over its own contract (UC-18).
///
/// A second function rather than a second parameter on the first: the catalog
/// screen reads only `TagCatalogRepository`, and a card fake it never calls
/// would be a dependency the audit does not have.
Widget tagScreenWith(FakeTagCatalogRepository repository, Widget screen) {
  return ProviderScope(
    overrides: [tagCatalogRepositoryProvider.overrideWithValue(repository)],
    child: screen,
  );
}
