import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'audit_rules.dart';

/// Fails the test on blocking findings, and prints everything else.
///
/// The printing is not decoration. A screen with zero violations and eleven
/// unread nodes is not a screen that passed — it is a screen that was partly
/// looked at, and the only thing standing between that and a false sense of
/// coverage is the list being visible in the test output.
void expectAuditClean(
  ScreenAudit audit,
  List<AuditRule> rules, {
  Set<SkipReason> tolerated = const <SkipReason>{},
}) {
  final findings = runAuditRules(audit, rules);
  final blocking = findings.where((finding) => finding.isBlocking).toList();
  final notes = findings.where((finding) => !finding.isBlocking).toList();
  final skips = audit.skips
      .where((skip) => !tolerated.contains(skip.reason))
      .toList();

  final report = StringBuffer('${audit.label}  ${audit.items.length} items, ')
    ..writeln('${audit.allPaints.length} paints');
  for (final note in notes) {
    report.writeln('  $note');
  }
  for (final skip in skips) {
    report.writeln('  skipped  $skip');
  }
  // `debugPrint`, and unconditional: the unread list is the point. Routing it
  // through `printOnFailure` would show it only when something else already
  // broke, which is exactly when nobody is reading it.
  debugPrint(report.toString().trimRight());

  expect(blocking, isEmpty, reason: '${audit.label}\n${blocking.join('\n')}');
}

/// Machine-readable form, for diffing two runs or handing to another tool.
String auditToJson(
  ScreenAudit audit, {
  List<AuditFinding> findings = const [],
}) {
  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'screen': audit.screen,
    'theme': audit.theme,
    'state': audit.state,
    'viewport': <String, double>{
      'width': audit.viewport.width,
      'height': audit.viewport.height,
    },
    'items': <Object>[
      for (final item in audit.items)
        <String, Object?>{
          'id': item.id,
          'rect': _rect(item),
          'paints': <Object>[
            for (final paint in item.paints)
              <String, Object?>{
                'role': paint.role.name,
                'source': paint.source.name,
                'color': hexOf(paint.color),
                'origin': paint.origin,
                if (paint.fontSize != null) 'fontSize': paint.fontSize,
                if (paint.role == PaintRole.text)
                  'largeText': paint.isLargeText,
              },
          ],
        },
    ],
    'skipped': <Object>[
      for (final skip in audit.skips)
        <String, Object?>{
          'item': skip.itemId,
          'reason': skip.reason.name,
          'detail': skip.detail,
        },
    ],
    'findings': <Object>[
      for (final finding in findings)
        <String, Object?>{
          'rule': finding.rule,
          'item': finding.itemId,
          'blocking': finding.isBlocking,
          'message': finding.message,
        },
    ],
  });
}

List<double> _rect(AuditItem item) => <double>[
  item.rect.left,
  item.rect.top,
  item.rect.width,
  item.rect.height,
];
