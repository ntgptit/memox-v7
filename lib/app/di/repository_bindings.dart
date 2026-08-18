import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database_provider.dart';
import '../../core/time/clock_provider.dart';
import '../../features/reminder/data/datasources/reminder_dao.dart';
import '../../features/reminder/data/datasources/reminder_notification_data_source.dart';
import '../../features/reminder/data/datasources/reminder_scheduler_data_source.dart';
import '../../features/reminder/data/repositories/android_reminder_platform_repository_impl.dart';
import '../../features/reminder/data/repositories/reminder_settings_repository_impl.dart';
import '../../features/reminder/data/repositories/reminder_workload_repository_impl.dart';
import '../../features/reminder/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import '../../features/reminder/di/reminder_platform_repository_provider.dart';
import '../../features/reminder/di/reminder_settings_repository_provider.dart';
import '../../features/reminder/di/reminder_workload_repository_provider.dart';
import '../../features/reminder/domain/repositories/reminder_platform_repository.dart';
import '../../features/reminder/domain/repositories/reminder_settings_repository.dart';
import '../../features/reminder/domain/repositories/reminder_workload_repository.dart';
import '../../features/card/data/datasources/card_import_file_data_source.dart';
import '../../features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart';
import '../../features/card/data/repositories/card_export_destination_repository_impl.dart';
import '../../features/card/data/repositories/card_export_repository_impl.dart';
import '../../features/card/data/repositories/card_import_repository_impl.dart';
import '../../features/card/data/repositories/card_import_source_repository_impl.dart';
import '../../features/card/data/repositories/card_transfer_repository_impl.dart';
import '../../features/card/data/repositories/card_detail_repository_impl.dart';
import '../../features/card/data/repositories/card_repository_impl.dart';
import '../../features/card/data/repositories/tag_catalog_repository_impl.dart';
import '../../features/card/di/tag_catalog_repository_provider.dart';
import '../../features/card/domain/repositories/tag_catalog_repository.dart';
import '../../features/card/di/card_detail_repository_provider.dart';
import '../../features/card/di/card_export_repository_provider.dart';
import '../../features/card/di/card_import_repository_provider.dart';
import '../../features/card/di/card_transfer_repository_provider.dart';
import '../../features/card/di/card_repository_provider.dart';
import '../../features/card/domain/models/card_transfer_encoder_model.dart';
import '../../features/card/domain/repositories/card_detail_repository.dart';
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
import '../../features/settings/data/repositories/app_settings_repository_impl.dart';
import '../../features/settings/di/app_settings_repository_provider.dart';
import '../../features/settings/domain/repositories/app_settings_repository.dart';
import '../../features/search/data/repositories/library_search_repository_impl.dart';
import '../../features/search/di/library_search_repository_provider.dart';
import '../../features/search/domain/repositories/library_search_repository.dart';
import '../../features/study/data/datasources/study_dao.dart';
import '../../features/study/data/datasources/study_home_dao.dart';
import '../../features/study/di/study_home_repository_provider.dart';
import '../../features/study/di/study_repository_provider.dart';
import '../../features/study/data/repositories/study_home_repository_impl.dart';
import '../../features/study/data/repositories/study_repository_impl.dart';
import '../../features/study/domain/repositories/study_home_repository.dart';
import '../../features/study/domain/repositories/study_repository.dart';
import '../../features/trash/data/datasources/trash_dao.dart';
import '../../features/trash/data/repositories/content_trash_repository_impl.dart';
import '../../features/trash/data/repositories/trash_repository_impl.dart';
import '../../features/trash/di/trash_repository_provider.dart';
import '../../features/trash/domain/repositories/content_trash_repository.dart';
import '../../features/trash/domain/repositories/trash_repository.dart';

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
  // The second cross-feature wire, and it exists for the same reason as the
  // first: deleting a deck has to create a deletion batch (BR-256) without
  // leaving the single transaction, so Deck's repository takes Trash's *domain*
  // contract and the root decides what satisfies it.
  trash: ref.watch(contentTrashRepositoryProvider),
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
  trash: ref.watch(contentTrashRepositoryProvider),
);

/// Trash's two contracts.
///
/// **The batch half takes Study's contract, not Trash's own screen.** Closing
/// the sessions a deletion invalidates is BR-259, it has to happen inside the
/// delete transaction, and the session status × end_reason pair belongs to
/// `StudySessionStatus.isValidWith` — so Trash asks Study rather than writing
/// that table behind the enum's back.
ContentTrashRepository contentTrashRepositoryBinding(Ref ref) =>
    ContentTrashRepositoryImpl(
      TrashDao(ref.watch(appDatabaseProvider)),
      clock: ref.watch(clockProvider),
      study: ref.watch(studyRepositoryProvider),
    );

/// The list-and-restore half. No Study dependency: a restore closes nothing —
/// the sessions a deletion invalidated stay invalidated (BR-86), because
/// history is not rewritten by undoing the thing that ended it.
TrashRepository trashRepositoryBinding(Ref ref) => TrashRepositoryImpl(
  TrashDao(ref.watch(appDatabaseProvider)),
  clock: ref.watch(clockProvider),
);

/// The tag catalog (M99.30, UC-18).
///
/// **The database itself, and no clock.** One transaction has to cover the
/// collision test and the rename-or-merge that follows it (BR-234), which is
/// the same reason `cardRepositoryBinding` takes the database. No clock,
/// because a catalog operation stamps nothing: it writes `tags.name` /
/// `tags.name_folded` and rows of `card_tags`, none of which carry a timestamp,
/// and BR-236 forbids it from touching one that does.
TagCatalogRepository tagCatalogRepositoryBinding(Ref ref) =>
    TagCatalogRepositoryImpl(ref.watch(appDatabaseProvider));

/// The card detail read (UC-19). **No clock and no write path**: BR-239 makes
/// this surface read-only, and the binding is where that shows — an
/// implementation handed a clock would be one that could stamp something.
CardDetailRepository cardDetailRepositoryBinding(Ref ref) =>
    CardDetailRepositoryImpl(ref.watch(appDatabaseProvider));

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

/// Global Library Search (UC-20).
///
/// **The database itself, not a DAO** — the same difference `cardRepositoryBinding`
/// explains: the deck set and the card page must come from one transaction, and a
/// ready-made adapter would let this root hand the repository a snapshot from a
/// second database.
///
/// No clock: a search reads and stamps nothing.
LibrarySearchRepository librarySearchRepositoryBinding(Ref ref) =>
    LibrarySearchRepositoryImpl(ref.watch(appDatabaseProvider));

/// Study needs no clock: every one of its operations takes `now` as an argument,
/// because a session's whole behaviour turns on which instant it is measured
/// against and a repository that read the clock itself could not be tested at
/// the `due_at == now` boundary (AD-06).
///
/// It does take a random source, which is deliberately not injected here: the
/// default is a real one, and only a test replaces it. A seeded shuffle in
/// production would make every session lay its cards out in the same order.
/// Progress reads what studying produced and writes nothing (BR-190, BR-188),
/// so it
/// takes neither a clock nor an id generator: every instant it needs arrives as
/// an argument from `clockProvider` and `utcOffsetProvider` at the controller
/// (BR-184, BR-194),
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

/// The app's one global options row (BR-210).
///
/// **The database itself, not a DAO** — the same difference `cardRepositoryBinding`
/// explains. It takes the clock because every write stamps `updated_at` and
/// nothing under `lib/features/` may read the wall clock (AD-16).
AppSettingsRepository appSettingsRepositoryBinding(Ref ref) =>
    AppSettingsRepositoryImpl(
      ref.watch(appDatabaseProvider),
      clock: ref.watch(clockProvider),
    );

/// The starter catalog: the shipped assets, decoded once (UC-01).
///
/// A `Future` binding rather than a repository: there is no database and no
/// stream behind it, only the bundle the app was built with — which is why the
/// data source is not a repository either.
Future<List<DeckTemplate>> deckTemplateCatalogBinding(Ref ref) =>
    const DeckTemplateDataSource().loadAll();

/// The reminder's stored choice. Its own DAO for the reason `DeckTemplateDao`
/// has one: `app_settings` is shared with Study, but the two features read
/// disjoint columns, and one DAO would make every reminder write invalidate the
/// study options stream.
///
/// It takes the clock because `app_settings.updated_at` is a real fact about
/// the row; the workload repository does not, because every one of its
/// operations is measured against a `now` the caller supplies (AD-06, AD-16).
ReminderSettingsRepository reminderSettingsRepositoryBinding(Ref ref) =>
    ReminderSettingsRepositoryImpl(
      ReminderDao(ref.watch(appDatabaseProvider)),
      clock: ref.watch(clockProvider),
    );

ReminderWorkloadRepository reminderWorkloadRepositoryBinding(Ref ref) =>
    ReminderWorkloadRepositoryImpl(ReminderDao(ref.watch(appDatabaseProvider)));

/// **The one binding that chooses a platform, and the only place that may**
/// (BR-229, AD-21). Android gets the real adapter; Web and iOS get one that
/// reports the capability as unsupported and refuses to pretend otherwise.
///
/// `kIsWeb` first, because `defaultTargetPlatform` on the web reports the
/// *browser's* host OS — an Android phone running Chrome answers
/// `TargetPlatform.android`, and without the first check the web build would be
/// handed an adapter for plugins it has no business calling.
///
/// The Android adapter still probes at runtime (`readCapability`), so a device
/// or a test binding where the plugin is not registered reports `unsupported`
/// rather than throwing at the first toggle.
ReminderPlatformRepository reminderPlatformRepositoryBinding(Ref ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnsupportedReminderPlatformRepositoryImpl();
  }

  return AndroidReminderPlatformRepositoryImpl(
    notifier: ReminderNotificationDataSource(),
    scheduler: ReminderSchedulerDataSource(),
  );
}

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
  tagCatalogRepositoryProvider.overrideWith(tagCatalogRepositoryBinding),
  cardDetailRepositoryProvider.overrideWith(cardDetailRepositoryBinding),
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
  appSettingsRepositoryProvider.overrideWith(appSettingsRepositoryBinding),
  progressRepositoryProvider.overrideWith(progressRepositoryBinding),
  studyHomeRepositoryProvider.overrideWith(studyHomeRepositoryBinding),
  reminderSettingsRepositoryProvider.overrideWith(
    reminderSettingsRepositoryBinding,
  ),
  reminderWorkloadRepositoryProvider.overrideWith(
    reminderWorkloadRepositoryBinding,
  ),
  reminderPlatformRepositoryProvider.overrideWith(
    reminderPlatformRepositoryBinding,
  ),
  librarySearchRepositoryProvider.overrideWith(librarySearchRepositoryBinding),
  contentTrashRepositoryProvider.overrideWith(contentTrashRepositoryBinding),
  trashRepositoryProvider.overrideWith(trashRepositoryBinding),
];
