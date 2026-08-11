import 'package:memox/features/progress/presentation/screens/progress_placeholder_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// The two scaffolded-branch placeholders (AD-19).
///
/// No `ProviderScope`, no fake repository and no scenario dropdown, because the
/// screens are presentation-only: they read nothing, so there is no state to
/// select. One use-case each — what the catalog is for here is the light/dark,
/// text-scale and 320-viewport addons, which are exactly the axes a static
/// screen can still get wrong.
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
      WidgetbookComponent(
        name: 'SettingsPlaceholderScreen',
        useCases: <WidgetbookUseCase>[
          WidgetbookUseCase(
            name: 'Playground',
            builder: (context) => const SettingsPlaceholderScreen(),
          ),
        ],
      ),
    ];
