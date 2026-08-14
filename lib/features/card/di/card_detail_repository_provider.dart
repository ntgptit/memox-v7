import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/card_detail_repository.dart';

part 'card_detail_repository_provider.g.dart';

/// The read-side contract of one card, declared here and bound at the
/// composition root.
///
/// Same shape as its siblings — see `card_repository_provider.dart` for why a
/// feature declares its own seam and why the body throws instead of building
/// anything.
///
/// **A separate seam from `cardRepositoryProvider`, and the split pays for
/// itself in the tests.** A detail widget test fakes two methods; faking the
/// management contract to render a read-only screen would mean stubbing
/// twenty-six, twenty-four of which the screen is forbidden to call (BR-182).
@Riverpod(keepAlive: true)
CardDetailRepository cardDetailRepository(Ref ref) => throw StateError(
  'cardDetailRepositoryProvider was read without an override. The composition '
  'root binds it — see cardDetailRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
