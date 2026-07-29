import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'audited_screens.dart';
import 'screen_audit_coverage.dart';

/// The gate: a screen added to `lib/` must be registered for audit.
///
/// It runs inside `flutter test`, not in the guard and not in a shell script.
/// The guard reads one file at a time, and this question spans two trees; a
/// shell script would have to re-derive from file names what the registry
/// already states. Here the check reads the registry itself, and the failure
/// message can name the missing screen and the line to add.
void main() {
  group('the registry describes lib/', () {
    test('every screen in lib is audited or explicitly deferred', () {
      final screens = discoverScreenClasses(Directory('lib'));

      // Guards the finder, not the registry. A glob that silently matched
      // nothing would make every assertion below pass forever — the exact
      // failure this project has shipped three times.
      expect(
        screens,
        isNotEmpty,
        reason:
            'no *_screen.dart found under lib/ — the finder is broken, '
            'not the registry',
      );

      final failures = screenCoverageFailures(
        screensInLib: screens,
        auditedNames: auditedScreens.map((entry) => entry.name).toList(),
        pending: pendingAudits,
      );

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('every screen file sits in a folder screens are allowed in', () {
      // The location half of the same question, kept beside the coverage half
      // because both come from one walk of lib/ and both fail for one reason:
      // somebody added a screen without deciding where it belongs.
      final misplaced = misplacedScreenFiles(Directory('lib'));

      expect(
        misplaced,
        isEmpty,
        reason:
            'a *_screen.dart may live only under '
            '${screenFolders.join(' or ')} — found ${misplaced.join(', ')}',
      );
    });

    test('the finder resolves a file name to its class name', () {
      final screens = discoverScreenClasses(Directory('lib'));

      expect(screens, contains('RouteNotFoundScreen'));
      expect(screens, contains('ReviewPlaceholderScreen'));
    });
  });

  group('the rules themselves', () {
    // Exercised on data that is not on disk, because a gate provable only by
    // the situation the repo happens to be in today cannot be trusted on the
    // day it first says no.
    const deferred = PendingAudit(
      _SampleScreen,
      rationale: 'Needs a database before it can be pumped.',
      wbsTask: 'M4.2',
    );

    test('an unregistered screen fails, and the message says what to add', () {
      final failures = screenCoverageFailures(
        screensInLib: <String>['NewThingScreen'],
        auditedNames: const <String>[],
        pending: const <PendingAudit>[],
      );

      expect(failures, hasLength(1));
      expect(failures.single, contains('NewThingScreen'));
      expect(failures.single, contains('auditedScreens'));
    });

    test('a registered screen passes', () {
      expect(
        screenCoverageFailures(
          screensInLib: <String>['NewThingScreen'],
          auditedNames: const <String>['NewThingScreen'],
          pending: const <PendingAudit>[],
        ),
        isEmpty,
      );
    });

    test('a deferred screen passes while it still exists', () {
      expect(
        screenCoverageFailures(
          screensInLib: <String>[deferred.name],
          auditedNames: const <String>[],
          pending: const <PendingAudit>[deferred],
        ),
        isEmpty,
      );
    });

    test('a deferral for a screen that no longer exists is stale', () {
      // Same rule as an unused allowance. A permission left behind after the
      // thing it excused is gone reads as coverage to whoever comes next.
      final failures = screenCoverageFailures(
        screensInLib: const <String>[],
        auditedNames: const <String>[],
        pending: const <PendingAudit>[deferred],
      );

      expect(failures, hasLength(1));
      expect(failures.single, contains('no longer exists'));
    });

    test('audited and deferred at once is a contradiction', () {
      final failures = screenCoverageFailures(
        screensInLib: <String>[deferred.name],
        auditedNames: <String>[deferred.name],
        pending: const <PendingAudit>[deferred],
      );

      expect(failures, hasLength(1));
      expect(failures.single, contains('both audited and deferred'));
    });

    test('a deferral must carry a reason and an owner', () {
      expect(deferred.rationale, isNotEmpty);
      expect(deferred.wbsTask, isNotEmpty);
    });
  });
}

/// Stands in for a real screen in the rule tests. Never rendered.
class _SampleScreen {
  const _SampleScreen();
}
