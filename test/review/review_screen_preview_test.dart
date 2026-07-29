@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';

import '../visual_audit/memox_audit.dart';
import '../visual_audit/screen_auditor.dart';
import 'preview_harness.dart';

/// The review screen — the one that decides the palette.
///
/// Everything else in the app is chrome around this. If the flashcard is not
/// the most prominent thing here, the palette is wrong regardless of how the
/// other screens look.
void main() {
  previewTest('review', () => const _ReviewScreen());
  // Anchors name the parts worth reading in a report; they do not bound what is
  // covered. Everything outside them still belongs to the implicit `screen`
  // item, so a widget added later is audited whether or not anyone lists it.
  memoxAuditTest(
    'review',
    () => const _ReviewScreen(),
    anchors: <AuditAnchor>[
      AuditAnchor.type('flashcard', PreviewCard),
      AuditAnchor.type('verdict', VerdictAction),
    ],
  );
}

class _ReviewScreen extends StatelessWidget {
  const _ReviewScreen();

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final texts = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.close, color: scheme.onSurface),
        title: const Text('Academic Word List'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '3 of 20',
                  style: texts.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: semantic.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '7-day streak',
                  style: texts.bodySmall?.copyWith(color: semantic.info),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // THE FLASHCARD.
            PreviewCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ephemeral',
                    style: texts.headlineMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'adjective · lasting for a very short time',
                    style: texts.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '“Fashions are ephemeral: new ones regularly displace '
                    'the old.”',
                    style: texts.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const _VerdictRow(label: 'At rest', selected: null),
            const SizedBox(height: AppSpacing.lg),
            const _VerdictRow(label: 'Remembered chosen', selected: true),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('End session'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: <Widget>[
                Icon(Icons.error_outline, size: 18, color: semantic.danger),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Could not sync — changes are saved on this device',
                    style: texts.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Both verdict states are rendered on the same screen on purpose: idle beside
/// selected is the only way to see whether "selected" reads as a choice rather
/// than as an alert.
class _VerdictRow extends StatelessWidget {
  const _VerdictRow({required this.label, required this.selected});

  final String label;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionLabel(label),
        Row(
          children: <Widget>[
            Expanded(
              child: VerdictAction(
                label: 'Forgotten',
                tint: semantic.danger,
                isSelected: selected == false,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: VerdictAction(
                label: 'Remembered',
                tint: semantic.success,
                isSelected: selected ?? false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
