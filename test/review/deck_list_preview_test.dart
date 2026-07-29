@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';

import 'preview_harness.dart';

/// The deck list — where the primary action lives.
///
/// The review screen has no CTA at all, so this is the only screen that shows
/// whether an indigo filled button sits correctly on the navy page: bright
/// enough to be the obvious next step, quiet enough that a list of decks still
/// reads as the content.
void main() {
  previewTest('deck_list', () => const _DeckListScreen());
}

const List<_Deck> _decks = <_Deck>[
  _Deck(name: 'Academic Word List', detail: '20 of 570 learned', due: 12),
  _Deck(name: 'IELTS Writing Task 2', detail: '145 of 210 learned', due: 3),
  _Deck(name: 'Phrasal verbs', detail: '88 of 88 learned', due: 0),
  _Deck(name: 'Business email', detail: 'Not started', due: 0),
];

class _Deck {
  const _Deck({required this.name, required this.detail, required this.due});

  final String name;
  final String detail;
  final int due;
}

class _DeckListScreen extends StatelessWidget {
  const _DeckListScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(Icons.add, color: scheme.onSurface),
          ),
        ],
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
            const TextField(
              decoration: InputDecoration(hintText: 'Search your decks'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Study 15 cards due today'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionLabel('Your decks'),
            for (final deck in _decks) ...<Widget>[
              _DeckRow(deck: deck),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck});

  final _Deck deck;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final texts = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return PreviewCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: semantic.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.style_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(deck.name, style: texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  deck.detail,
                  style: texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _DueBadge(due: deck.due),
        ],
      ),
    );
  }
}

/// The only place a semantic colour appears in a list: a count that is genuinely
/// actionable. A deck with nothing due gets no colour at all — a badge on every
/// row would make the colour mean "row" instead of "due".
class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.due});

  final int due;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final texts = Theme.of(context).textTheme;

    if (due == 0) {
      return Icon(
        Icons.check_circle_outline,
        size: 18,
        color: semantic.success,
      );
    }

    return Text(
      '$due due',
      style: texts.labelMedium?.copyWith(color: semantic.warning),
    );
  }
}
