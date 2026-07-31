import 'package:flutter/material.dart';

import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import '../support/showcase_section.dart';

/// The typography section: every `TextTheme` role, rendered in itself, with
/// the resolved family, size, weight and line height spelled out beneath it.
class TokenTypographySectionWidget extends StatelessWidget {
  const TokenTypographySectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowcaseSectionWidget(
      title: 'Typography',
      children: <Widget>[
        for (final role in _typeRoles(context))
          _TypeSpecimen(name: role.name, style: role.style),
      ],
    );
  }
}

/// A text role paired with the name a caller would use to reach it.
class _TypeRole {
  const _TypeRole(this.name, this.style);

  final String name;
  final TextStyle? style;
}

List<_TypeRole> _typeRoles(BuildContext context) {
  final texts = context.texts;

  return <_TypeRole>[
    _TypeRole('displayLarge', texts.displayLarge),
    _TypeRole('displayMedium', texts.displayMedium),
    _TypeRole('displaySmall', texts.displaySmall),
    _TypeRole('headlineLarge', texts.headlineLarge),
    _TypeRole('headlineMedium', texts.headlineMedium),
    _TypeRole('headlineSmall', texts.headlineSmall),
    _TypeRole('titleLarge', texts.titleLarge),
    _TypeRole('titleMedium', texts.titleMedium),
    _TypeRole('titleSmall', texts.titleSmall),
    _TypeRole('bodyLarge', texts.bodyLarge),
    _TypeRole('bodyMedium', texts.bodyMedium),
    _TypeRole('bodySmall', texts.bodySmall),
    _TypeRole('labelLarge', texts.labelLarge),
    _TypeRole('labelMedium', texts.labelMedium),
    _TypeRole('labelSmall', texts.labelSmall),
  ];
}

class _TypeSpecimen extends StatelessWidget {
  const _TypeSpecimen({required this.name, required this.style});

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(name, style: style),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _spec(style),
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _spec(TextStyle? style) {
  if (style == null) return 'unresolved';

  final family = style.fontFamily ?? 'inherited';
  final size = style.fontSize?.toStringAsFixed(0) ?? 'inherited';
  final weight = style.fontWeight?.value.toString() ?? '400';
  final height = style.height == null
      ? ''
      : ' · line height ×${style.height!.toStringAsFixed(2)}';

  return '$family · ${size}sp · w$weight$height';
}
