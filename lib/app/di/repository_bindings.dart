import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database_provider.dart';
import '../../core/time/clock_provider.dart';
import '../../features/card/data/datasources/card_import_file_data_source.dart';
import '../../features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart';
import '../../features/card/data/repositories/card_export_destination_repository_impl.dart';
import '../../features/card/data/repositories/card_export_repository_impl.dart';
import '../../features/card/data/repositories/card_import_repository_impl.dart';
import '../../features/card/data/repositories/card_import_source_repository_impl.dart';
import '../../features/card/data/repositories/card_transfer_repository_impl.dart';
import '../../features/card/data/repositories/card_repository_impl.dart';
import '../../features/card/di/card_export_repository_provider.dart';
import '../../features/card/di/card_import_repository_provider.dart';
import '../../features/card/di/card_transfer_repository_provider.dart';
import '../../features/card/di/card_repository_provider.dart';
import '../../features/card/domain/models/card_transfer_encoder_model.dart';
import '../../features/card/domain/repositories/card_export_destination_repository.dart';
import '../../features/card/domain/repositories/card_export_repository.dart';
import '../../features/card/domain/repositories/card_import_repository.dart';
import '../../features/card/domain/repositories/card_import_source_repository.dart';
import '../../features/card/domain/repositories/card_transfer_repository.dart';
import '../../features/card/domain/repositories/card_repository.dart';
import '../../features/deck/di/deck_repository_provider.dart';
import '../../features/deck/di/deck_template_provider.dart';
import '../../features/deck/data/datasources/deck_dao.dart';
import '../../features/deck/data/datasources/deck_template_data_source.dart';
import '../../features/deck/data/datasources/deck_template_dao.dart';
import '../../features/deck/data/repositories/deck_repository_impl.dart';
import '../../features/deck/data/repositories/deck_template_repository_impl.dart';
import '../../features/deck/domain/repositories/deck_repository.dart';
import '../../features/deck/domain/models/deck_template_model.dart';
import '../../features/deck/domain/repositories/deck_template_repository.dart';
import '../../features/progress/data/datasources/progress_dao.dart';
import '../../features/progress/data/repositories/progress_repository_impl.dart';
import '../../features/progress/di/progress_repository_provider.dart';
import '../../features/progress/domain/repositories/progress_repository.dart';
import '../../features/study/data/datasources/study_dao.dart';
import '../../features/study/data/datasources/study_home_dao.dart';
import '../../features/study/di/study_home_repository_provider.dart';
import '../../features/study/di/study_repository_provider.dart';
import '../../features/study/data/repositories/study_home_repository_impl.dart';
import '../../features/study/data/repositories/study_repository_impl.dart';
import '../../features/study/domain/repositories/study_home_repository.dart';
import '../../features/study/domain/repositories/study_repository.dart';

/// Where each repository contract is bound to its implementation.
///
/// **The only place an implementation is named outside its own layer.** A feature
/// declares what it needs — `deckRepositoryProvider`, typed as the domain contract
/// — and this file decides what satisfies it. `buildRootWidget` installs the
/// bindings; nothing else may.
///
/// The direction matters more than the location. `app/` importing `features/` is
/// the composition root doing its job; the reverse would make a feature depend on
/// the shell, and that is what
/// `test/app/architecture_boundary_test.dart` forbids.
///
/// **Factory functions, not a list of `Override`s.** Riverpod's `Override` is a
/// sealed type in `src/`, not part of `flutter_riverpod`'s public API, so a
/// function cannot be declared to return one. The call site writes
/// `deckRepositoryProvider.overrideWith(deckRepositoryBinding)` instead, which
/// names only public types and keeps the construction here.
///
/// Adding a feature adds one function here and one line at the root. That is the
/// whole cost, and it is deliberately not zero: a repository whose implementation
/// nobody had to choose is a repository nobody can substitute.
DeckRepository deckRepositoryBinding(Ref ref) => DeckRepositoryImpl(
  DeckDao(ref.watch(appDatabaseProvider)),
  // From `clockProvider` rather than a default inside the repository, so "now"
  // has one owner the whole tree can override.
  clock: ref.watch(clockProvider),
  // **The first place two features are wired to each other, and it is here on
  // purpose.** Reset has to close the sessions it invalidates (BR-83) without
  // leaving the single write BR-47 requires, so Deck's repository takes Study's
  // *domain* contract. The root is what decides which implementation satisfies
  // it — which is the whole reason this file exists.
  study: ref.watch(studyRepositoryProvider),
);

/// **The database itself, not a DAO — and the difference is the point of this
/// file.** `CardRepositoryImpl` builds both of its adapters internally so that
/// the BR-62 content lock and the card insert cannot end up in two
/// transactions; an API taking two ready-made DAOs would let this root hand it
/// instances from two databases, and the lock would then sit outside the
/// transaction that rolls the card back. The binding absorbs that difference,
/// which is what a composition root is for: the two contracts look the same to
/// the features that declare them, and only this file knows they are wired
/// differently.
CardRepository cardRepositoryBinding(Ref ref) => CardRepositoryImpl(
  ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
);

/// Card transfer's three seams, bound apart on purpose (M99.19): the picker
/// is the one platform dialog, the decoder is pure bytes-to-rows, and the
/// commit is pure database — so no test ever fakes a half it does not call,
/// and the commit implementation can prove it never sees a byte of CSV.
CardImportRepository cardImportRepositoryBinding(Ref ref) =>
    CardImportRepositoryImpl(
      ref.watch(appDatabaseProvider),
      clock: ref.watch(clockProvider),
    );

CardTransferRepository cardTransferRepositoryBinding(Ref ref) =>
    const CardTransferRepositoryImpl();

CardImportSourceRepository cardImportSourceRepositoryBinding(Ref ref) =>
    const CardImportSourceRepositoryImpl(picker: CardImportFileDataSource());

/// Card export's three seams, bound apart for the same reason import's are
/// (M99.21, AD-20): the read is pure database, the encoder resolver is pure
/// bytes, and the destination is the one place the app talks to the OS.
///
/// **The database itself, not a DAO** — the same difference `cardRepositoryBinding`
/// explains: the deck name and the card rows must come from one transaction,
/// and a ready-made adapter would let this root hand the repository a snapshot
/// from a second database.
///
/// No clock: an export writes nothing and stamps nothing (BR-178). "Now" enters
/// this flow once, at the use case, to date the file name (BR-180).
CardExportRepository cardExportRepositoryBinding(Ref ref) =>
    CardExportRepositoryImpl(ref.watch(appDatabaseProvider));

/// The share sheet. Constructed with no argument so the plugin's own singleton
/// is used; the injectable seam on the implementation exists for host tests,
/// not for this root to choose between platforms.
CardExportDestinationRepository cardExportDestinationRepositoryBinding(
  Ref ref,
) => const CardExportDestinationRepositoryImpl();

/// The encode registry, bound as the domain typedef so nothing above `data/`
/// has to import the file holding the `switch` (AD-20).
CardTransferEncoderResolver cardTransferEncoderResolverBinding(Ref ref) =>
    cardTransferEncoderFor;

/// The template-copy path (AD-07). Its own DAO, for the reason stated on
/// `DeckTemplateDao`: it writes decks, cards and study states in one
/// transaction, which is a different job from the reads a deck list rebuild
/// runs constantly.
DeckTemplateRepository deckTemplateRepositoryBinding(Ref ref) =>
    DeckTemplateRepositoryImpl(
      DeckTemplateDao(ref.watch(appDatabaseProvider)),
      clock: ref.watch(clockProvider),
    );

/// Study needs no clock: every one of its operations takes `now` as an argument,
/// because a session's whole behaviour turns on which instant it is measured
/// against and a repository that read the clock itself could not be tested at
/// the `due_at == now` boundary (AD-06).
///
/// It does take a random source, which is deliberately not injected here: the
/// default is a real one, and only a test replaces it. A seeded shuffle in
/// production would make every session lay its cards out in the same order.
/// Progress reads what studying produced and writes nothing (BR-190, BR-198),
/// so it
/// takes neither a clock nor an id generator: every instant it needs arrives as
/// an argument from `clockProvider` and `utcOffsetProvider` at the controller
/// (BR-202, BR-194),
/// and there is nothing for it to stamp.
///
/// Its own DAO rather than the database, unlike the card bindings: there is no
/// multi-step write whose steps have to share a transaction, so the narrower
/// seam is the honest one.
ProgressRepository progressRepositoryBinding(Ref ref) =>
    ProgressRepositoryImpl(ProgressDao(ref.watch(appDatabaseProvider)));

StudyRepository studyRepositoryBinding(Ref ref) =>
    StudyRepositoryImpl(StudyDao(ref.watch(appDatabaseProvider)));

/// The Study tab's read, bound apart from the session repository above (BR-200).
///
/// **Two contracts over one database, on purpose.** They are wired identically
/// and could have been one; splitting them is what makes the Home screen unable
/// to open a session, because the only object it can reach has no method that
/// writes. Import and export are split the same way and for the same reason.
///
/// No clock, for the reason `studyRepositoryBinding` gives: `now` and the local
/// day arrive as arguments, so the read is testable at the `due_at == now` and
/// the local-midnight boundaries (AD-06, AD-16).
StudyHomeRepository studyHomeRepositoryBinding(Ref ref) =>
    StudyHomeRepositoryImpl(StudyHomeDao(ref.watch(appDatabaseProvider)));

/// The starter catalog: the shipped assets, decoded once (UC-01).
///
/// A `Future` binding rather than a repository: there is no database and no
/// stream behind it, only the bundle the app was built with — which is why the
/// data source is not a repository either.
Future<List<DeckTemplate>> deckTemplateCatalogBinding(Ref ref) =>
    const DeckTemplateDataSource().loadAll();

/// Every contract the app binds, as one list.
///
/// **It exists because a hand-written subset of it broke sixty-six end-to-end
/// scenarios at once.** `ItHarness` built its own container listing only the two
/// bindings it thought it needed; when `deckRepositoryBinding` grew a dependency
/// on `studyRepositoryProvider` (UC-07, BR-83), that provider was contract-only
/// in the harness's container and reading it threw — before the first step of
/// every scenario ran.
///
/// The list is the fix rather than a third line in the harness: a binding that
/// grows a dependency can no longer break a container that was written from
/// this. Anything a caller wants to substitute — the database, the clock — goes
/// *after* it, because a later override wins.
List<Override> repositoryBindingOverrides() => <Override>[
  deckRepositoryProvider.overrideWith(deckRepositoryBinding),
  cardRepositoryProvider.overrideWith(cardRepositoryBinding),
  cardImportRepositoryProvider.overrideWith(cardImportRepositoryBinding),
  cardTransferRepositoryProvider.overrideWith(cardTransferRepositoryBinding),
  cardImportSourceRepositoryProvider.overrideWith(
    cardImportSourceRepositoryBinding,
  ),
  cardExportRepositoryProvider.overrideWith(cardExportRepositoryBinding),
  cardExportDestinationRepositoryProvider.overrideWith(
    cardExportDestinationRepositoryBinding,
  ),
  cardTransferEncoderResolverProvider.overrideWith(
    cardTransferEncoderResolverBinding,
  ),
  deckTemplateRepositoryProvider.overrideWith(deckTemplateRepositoryBinding),
  deckTemplateCatalogProvider.overrideWith(deckTemplateCatalogBinding),
  studyRepositoryProvider.overrideWith(studyRepositoryBinding),
  progressRepositoryProvider.overrideWith(progressRepositoryBinding),
  studyHomeRepositoryProvider.overrideWith(studyHomeRepositoryBinding),
];
