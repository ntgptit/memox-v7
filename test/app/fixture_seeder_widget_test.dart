import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/startup/fixture_seeder_widget.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';

/// Records what it was asked to install, and answers whatever the test wants.
final class _RecordingTemplateRepository implements DeckTemplateRepository {
  final List<String> installed = <String>[];
  DeckTemplateInstallOutcome outcome = DeckTemplateInstallOutcome.installed;
  Exception? failWith;

  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    installed.add(template.templateId);

    return outcome;
  }
}

/// Which flavors seed, and what a failure does to the launch (M4.12, AD-07).
///
/// The repository is faked and the **assets are real**, because the two things
/// worth pinning here are the flavor gate and the fact that a broken asset does
/// not take the app down — neither of which needs a database.
void main() {
  Future<_RecordingTemplateRepository> pumpFor(
    WidgetTester tester,
    EnvConfig config, {
    Exception? failWith,
  }) async {
    final repository = _RecordingTemplateRepository()..failWith = failWith;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(config),
          deckTemplateRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FixtureSeederWidget(child: SizedBox.shrink()),
      ),
    );
    // The seed starts on the post-frame callback and then awaits the asset
    // decode; each pump drains the microtask queue. Bounded rather than
    // `pumpAndSettle` so a hang is a failure, not a ten-minute wait.
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    return repository;
  }

  testWidgets('a development launch installs every shipped template', (
    tester,
  ) async {
    final repository = await pumpFor(tester, EnvConfig.development);

    // Both fixtures, so a demo has an `eight_box` tree and an `sm2` one — the
    // two schedulers render different review actions (BR-30).
    expect(repository.installed.length, 2);
  });

  testWidgets('staging and production launch empty', (tester) async {
    // AD-07 refuses to write starter content into a user's data without asking.
    // The shipped decks are declared fixtures (BR-87), so they seed where a
    // fixture belongs and nowhere else; the other flavors will get the
    // starter-deck library screen AD-07 actually describes.
    expect((await pumpFor(tester, EnvConfig.staging)).installed, isEmpty);
    expect((await pumpFor(tester, EnvConfig.production)).installed, isEmpty);
  });

  testWidgets('a failing install does not take down the launch', (
    tester,
  ) async {
    final repository = await pumpFor(
      tester,
      EnvConfig.development,
      failWith: Exception('database is unavailable'),
    );

    // The child still rendered, and nothing escaped to the framework. A seed is
    // convenience; whatever the user opened the app to do is not.
    expect(repository.installed, isEmpty);
    expect(find.byType(SizedBox), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
