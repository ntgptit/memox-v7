import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'token_color_sections_widget.dart';
import 'token_scale_sections_widget.dart';
import 'token_typography_section_widget.dart';

/// The Tokens tab: every design token, rendered with its resolved value.
///
/// Colour and typography are read back from the live theme (`context.colors`,
/// `context.texts`, `context.semanticColors`) rather than from `AppColors`
/// directly, so what this tab shows is what a product screen would actually
/// get — including anything the theme construction remaps. The scale tokens
/// (`AppSpacing`, `AppRadius`, `AppIconSize`, `AppDurations`,
/// `AppBreakpoints`) have no theme indirection, so those are read at the
/// source.
///
/// One section group per file, one file per token family — the same reason the
/// tokens themselves are one file per family.
class TokenGalleryWidget extends StatelessWidget {
  const TokenGalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const <Widget>[
        TokenColorSectionsWidget(),
        TokenTypographySectionWidget(),
        TokenScaleSectionsWidget(),
      ],
    );
  }
}
