import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// The wall clock, as a value the rest of the tree can override.
///
/// **In `core/` because a clock belongs to no feature.** It started life inside
/// the deck feature, which meant the first other feature that needed "now" would
/// have had to import `features/deck/presentation/…` — a cross-feature
/// presentation import, which `check_architecture.sh` reports as an error. A
/// helper every feature needs and no feature owns is exactly what `core/` is for.
///
/// A function rather than a `DateTime`, because callers need "now at the moment I
/// ask", not "now when this provider was first built". Tests override it with a
/// fixed instant; nothing below reads `DateTime.now()` directly, which is what
/// makes a boundary like `due_at == now` testable at all (BR-22).
///
/// UTC, always. Timestamps are stored in UTC and `due_at` arithmetic is only safe
/// in one zone.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) =>
    () => DateTime.now().toUtc();
