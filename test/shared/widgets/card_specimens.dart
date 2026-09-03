import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// The two Card specimens that are about **relation**, not about one card.
///
/// Every other card golden in this suite shoots a single recipe, which is the
/// right shape for "does `raised` still paint `surfaceContainerLow`" and the
/// wrong one for the defect M100.35 fixed. That defect was only visible in the
/// plural: one dark card wearing a bright blurred rim looks deliberate, and ten
/// of them down a phone column read as neon stripes. A specimen that renders
/// one card can never fail on it.
///
/// So these two hold cards **next to each other**: a depth ladder plus a stack
/// of identical list cards, and the state matrix with a neutral card beside it
/// for scale.
class CardDepthSpecimen extends StatelessWidget {
  const CardDepthSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The ladder, in order, so `none < card < raised` either reads or
            // does not.
            MxCard.flat(child: Text('flat — no depth')),
            SizedBox(height: 12),
            MxCard.raised(child: Text('raised — one step')),
            SizedBox(height: 12),
            MxCard.focal(child: Text('focal — the lifted one')),
            SizedBox(height: 24),
            // Repetition is the test. Three identical list cards: if the depth
            // cue is louder than the content, this band is what shows it.
            MxCard.raised(child: Text('Academic Word List')),
            SizedBox(height: 12),
            MxCard.raised(child: Text('IELTS Writing Task 2')),
            SizedBox(height: 12),
            MxCard.raised(child: Text('Phrasal verbs')),
          ],
        ),
      ),
    );
  }
}

/// Selection, option and disabled, each beside a plain card for scale.
class CardStatesSpecimen extends StatelessWidget {
  const CardStatesSpecimen({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MxCard.raised(child: Text('unselected — the neutral')),
            SizedBox(height: 12),
            MxCard.flat(
              isSelected: true,
              onTap: _noop,
              child: Text('selected — edge treatment'),
            ),
            SizedBox(height: 12),
            MxCard.flat(
              isSelected: true,
              selectionTreatment: MxCardSelectionTreatment.tint,
              onTap: _noop,
              child: Text('selected — tint treatment'),
            ),
            SizedBox(height: 24),
            MxCard.option(
              isSelected: true,
              onTap: _noop,
              child: Text('option — picked'),
            ),
            SizedBox(height: 12),
            MxCard.option(
              isSelected: false,
              onTap: _noop,
              child: Text('option — available'),
            ),
            SizedBox(height: 12),
            // The state M100.35 gave a face: a control whose handler was
            // withheld. It used to render identically to the one above it.
            MxCard.option(
              isSelected: false,
              onTap: null,
              child: Text('option — disabled'),
            ),
            SizedBox(height: 24),
            MxCard.recessed(
              edge: MxCardRecessedEdge.success,
              child: Text('recessed — success verdict'),
            ),
            SizedBox(height: 12),
            MxCard.recessed(
              edge: MxCardRecessedEdge.danger,
              child: Text('recessed — danger verdict'),
            ),
          ],
        ),
      ),
    );
  }
}
