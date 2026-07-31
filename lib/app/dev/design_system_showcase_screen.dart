import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mx_icon_button.dart';
import 'component_gallery_widget.dart';
import 'token_gallery_widget.dart';

/// The design-system showcase — a dev-channel tool, not a product screen.
///
/// One screen that renders every design token with its resolved value and
/// every `Mx*` shared component in every state, so a change to
/// `core/theme/` or `shared/widgets/` can be reviewed in one place instead of
/// by hunting for whichever product screens happen to use the changed piece.
/// The toolbar flips light/dark and cycles the text scale **locally**, so both
/// themes and large type are inspectable side by side without touching device
/// settings.
///
/// **Where it lives, and why that is load-bearing.** `lib/app/dev/` is the
/// dev channel: outside the guard's `ui_surfaces` scope, outside MX-VIS-001's
/// production-screen roots, and outside the ARB rule — the same standing
/// decision that lets `MobileFrameWidget` paint a tokenless backdrop. The copy
/// here is deliberately English-only; localizing a developer tool would spend
/// translator effort on strings no user ever sees. Everything else still comes
/// from tokens, because this screen exists to show the tokens.
///
/// **How it is reached.** Only via `RoutePaths.devDesignSystem`, and only when
/// the route table was built with dev routes enabled (debug builds — see
/// `createAppRouter`). No product screen links here.
class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

/// The scales worth checking, in cycling order: the default, the common large
/// setting, and the accessibility ceiling every component must survive.
const List<double> _textScaleSteps = <double>[1.0, 1.5, 2.0];

class _DesignSystemShowcaseScreenState
    extends State<DesignSystemShowcaseScreen> {
  /// `null` until the developer toggles: follow the app's current brightness,
  /// so the screen opens showing the theme the rest of the app is in.
  bool? _isDarkOverride;

  int _textScaleIndex = 0;

  double get _textScale => _textScaleSteps[_textScaleIndex];

  void _toggleBrightness(bool isCurrentlyDark) {
    setState(() => _isDarkOverride = !isCurrentlyDark);
  }

  void _cycleTextScale() {
    setState(
      () => _textScaleIndex = (_textScaleIndex + 1) % _textScaleSteps.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        _isDarkOverride ?? Theme.of(context).brightness == Brightness.dark;

    // A full theme override rather than a stored ThemeMode: the showcase must
    // not change the app's theme, only its own subtree — flipping to dark here
    // and popping back to a light app is the whole point of a local toggle.
    return Theme(
      data: isDark ? buildDarkTheme() : buildLightTheme(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Design system'),
            actions: <Widget>[
              MxIconButton(
                icon: Icons.text_fields,
                semanticLabel:
                    'Text scale ×${_textScale.toStringAsFixed(1)} — '
                    'tap to cycle',
                onPressed: _cycleTextScale,
              ),
              MxIconButton(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                semanticLabel: isDark
                    ? 'Switch to light theme'
                    : 'Switch to dark theme',
                onPressed: () => _toggleBrightness(isDark),
              ),
            ],
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'Tokens'),
                Tab(text: 'Components'),
              ],
            ),
          ),
          body: SafeArea(
            // Scaled below the toolbar, not around it: the tab bar and the
            // toggle buttons are the instrument, the galleries are the
            // specimen.
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(_textScale)),
              child: const TabBarView(
                children: <Widget>[
                  TokenGalleryWidget(),
                  ComponentGalleryWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
