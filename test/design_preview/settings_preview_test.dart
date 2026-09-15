@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

import '../visual_audit/memox_audit.dart';
import 'preview_harness.dart';

/// Settings — the screen that shows whether the palette survives density.
///
/// A study screen has one card and two buttons; a settings screen has a dozen
/// rows, switches, dividers and one destructive action. This is where a canvas
/// that is a little too saturated stops being atmospheric and starts being
/// noisy, and where `danger` has to stay distinguishable from ordinary chrome
/// without turning the row into a warning.
void main() {
  previewTest('settings', () => const _SettingsScreen());
  memoxAuditTest('settings', () => const _SettingsScreen());
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionLabel('Study'),
            PreviewCard(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: <Widget>[
                  _SwitchRow(title: 'Daily reminder', value: true),
                  _RowDivider(),
                  _ValueRow(title: 'Scheduler', value: 'Eight box'),
                  _RowDivider(),
                  _ValueRow(title: 'New cards per day', value: '20'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            SectionLabel('Appearance'),
            PreviewCard(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: <Widget>[
                  _ValueRow(title: 'Theme', value: 'System'),
                  _RowDivider(),
                  _SwitchRow(title: 'Larger text', value: false),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            SectionLabel('Data'),
            PreviewCard(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: <Widget>[
                  _ValueRow(title: 'Export decks', value: ''),
                  _RowDivider(),
                  _DestructiveRow(title: 'Reset learning progress'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value});

  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Switch(value: value, onChanged: (_) {}),
      ],
    ),
  );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// `danger` as a label, not as a fill. A destructive row that is a red block
/// reads as an error the app is reporting rather than an action the user can
/// take, and it drags the eye to the bottom of every settings screen.
class _DestructiveRow extends StatelessWidget {
  const _DestructiveRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.restart_alt, size: 20, color: semantic.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: semantic.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      color: semantic.borderSubtle,
    );
  }
}
