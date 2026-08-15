import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/tag_catalog_repository.dart';

part 'tag_catalog_repository_provider.g.dart';

/// The catalog contract this feature needs, declared as the **contract** and
/// bound at the composition root.
///
/// The shape and the reasoning are `cardRepositoryProvider`'s. What this one
/// adds is a second seam inside one feature: the catalog and the card repository
/// are two contracts over overlapping tables, so a test of the catalog installs
/// a fake with three methods and never has to satisfy `CardRepository`'s
/// twenty-six.
@Riverpod(keepAlive: true)
TagCatalogRepository tagCatalogRepository(Ref ref) => throw StateError(
  'tagCatalogRepositoryProvider was read without an override. The composition '
  'root binds it — see tagCatalogRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
