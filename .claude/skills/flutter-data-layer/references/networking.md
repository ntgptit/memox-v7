# Networking with Dio

Location: `core/network/`.

## One client, configured once

```dart
Dio buildDio(EnvConfig env) {
  final dio = Dio(BaseOptions(
    baseUrl: env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 400,
  ));

  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AuthInterceptor(tokenStore, dio),
    if (env.logLevel == LogLevel.debug) LoggingInterceptor(),
  ]);
  return dio;
}
```

All three timeouts matter and they fail differently: `connectTimeout` covers
reaching the server, `receiveTimeout` covers a server that accepts and then
stalls, `sendTimeout` covers a stalled upload. Without a receive timeout a
request can hang until the OS gives up — minutes of a spinner.

Expose it as a single `keepAlive` provider. Multiple Dio instances mean multiple
interceptor chains, and a token refreshed on one is not applied to the others.

## Interceptors

**Request ID** — attach a UUID per request and log it. When a user reports a
failure, this is what correlates their report with the server's logs.

**Auth** — attach the bearer token; on 401, refresh once and retry.

The trap is concurrent 401s: five parallel requests fail, five refreshes fire,
four are rejected as reusing a consumed refresh token, and the user is logged
out. Serialise it — hold a single in-flight refresh `Future` and have every
waiter await the same one:

```dart
Future<String>? _refreshInFlight;

Future<String> _refreshToken() {
  final existing = _refreshInFlight;
  if (existing != null) return existing;          // join the in-flight refresh

  final future = _performRefresh().whenComplete(() => _refreshInFlight = null);
  _refreshInFlight = future;
  return future;
}
```

If the refresh itself fails, clear the session and let the router's guard move
the user to login. Do not retry a failed refresh — the token is gone.

**Logging** — development only, and redact by key:

```dart
const _redactedKeys = {'authorization', 'password', 'token', 'refresh_token'};
```

Redact in the interceptor rather than at call sites: one place to get right, and
it cannot be forgotten by a new endpoint. Never log a full response body in
production — it will contain user data.

**Error mapping** — do not map inside the interceptor. Let `DioException`
propagate to the repository, which owns the decision of whether a failure means
"show an error" or "fall back to cache". An interceptor cannot know that.

## Mapping to Failure

`core/error/dio_error_mapper.dart`:

```dart
Failure mapDioException(DioException e) {
  final type = e.type;
  if (type == DioExceptionType.connectionError ||
      type == DioExceptionType.connectionTimeout) {
    return const NetworkFailure(message: 'No internet connection');
  }
  if (type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout) {
    return const NetworkFailure(message: 'The server took too long to respond');
  }
  if (type == DioExceptionType.cancel) {
    return const CancelledFailure(message: 'Request cancelled');
  }

  final status = e.response?.statusCode;
  if (status == null) return UnknownFailure(message: 'Something went wrong', cause: e);

  return switch (status) {
    400 => ValidationFailure(
        message: _serverMessage(e) ?? 'Invalid request',
        fieldErrors: _fieldErrors(e),
      ),
    401 => const UnauthorizedFailure(message: 'Please sign in again'),
    403 => const ForbiddenFailure(message: 'You do not have access to this'),
    404 => const NotFoundFailure(message: 'Not found'),
    409 => const ConflictFailure(message: 'This was changed elsewhere'),
    422 => ValidationFailure(
        message: _serverMessage(e) ?? 'Please check your input',
        fieldErrors: _fieldErrors(e),
      ),
    >= 500 => const NetworkFailure(message: 'The server is having problems'),
    _ => UnknownFailure(message: 'Something went wrong', cause: e),
  };
}
```

Server messages are shown only where the API contract guarantees they are
user-safe — otherwise you forward internal detail to the user. If it is not
guaranteed, use the generic message and log the server's text.

Test this function directly, per status code and exception type. It is the code
most likely to be wrong and least likely to be exercised by hand.

## API contract

Document in `docs/api-spec.md`: endpoints, request and response shapes, the
error envelope, pagination style, and auth behaviour.

**Pagination** — normalise whatever the server does into one internal shape:

```dart
final class Page<T> {
  const Page({required this.items, required this.nextCursor, required this.hasMore});
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
```

Cursor pagination is more robust than offset for lists that change while being
paged — offset skips or duplicates rows when items are inserted mid-scroll.

**Backward compatibility** — treat every field the server might not send as
nullable in the DTO and resolve it in the mapper. An unknown enum value maps to
an `unknown` variant rather than throwing; otherwise the server adding a status
crashes the app for every user who has not updated.

## Resilience

- **Offline** — surface it as an explicit state, not a generic error. If the app
  is offline-first, show cached data with an offline indicator instead of an
  error screen. `connectivity_plus` reports link state, not reachability — a
  captive portal reads as connected, so treat it as a hint, not proof.
- **Retry** — bounded, exponential backoff with jitter, GETs only. Jitter
  matters when many clients retry after an outage; without it they synchronise
  and re-flood the server.
- **Never blindly retry a mutation.** Use an idempotency key the server honours,
  or do not retry.
- **Duplicate submissions** — guard in the controller (see
  `flutter-state-riverpod`), not only in the UI.
- **Cancellation** — `CancelToken` tied to the provider's `onDispose`.
