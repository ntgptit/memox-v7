import 'package:flutter/material.dart';

import '../../../l10n/l10n_extension.dart';

/// The review feature's entry surface until the real session screen exists.
///
/// Structural anchor for `features/review/presentation/`, and the app's home:
/// review is the only feature in the MVP, so the placeholder belongs to it
/// rather than to the app shell. M5.4 replaces this with the real session
/// screen; the route into it is wired in M4.1.
///
/// It reads its text from the ARB files, so the "no user-visible string outside
/// ARB" rule holds from the feature's very first screen instead of being
/// retrofitted once there are many.
class ReviewPlaceholderScreen extends StatelessWidget {
  const ReviewPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.l10n.homePlaceholderMessage)),
    );
  }
}
