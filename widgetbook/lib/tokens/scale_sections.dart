import 'package:flutter/material.dart';

import 'package:memox/core/theme/app_breakpoints.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/core/theme/app_icon_size.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import '../support/showcase_section.dart';

/// The scale-token sections of the token gallery: spacing, radius, icon
/// sizes, durations and breakpoints — the tokens with no theme indirection,
/// read straight from their `abstract final class` holders.
class TokenScaleSectionsWidget extends StatelessWidget {
  const TokenScaleSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SpacingSection(),
        _RadiusSection(),
        _IconSizeSection(),
        _DurationsSection(),
        _BreakpointsSection(),
      ],
    );
  }
}

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'Spacing (AppSpacing)',
      children: <Widget>[
        _SpacingBar(name: 'xs', value: AppSpacing.xs),
        _SpacingBar(name: 'sm', value: AppSpacing.sm),
        _SpacingBar(name: 'md', value: AppSpacing.md),
        _SpacingBar(name: 'lg', value: AppSpacing.lg),
        _SpacingBar(name: 'xl', value: AppSpacing.xl),
        _SpacingBar(name: 'xxl', value: AppSpacing.xxl),
        _TouchTargetDemo(),
      ],
    );
  }
}

class _RadiusSection extends StatelessWidget {
  const _RadiusSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'Radius (AppRadius)',
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            _RadiusBox(name: 'sm', value: AppRadius.sm),
            _RadiusBox(name: 'md', value: AppRadius.md),
            _RadiusBox(name: 'lg', value: AppRadius.lg),
            _RadiusBox(name: 'pill', value: AppRadius.pill),
          ],
        ),
      ],
    );
  }
}

class _IconSizeSection extends StatelessWidget {
  const _IconSizeSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'Icon sizes (AppIconSize)',
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            _IconSizeDemo(name: 'sm', value: AppIconSize.sm),
            _IconSizeDemo(name: 'md', value: AppIconSize.md),
            _IconSizeDemo(name: 'lg', value: AppIconSize.lg),
          ],
        ),
      ],
    );
  }
}

class _DurationsSection extends StatelessWidget {
  const _DurationsSection();

  @override
  Widget build(BuildContext context) {
    return ShowcaseSectionWidget(
      title: 'Durations (AppDurations)',
      children: <Widget>[
        _FactRow(name: 'fast', value: '${AppDurations.fast.inMilliseconds} ms'),
        _FactRow(
          name: 'normal',
          value: '${AppDurations.normal.inMilliseconds} ms',
        ),
        _FactRow(name: 'slow', value: '${AppDurations.slow.inMilliseconds} ms'),
      ],
    );
  }
}

class _BreakpointsSection extends StatelessWidget {
  const _BreakpointsSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return ShowcaseSectionWidget(
      title: 'Breakpoints (AppBreakpoints)',
      children: <Widget>[
        _FactRow(
          name: 'compact',
          value: '< ${AppBreakpoints.compact.toStringAsFixed(0)} logical px',
        ),
        _FactRow(
          name: 'medium',
          value:
              '${AppBreakpoints.medium.toStringAsFixed(0)} logical px '
              '(documented, unused)',
        ),
        _FactRow(
          name: 'current width',
          value:
              '${width.toStringAsFixed(0)} px — '
              '${AppBreakpoints.isCompact(width) ? 'compact' : 'regular'}',
        ),
      ],
    );
  }
}

class _SpacingBar extends StatelessWidget {
  const _SpacingBar({required this.name, required this.value});

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _factNameWidth,
            child: Text(
              '$name · ${value.toStringAsFixed(0)}',
              style: context.texts.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // The bar is the token's exact width — honest, even though the small
          // steps render small. A scaled-up bar would misstate the one fact
          // this row exists to show.
          SizedBox(
            width: value,
            height: AppSpacing.md,
            child: ColoredBox(color: context.colors.primary),
          ),
        ],
      ),
    );
  }
}

class _TouchTargetDemo extends StatelessWidget {
  const _TouchTargetDemo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _factNameWidth,
            child: Text(
              'minimumTouchTarget · '
              '${AppSpacing.minimumTouchTarget.toStringAsFixed(0)}',
              style: context.texts.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox.square(
            dimension: AppSpacing.minimumTouchTarget,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: context.semanticColors.focusRing),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Width of the demo box a radius is carved from.
const double _radiusBoxWidth = 96;

/// Height of the demo box a radius is carved from.
const double _radiusBoxHeight = 56;

class _RadiusBox extends StatelessWidget {
  const _RadiusBox({required this.name, required this.value});

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _radiusBoxWidth,
          height: _radiusBoxHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.semanticColors.surfaceMuted,
              borderRadius: BorderRadius.circular(value),
              border: Border.all(color: context.semanticColors.borderSubtle),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$name · ${value.toStringAsFixed(0)}',
          style: context.texts.bodySmall,
        ),
      ],
    );
  }
}

class _IconSizeDemo extends StatelessWidget {
  const _IconSizeDemo({required this.name, required this.value});

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(Icons.style_outlined, size: value),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$name · ${value.toStringAsFixed(0)}',
          style: context.texts.bodySmall,
        ),
      ],
    );
  }
}

/// Width of the name column in fact rows, wide enough for the longest token
/// name at regular scale; longer text wraps rather than clipping.
const double _factNameWidth = 168;

class _FactRow extends StatelessWidget {
  const _FactRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _factNameWidth,
            child: Text(name, style: context.texts.bodySmall),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(value, style: context.texts.bodySmall)),
        ],
      ),
    );
  }
}
