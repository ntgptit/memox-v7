import 'package:memox/features/progress/presentation/screens/progress_placeholder_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// The one scaffolded-branch placeholder still standing (AD-19).
///
/// No `ProviderScope`, no fake repository and no scenario dropdown, because the
/// screen is presentation-only: it reads nothing, so there is no state to
/// select. What the catalog is for here is the light/dark, text-scale and
/// 320-viewport addons, which are exactly the axes a static screen can still
/// get wrong.
///
/// **Settings left this file at M99.23.** It has a repository, four states and
/// three groups, so it is catalogued beside the other real screens in
/// `settings_screens_use_case.dart`.
List<WidgetbookComponent> placeholderScreenComponents() =>
    <WidgetbookComponent>[
      WidgetbookComponent(
        name: 'ProgressPlaceholderScreen',
        useCases: <WidgetbookUseCase>[
          WidgetbookUseCase(
            name: 'Playground',
            builder: (context) => const ProgressPlaceholderScreen(),
          ),
        ],
      ),
    ];
