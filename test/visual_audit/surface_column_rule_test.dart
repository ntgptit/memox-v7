import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'audit_rules.dart';

/// What the geometry rule must catch, and what it must stay quiet about.
///
/// A gate nobody has watched fire is a gate nobody should trust — the whole
/// reason this rule exists is that four other gates were green over a real
/// defect. The first case here *is* that defect, to scale.
void main() {
  ScreenAudit auditOf(List<Rect> surfaces) => ScreenAudit(
    screen: 'probe',
    theme: 'light',
    state: 'idle',
    viewport: const Size(400, 800),
    items: const <AuditItem>[],
    skips: const <AuditSkip>[],
    surfaces: surfaces,
  );

  List<AuditFinding> check(List<Rect> surfaces) =>
      const SurfaceColumnRule().check(auditOf(surfaces)).toList();

  test('a row sized to its content, inboard of the column, fails', () {
    // Card Import's `Wrap` to scale: two cards stop at 352 while the panel
    // below runs to 384 (M99.19a finding V9).
    final findings = check(<Rect>[
      const Rect.fromLTRB(16, 100, 180, 200),
      const Rect.fromLTRB(188, 100, 352, 200),
      const Rect.fromLTRB(16, 220, 384, 320),
    ]);

    expect(findings, hasLength(1));
    expect(findings.single.isBlocking, isTrue);
    expect(findings.single.message, contains('16..352'));
    expect(findings.single.message, contains('column is 16..384'));
  });

  test('the same two cards as equal halves of the column pass', () {
    expect(
      check(<Rect>[
        const Rect.fromLTRB(16, 100, 196, 200),
        const Rect.fromLTRB(204, 100, 384, 200),
        const Rect.fromLTRB(16, 220, 384, 320),
      ]),
      isEmpty,
    );
  });

  test('a row that starts late is caught as well as one that ends early', () {
    final findings = check(<Rect>[
      const Rect.fromLTRB(64, 100, 384, 200),
      const Rect.fromLTRB(16, 220, 384, 320),
    ]);

    expect(findings, hasLength(1));
    expect(findings.single.message, contains('64..384'));
  });

  test('cards of unequal height still count as one row', () {
    // A wrapped subtitle makes one card taller. Splitting the row there would
    // judge each card alone and let a ragged pair through.
    expect(
      check(<Rect>[
        const Rect.fromLTRB(16, 100, 180, 260),
        const Rect.fromLTRB(188, 100, 352, 200),
        const Rect.fromLTRB(16, 280, 384, 380),
      ]),
      hasLength(1),
    );
  });

  test(
    'a panel nested inside a card is judged by its card, not the column',
    () {
      expect(
        check(<Rect>[
          const Rect.fromLTRB(16, 100, 384, 300),
          // A helper panel inside it, placed against that card's padding.
          const Rect.fromLTRB(32, 140, 368, 220),
          const Rect.fromLTRB(16, 320, 384, 400),
        ]),
        isEmpty,
      );
    },
  );

  test('a screen whose surfaces are all narrow judges consistency, not an '
      'absolute inset', () {
    expect(
      check(<Rect>[
        const Rect.fromLTRB(80, 100, 320, 200),
        const Rect.fromLTRB(80, 220, 320, 320),
      ]),
      isEmpty,
    );
  });

  test('one surface is not a column', () {
    expect(check(<Rect>[const Rect.fromLTRB(16, 100, 180, 200)]), isEmpty);
  });
}
