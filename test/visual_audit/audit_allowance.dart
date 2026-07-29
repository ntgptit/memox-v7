import 'package:flutter/material.dart';

import 'audit_model.dart';

/// Written permission for one specific unreadable node to stay unreadable, and
/// the bookkeeping that keeps such permissions honest.
///
/// Split from the model because these types answer a different question. The
/// model describes what the screen paints; this file describes what a human
/// promised to check by other means — a promise that has to name its subject,
/// carry a reason, and expire loudly when it stops matching anything.

/// Permission for one specific unreadable node to stay unreadable.
///
/// Scoped on purpose. `{SkipReason.customPainter}` would wave through every
/// `CustomPainter` on the screen including ones added next year, which is the
/// same shape of mistake as a lint rule whose scope matches no files: it reads
/// as coverage and provides none.
///
/// [rationale] is required because an allowance is a promise that someone
/// checked this by other means, and a promise with no author is a silence.
@immutable
class AuditSkipAllowance {
  /// The asserts compare against literals rather than calling `trim()`, because
  /// a `const` constructor can only assert on compile-time-constant expressions.
  /// Whitespace-only values slip past here and are caught by
  /// [validateAllowances], which runs before any evaluation.
  const AuditSkipAllowance({
    required this.itemId,
    required this.reason,
    required this.detailContains,
    required this.rationale,
  }) : assert(itemId != '', 'An allowance must name the item it applies to.'),
       assert(
         detailContains != '',
         'An allowance must name what it allows. Matching every skip of a '
         'reason on an item is the blanket permission this type exists to '
         'prevent.',
       ),
       assert(
         rationale != '',
         'An allowance is a promise that someone checked this another way. '
         'Say who checked it and how.',
       );

  final String itemId;
  final SkipReason reason;

  /// Substring the skip's detail must contain.
  ///
  /// Required, not optional. Left out, an allowance covers every skip of its
  /// reason on its item — including the one added six months later that nobody
  /// has looked at. That is the same failure as a lint rule scoped to no files:
  /// it reads as coverage and provides none.
  final String detailContains;

  final String rationale;

  bool matches(AuditSkip skip) {
    if (skip.itemId != itemId) return false;
    if (skip.reason != reason) return false;

    return skip.detail.contains(detailContains);
  }

  @override
  String toString() => '$itemId/${reason.name} ~ "$detailContains"';
}

/// Throws on an allowance that would be too vague to mean anything.
///
/// A hard throw, not a finding: a malformed allowance is a bug in the test, and
/// turning it into another line of report would put it in the same list as the
/// things it is supposed to be resolving.
void validateAllowances(List<AuditSkipAllowance> allowances) {
  for (final allowance in allowances) {
    final fields = <String, String>{
      'itemId': allowance.itemId,
      'detailContains': allowance.detailContains,
      'rationale': allowance.rationale,
    };

    fields.forEach((name, value) {
      if (value.trim().isNotEmpty) return;

      throw ArgumentError.value(
        value,
        name,
        'AuditSkipAllowance.$name is blank on $allowance',
      );
    });
  }
}

/// A skip and the single allowance that accounted for it.
///
/// The pair is kept rather than just the skip, because the rationale is the only
/// part anyone will want six months from now: "four allowed" says a number,
/// "allowed because the focused border is covered by the state audit in M5" says
/// whether the permission is still true.
@immutable
class AuditAllowedSkip {
  const AuditAllowedSkip({required this.skip, required this.allowance});

  final AuditSkip skip;
  final AuditSkipAllowance allowance;

  @override
  String toString() =>
      '${skip.reason.name}: ${skip.detail}  [${skip.itemId}]\n'
      '           because: ${allowance.rationale}';
}

/// One skip matched by more than one allowance.
///
/// Not resolved, and deliberately not resolved by picking one. Two overlapping
/// permissions mean nobody can say which promise is being relied on, and a broad
/// allowance sitting behind a narrow one keeps working after the narrow one stops
/// being true.
@immutable
class AuditAllowanceConflict {
  const AuditAllowanceConflict({required this.skip, required this.allowances});

  final AuditSkip skip;
  final List<AuditSkipAllowance> allowances;

  @override
  String toString() =>
      '${skip.reason.name}: ${skip.detail}  [${skip.itemId}]  matched by '
      '${allowances.length}: ${allowances.join(' | ')}';
}
