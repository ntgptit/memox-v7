import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/tag_catalog_repository_provider.dart';
import '../../domain/usecases/delete_tag_use_case.dart';
import '../../domain/usecases/rename_tag_use_case.dart';
import '../../domain/usecases/watch_tag_catalog_use_case.dart';

part 'tag_use_case_provider.g.dart';

/// The tag catalog's use cases, wired to its own repository (UC-12).
///
/// A `_provider`, not a `_controller`: it only wires dependencies, and the
/// guard's widget scopes exempt `_controller` from the ban on reading a
/// repository directly — a wiring file must not borrow that exemption. Same
/// split `card_use_case_provider.dart` documents.
///
/// **Beside that file rather than inside it.** The catalog is a second contract
/// (see `TagCatalogRepository`), and keeping its wiring separate is what lets a
/// catalog test override one provider instead of the card feature's whole
/// dependency graph.
@riverpod
WatchTagCatalogUseCase watchTagCatalogUseCase(Ref ref) =>
    WatchTagCatalogUseCase(ref.watch(tagCatalogRepositoryProvider));

@riverpod
RenameTagUseCase renameTagUseCase(Ref ref) =>
    RenameTagUseCase(ref.watch(tagCatalogRepositoryProvider));

@riverpod
DeleteTagUseCase deleteTagUseCase(Ref ref) =>
    DeleteTagUseCase(ref.watch(tagCatalogRepositoryProvider));
