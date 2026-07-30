import 'dart:developer' as developer;

import 'package:drift/drift.dart';

/// Where interceptor output goes. Injected so a test can read what was written.
typedef QueryLogSink = void Function(String message);

/// Prefix on every line, so query output can be filtered apart from the provider
/// and startup logging.
const String _logName = 'memox.sql';

/// A statement slower than this is marked in the log.
///
/// Two thirds of a 60fps frame. Not a limit and not an assertion — a single
/// local `SELECT` has no business taking this long, so the marker is there to be
/// noticed while scrolling past a hundred fast lines.
const Duration kSlowStatementThreshold = Duration(milliseconds: 10);

/// Logs every statement and how long it took. Debug builds only.
///
/// **Why not `driftRuntimeOptions.debugPrint = true`.** That is the obvious
/// answer and it is the wrong one here: drift's own logging prints the bound
/// variables next to the statement, so the first `INSERT INTO cards` would put
/// the front and back of a flashcard into the log. AD-08 forbids logging card
/// content *at any level* and permits IDs — a rule written down precisely
/// because reaching for content while debugging is the natural reflex. So the
/// flag stays off and this interceptor takes its place.
///
/// **What is logged:** the statement text, the elapsed time, and a row count.
/// **What is never logged:** the arguments, the returned rows, and the database
/// path. `args` is not read anywhere in this file — the omission is structural
/// rather than a rule someone has to remember, and
/// `test/core/database/query_log_interceptor_test.dart` proves it with card
/// content that would be unmistakable in the output.
///
/// The statement text is safe because every query in `lib/` comes from a
/// `.drift` file and reaches SQLite with `?` placeholders (AD-02). A
/// hand-written `customStatement` that interpolated a value into the SQL would
/// defeat that — which is one more reason business SQL does not live in Dart.
///
/// **What it cannot see.** Drift runs `onCreate` and `beforeOpen` through its own
/// opening executor, which wraps the delegate *underneath* an interceptor. So
/// `CREATE TABLE` and `PRAGMA foreign_keys = ON` never appear here, however long
/// you stare at the log. `test/database/migration_test.dart` covers both by
/// reading the schema and the pragma back out of SQLite.
final class QueryLogInterceptor extends QueryInterceptor {
  QueryLogInterceptor({QueryLogSink? sink}) : _sink = sink ?? _developerLog;

  final QueryLogSink _sink;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    statement,
    () => executor.runSelect(statement, args),
    (rows) => '${rows.length} rows',
  );

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    statement,
    () => executor.runInsert(statement, args),
    (rowId) => 'rowid $rowId',
  );

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    statement,
    () => executor.runUpdate(statement, args),
    (count) => '$count updated',
  );

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    statement,
    () => executor.runDelete(statement, args),
    (count) => '$count deleted',
  );

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) =>
      _timed(statement, () => executor.runCustom(statement, args), (_) => 'ok');

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _timed(
    // The statements, not the arguments — a batch is where the argument list is
    // longest and most likely to be full of card content.
    statements.statements.join('; '),
    () => executor.runBatched(statements),
    (_) => 'batch of ${statements.statements.length}',
  );

  /// Runs [body], then logs the statement with its duration and outcome.
  ///
  /// The log line is written after the statement completes rather than before it
  /// starts, because the duration is the point. A failure is not logged here at
  /// all: it propagates to the repository, which maps it to a `Failure`, and
  /// logging it twice would make one problem look like two.
  Future<T> _timed<T>(
    String statement,
    Future<T> Function() body,
    String Function(T result) describe,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await body();
    stopwatch.stop();

    final marker = stopwatch.elapsed >= kSlowStatementThreshold ? ' SLOW' : '';
    _sink(
      '${stopwatch.elapsedMicroseconds}us$marker  ${_collapse(statement)}  '
      '(${describe(result)})',
    );

    return result;
  }

  /// Puts a multi-line `.drift` statement on one line so the log stays greppable.
  String _collapse(String statement) =>
      statement.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The default sink. See the note in `core/state/provider_observer.dart` on why
/// this is a local function and not a shared logging abstraction.
void _developerLog(String message) =>
    developer.log(message, name: _logName, level: 500 /* FINE */);
