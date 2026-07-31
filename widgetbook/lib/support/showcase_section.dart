import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/theme_context_extension.dart';

/// One titled block of a token page.
class ShowcaseSectionWidget extends StatelessWidget {
  const ShowcaseSectionWidget({
    required this.title,
    required this.children,
    super.key,
  });

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
