import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_zone_provider.g.dart';

/// The device's offset from UTC, as a value the tree can override.
///
/// **In `core/` for the reason `clockProvider` is** — a timezone belongs to no
/// feature, and BR-105 makes two of them need it. `domain/` may not read the
/// device zone any more than it may read the wall clock; both arrive as inputs
/// (AD-16).
///
/// A function rather than a `Duration`, because the offset changes: a device
/// crossing a border, or a season changing, moves it while the app is running.
/// Reading it per call is what keeps "the start of tomorrow" correct after that
/// happens, and it is why `StudyDayModel` takes an offset instead of resolving
/// one itself.
@Riverpod(keepAlive: true)
Duration Function() utcOffset(Ref ref) =>
    () => DateTime.now().timeZoneOffset;
