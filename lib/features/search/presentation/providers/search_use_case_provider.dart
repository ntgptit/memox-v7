import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/library_search_repository_provider.dart';
import '../../domain/usecases/search_library_use_case.dart';

part 'search_use_case_provider.g.dart';

/// Dependency wiring, and nothing else — no state, no command, which is what
/// keeps this file `_provider` rather than `_controller`.
@riverpod
SearchLibraryUseCase searchLibraryUseCase(Ref ref) =>
    SearchLibraryUseCase(ref.watch(librarySearchRepositoryProvider));
