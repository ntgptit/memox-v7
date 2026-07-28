import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// The screen shell every screen uses.
///
/// Exists so screen padding and the app-bar shape are decided once. Without it
/// each screen picks its own padding and the difference is visible the moment
/// two screens sit next to each other in a flow.
class AppScaffoldWidget extends StatelessWidget {
  const AppScaffoldWidget({
    required this.body,
    this.title,
    this.actions,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget body;

  /// Already-localized text. Components never reach for ARB themselves — the
  /// screen that owns the copy passes it in.
  final String? title;

  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(
        child: Padding(padding: padding, child: body),
      ),
    );
  }
}
