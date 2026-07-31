import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// One titled block of the design-system showcase.
///
/// Lives in `lib/app/dev/` and not in `shared/widgets/` on purpose: its only
/// caller is the dev-channel showcase, and a shared component with one caller
/// is the premature abstraction the component guidelines warn against. If a
/// product screen ever needs a titled section, that is a design decision to
/// take then — not an import of a dev tool.
class ShowcaseSectionWidget extends StatelessWidget {
  const ShowcaseSectionWidget({
    required this.title,
    required this.children,
    super.key,
  });

  /// English on purpose. The showcase is a debug-only developer tool, outside
  /// the ARB rule's `ui_surfaces` scope — the same standing decision that lets
  /// `MobileFrameWidget` paint its backdrop without a token.
  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: context.texts.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ...children,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// A captioned demo inside a section: the state's name above the widget that
/// demonstrates it.
class ShowcaseItemWidget extends StatelessWidget {
  const ShowcaseItemWidget({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
