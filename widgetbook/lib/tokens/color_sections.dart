import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';

import '../support/showcase_section.dart';

/// The colour sections: the 45 `ColorScheme` roles the theme declares — the
/// 26 standard roles, then the 19 add-ons — and the `AppSemanticColors`
/// extension beside them.
///
/// Read from the live theme, never from `AppColors`, so a swatch shows the
/// colour a product widget would actually resolve — which is also what makes
/// the theme addon flip every swatch.
///
/// Every role, in the order Material lists them, so the page reads as the
/// lookup table it is. It used to show 32 of the 45 with standard and add-on
/// roles interleaved, and a role absent from this page is exactly how a gap
/// in the scheme stays invisible (M99.47, M100.17).
class TokenColorSectionsWidget extends StatelessWidget {
  const TokenColorSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseSectionWidget(
          title: 'ColorScheme · standard roles (26)',
          children: <Widget>[
            _ColorGrid(entries: _standardRoleEntries(context)),
          ],
        ),
        ShowcaseSectionWidget(
          title: 'ColorScheme · add-on roles (19)',
          children: <Widget>[_ColorGrid(entries: _addOnRoleEntries(context))],
        ),
        ShowcaseSectionWidget(
          title: 'Semantic colors (AppSemanticColors)',
          children: <Widget>[_ColorGrid(entries: _semanticEntries(context))],
        ),
      ],
    );
  }
}

/// A named colour, ready to swatch.
class _ColorEntry {
  const _ColorEntry(this.name, this.color);

  final String name;
  final Color color;
}

/// The 26 standard roles: four accent quartets, the surface trio, the outline
/// pair, the inverse trio, and the two utilities.
List<_ColorEntry> _standardRoleEntries(BuildContext context) {
  final colors = context.colors;

  return <_ColorEntry>[
    _ColorEntry('primary', colors.primary),
    _ColorEntry('onPrimary', colors.onPrimary),
    _ColorEntry('primaryContainer', colors.primaryContainer),
    _ColorEntry('onPrimaryContainer', colors.onPrimaryContainer),
    _ColorEntry('secondary', colors.secondary),
    _ColorEntry('onSecondary', colors.onSecondary),
    _ColorEntry('secondaryContainer', colors.secondaryContainer),
    _ColorEntry('onSecondaryContainer', colors.onSecondaryContainer),
    _ColorEntry('tertiary', colors.tertiary),
    _ColorEntry('onTertiary', colors.onTertiary),
    _ColorEntry('tertiaryContainer', colors.tertiaryContainer),
    _ColorEntry('onTertiaryContainer', colors.onTertiaryContainer),
    _ColorEntry('error', colors.error),
    _ColorEntry('onError', colors.onError),
    _ColorEntry('errorContainer', colors.errorContainer),
    _ColorEntry('onErrorContainer', colors.onErrorContainer),
    _ColorEntry('surface', colors.surface),
    _ColorEntry('onSurface', colors.onSurface),
    _ColorEntry('onSurfaceVariant', colors.onSurfaceVariant),
    _ColorEntry('outline', colors.outline),
    _ColorEntry('outlineVariant', colors.outlineVariant),
    _ColorEntry('inverseSurface', colors.inverseSurface),
    _ColorEntry('onInverseSurface', colors.onInverseSurface),
    _ColorEntry('inversePrimary', colors.inversePrimary),
    _ColorEntry('shadow', colors.shadow),
    _ColorEntry('scrim', colors.scrim),
  ];
}

/// The 19 add-on roles: the tone-based surface ladder and the three `*Fixed`
/// families.
List<_ColorEntry> _addOnRoleEntries(BuildContext context) {
  final colors = context.colors;

  return <_ColorEntry>[
    _ColorEntry('surfaceDim', colors.surfaceDim),
    _ColorEntry('surfaceBright', colors.surfaceBright),
    _ColorEntry('surfaceContainerLowest', colors.surfaceContainerLowest),
    _ColorEntry('surfaceContainerLow', colors.surfaceContainerLow),
    _ColorEntry('surfaceContainer', colors.surfaceContainer),
    _ColorEntry('surfaceContainerHigh', colors.surfaceContainerHigh),
    _ColorEntry('surfaceContainerHighest', colors.surfaceContainerHighest),
    // The `*Fixed` families. Swatched here rather than left to the role test
    // because they are the app's only generated colours: they carry their
    // palette's full chroma where the hand-tuned containers beside them
    // deliberately carry less, and a number cannot say whether that reads as
    // one system. Two swatches from the same family sit adjacent on purpose.
    _ColorEntry('primaryFixed', colors.primaryFixed),
    _ColorEntry('primaryFixedDim', colors.primaryFixedDim),
    _ColorEntry('onPrimaryFixed', colors.onPrimaryFixed),
    _ColorEntry('onPrimaryFixedVariant', colors.onPrimaryFixedVariant),
    _ColorEntry('secondaryFixed', colors.secondaryFixed),
    _ColorEntry('secondaryFixedDim', colors.secondaryFixedDim),
    _ColorEntry('onSecondaryFixed', colors.onSecondaryFixed),
    _ColorEntry('onSecondaryFixedVariant', colors.onSecondaryFixedVariant),
    _ColorEntry('tertiaryFixed', colors.tertiaryFixed),
    _ColorEntry('tertiaryFixedDim', colors.tertiaryFixedDim),
    _ColorEntry('onTertiaryFixed', colors.onTertiaryFixed),
    _ColorEntry('onTertiaryFixedVariant', colors.onTertiaryFixedVariant),
  ];
}

List<_ColorEntry> _semanticEntries(BuildContext context) {
  final semantic = context.semanticColors;

  return <_ColorEntry>[
    _ColorEntry('success', semantic.success),
    _ColorEntry('warning', semantic.warning),
    _ColorEntry('danger', semantic.danger),
    _ColorEntry('info', semantic.info),
    _ColorEntry('surfaceMuted', semantic.surfaceMuted),
    _ColorEntry('surfaceElevated', semantic.surfaceElevated),
    _ColorEntry('borderSubtle', semantic.borderSubtle),
  ];
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.entries});

  final List<_ColorEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: <Widget>[
        for (final entry in entries)
          _Swatch(name: entry.name, color: entry.color),
      ],
    );
  }
}

/// Width of one colour swatch card, sized so a 320-wide viewport fits two.
const double _swatchWidth = 132;

/// Height of the colour block inside a swatch.
const double _swatchHeight = 44;

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _swatchWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: _swatchHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                // Bordered so the swatch that matches the page background is
                // still visible as a swatch rather than as a hole.
                border: Border.all(color: context.semanticColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: context.texts.bodySmall),
          Text(
            _hex(color),
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _hex(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  // Alpha dropped: every token is fully opaque, so showing `FF` twenty times
  // would be noise in front of the six digits that differ.
  return '#${argb.substring(2)}';
}
