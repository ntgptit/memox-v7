import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// The one scaffolded-branch placeholder left (AD-19).
///
/// It was two until M99.23/M99.24, when Progress got its real screens and moved
/// to `progress_screen_use_case.dart` and `progress_deck_screen_use_case.dart`
/// — both of which need a `ProviderScope` and a fake repository, and so could
/// not stay in a file whose whole premise is that there is nothing to wire.
///
/// No `ProviderScope`, no fake repository and no scenario dropdown, because this
/// screen is presentation-only: it reads nothing, so there is no state to
/// select. What the catalog is for here is the light/dark, text-scale and
/// 320-viewport addons, which are exactly the axes a static screen can still get
/// wrong.
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
