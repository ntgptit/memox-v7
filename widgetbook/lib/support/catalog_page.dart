import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';

/// A scrolling page for token galleries and other long content.
///
/// A `Scaffold` is load-bearing, not decoration: several `Mx*` components are
/// built on `ListTile`, which throws without a `Material` ancestor — and the
/// theme addon wraps use-cases in a plain `ColoredBox`, not a `Scaffold`.
class CatalogListPage extends StatelessWidget {
  const CatalogListPage({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: children,
        ),
      ),
    );
  }
}

/// A centred page for single-component playgrounds.
class CatalogCenterPage extends StatelessWidget {
  const CatalogCenterPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
