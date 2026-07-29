import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The loading state, centred in whatever space it is given.
///
/// Takes an already-localized [semanticsLabel] because a bare spinner is
/// invisible to a screen reader — it announces nothing at all, so the user is
/// told neither that something is happening nor when it stops.
class MxLoadingState extends StatelessWidget {
  const MxLoadingState({required this.semanticsLabel, super.key});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(
          semanticsLabel: semanticsLabel,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
