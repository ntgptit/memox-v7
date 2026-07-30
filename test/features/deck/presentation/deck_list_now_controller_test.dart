import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_now_controller.dart';

import 'support/fake_deck_repository.dart';

/// `DeckListNow` — the instant the deck list's due counts are measured against.
///
/// The clock is injected, which is the property everything else about the due
/// count rests on: `due_at == now` is a boundary BR-22 has to get right, and a
/// provider that read `DateTime.now()` could not be tested at it.
void main() {
  final fixedNow = DateTime.utc(2026, 7, 29, 12);

  /// A container whose clock the test can move.
  ///
  /// Returned as a record rather than closed over, because a test that moves the
  /// clock needs to say when — `refresh` reads it at the moment it is called, not
  /// at build time, and that distinction is the whole mechanism.
  ({ProviderContainer container, void Function(DateTime) setNow}) containerAt(
    DateTime start,
  ) {
    var current = start;
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
        clockProvider.overrideWithValue(() => current),
      ],
    );
    addTearDown(container.dispose);

    return (container: container, setNow: (DateTime at) => current = at);
  }

  test('is injected, never read from the wall clock', () {
    final fixture = containerAt(fixedNow);

    expect(fixture.container.read(deckListNowProvider), fixedNow);
  });

  test('refresh re-measures it', () {
    final fixture = containerAt(fixedNow);
    fixture.container.listen<DateTime>(deckListNowProvider, (_, _) {});

    fixture.setNow(fixedNow.add(const Duration(hours: 3)));
    fixture.container.read(deckListNowProvider.notifier).refresh();

    expect(
      fixture.container.read(deckListNowProvider),
      fixedNow.add(const Duration(hours: 3)),
    );
  });

  test('refresh with no clock movement changes nothing', () {
    // Not a no-op worth asserting for its own sake — it pins that the value comes
    // from the clock and not from a counter or a rebuild, so an unrelated
    // invalidation cannot make the due counts flicker.
    final fixture = containerAt(fixedNow);
    fixture.container.listen<DateTime>(deckListNowProvider, (_, _) {});

    fixture.container.read(deckListNowProvider.notifier).refresh();

    expect(fixture.container.read(deckListNowProvider), fixedNow);
  });
}
