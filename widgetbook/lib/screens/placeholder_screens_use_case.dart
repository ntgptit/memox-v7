import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// The one branch still scaffolded ahead of its feature (AD-19).
///
/// No `ProviderScope`, no fake repository and no scenario dropdown, because the
/// screen is presentation-only: it reads nothing, so there is no state to
/// select. One use case — what the catalog is for here is the light/dark,
/// text-scale and 320-viewport addons, which are exactly the axes a static
/// screen can still get wrong.
///
/// Progress used to be the second entry. It has a feature now (UC-12), so it
/// has a use case of its own with real states — see
/// `progress_deck_screen_use_case.dart`.
List<WidgetbookComponent> placeholderScreenComponents() =>
    <WidgetbookComponent>[
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
