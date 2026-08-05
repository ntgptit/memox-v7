import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/deck/data/datasources/deck_template_data_source.dart';
import '../../features/deck/di/deck_template_provider.dart';
import '../config/env_config.dart';
import '../config/env_config_provider.dart';

/// Copies the shipped fixture decks into an empty database, on development
/// builds only.
///
/// **Development only, and that is AD-07 rather than caution.** The decision
/// says starter content is copied *on use*, never inserted at startup, because
/// inserting at startup writes into the user's own data without asking. That
/// argument holds for real starter content. It does not describe this: the
/// shipped decks are declared fixtures for development and test (BR-87), and
/// M4.12 needs the app demoable without anyone editing a database by hand. So
/// the seed runs where a fixture belongs and nowhere else — staging and
/// production launch empty and will get the starter-deck library screen that
/// AD-07 actually describes.
///
/// **It does not block the first frame.** The seed runs after mount, and the
/// deck list is watching a stream: when the transaction commits, the rows
/// arrive and the list rebuilds. Awaiting it before `runApp` would trade a
/// working empty screen for a longer white one.
///
/// **A failure is logged, not surfaced.** Nothing the user can do about a
/// malformed asset in a development build, and taking down startup for it would
/// hide whatever they were actually working on. `DeckTemplateFormatException`
/// names the file and the field.
class FixtureSeederWidget extends ConsumerStatefulWidget {
  const FixtureSeederWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FixtureSeederWidget> createState() =>
      _FixtureSeederWidgetState();
}

class _FixtureSeederWidgetState extends ConsumerState<FixtureSeederWidget> {
  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback`, not a bare call: `initState` runs during build,
    // and reading a provider that builds a repository there is a modification
    // mid-build. One frame later the tree is settled.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_seed()));
  }

  Future<void> _seed() async {
    if (ref.read(envConfigProvider).environment != AppEnvironment.development) {
      return;
    }

    try {
      final templates = await const DeckTemplateDataSource().loadAll();
      // `ref.read` after an await needs the guard: the widget can be gone by
      // the time the assets have been decoded, and reading a disposed ref
      // throws.
      if (!mounted) return;
      final report = await ref.read(installDeckTemplatesUseCaseProvider)(
        templates,
      );
      developer.log(
        'fixture seed: '
        '${report.map((entry) => '${entry.templateId}=${entry.outcome.name}').join(', ')}',
        name: 'memox.startup',
      );
    } on Object catch (error, stackTrace) {
      // Width is deliberate: an asset problem, a database problem and a
      // programming error all land here, and none of them may take down a
      // launch whose real work is elsewhere.
      developer.log(
        'fixture seed failed',
        name: 'memox.startup',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
