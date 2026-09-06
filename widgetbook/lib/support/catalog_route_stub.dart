import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// The edge of a use-case: where a catalog router lands when the screen under
/// review navigates somewhere the entry does not catalogue.
///
/// **A stand-in, and it says so.** A screen's controls are half of what a
/// reviewer comes to check, and a control that throws is worse than one that
/// does nothing — so the routers in `screens/` register every name their
/// subject can reach. Most of those destinations are other screens with their
/// own entries and their own fakes; wiring them into this router would mean
/// building a second app inside the catalog. This page is the honest end of
/// the line: it names the route that was reached, so a tap that worked is
/// visibly distinguishable from a tap that did nothing.
///
/// Deliberately plain. Anything that looked like a memox screen here would be
/// a screen the app does not have, sitting in the catalog that exists to say
/// what the app looks like.
class CatalogRouteStubPage extends StatelessWidget {
  const CatalogRouteStubPage({required this.routeName, super.key});

  /// The route the screen navigated to, shown verbatim.
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.subdirectory_arrow_right,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  routeName,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Navigated out of this use-case. '
                  'The destination has a catalog entry of its own.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
