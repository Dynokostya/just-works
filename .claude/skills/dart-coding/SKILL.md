---
name: dart-coding
description: Apply when writing or editing Dart (.dart) files. Behavioral corrections for null safety, async patterns, type system, error handling, and common antipatterns. Project conventions always override these defaults.
---

# Dart Coding

Match the project's existing conventions. When uncertain, read 2-3 existing files to infer the local style. Check `pubspec.yaml` for SDK constraints, `analysis_options.yaml` for lint rules, and any `.dart_tool/` config for code generation. These defaults apply only when the project has no established convention.

## Never rules

These are unconditional. They prevent bugs and crashes regardless of project style.

- **Never null-check a non-`final` field directly** — Dart's flow analysis only promotes `final`, local, or private variables. After the check, the field could still change between the test and the use. Copy to a local first.

```dart
// Wrong: _temp is mutable; not promoted to non-null
if (_temp != null) {
  print(_temp.length); // compile error or stale value
}

// Correct: local is promoted
final t = _temp;
if (t != null) {
  print(t.length);
}
```

- **Never use `!` to "guarantee" non-null without prior verification** — `!` is a runtime cast that throws `TypeError` when the value is null. It silently turns a static type error into a production crash. Use `??`, `if`-checks, or pattern matching first.
- **Never mix `late` with `?`** — `late String?` confuses two distinct states (uninitialized vs explicitly null) and defeats the purpose of `late`. Pick one: `late String` (deferred init, never null) or `String?` (may be null at any time).
- **Never index a `Map` without a null-check or `!` for known-present keys** — `map['k']` returns `V?`. Calling `.length` on the result without handling null is a compile error in null-safe code; using `!` blindly turns missing keys into runtime crashes.

```dart
// Wrong: subscript returns null on missing key
final n = map['k'].length;

// Correct: handle missing key explicitly
final v = map['k'];
final n = v?.length ?? 0;

// Correct: assert presence with rationale
final n = map['k']!.length; // key inserted at line 12, guaranteed present
```

- **Never discard a `Future`** — without `await` (or explicit `unawaited(...)`), errors silently vanish and ordering is undefined. Enable `unawaited_futures` lint. Use `unawaited(future)` only when you intentionally want fire-and-forget behavior.
- **Never `await` sequentially in a loop for independent operations** — serializes work that could run in parallel. Use `Future.wait` for fan-out.

```dart
// Wrong: serial round-trips
for (final id in ids) {
  results.add(await fetch(id));
}

// Correct: concurrent
final results = await Future.wait(ids.map(fetch));
```

- **Never declare `async` without `await`, `throw`, or a `Future` return inside** — meaningless overhead and confuses callers about whether the function is asynchronous.
- **Never leave a `StreamSubscription` uncancelled** — leaks memory and continues firing callbacks after the owner is disposed. `await sub.cancel()` in `dispose`/cleanup paths.
- **Never re-listen to a single-subscription stream** — throws `StateError`. HTTP, file, and most service streams are single-subscription. Use `.asBroadcastStream()` only when you genuinely need multiple listeners.
- **Never catch `Error` subtypes** — `StateError`, `ArgumentError`, `RangeError`, etc. signal programming bugs. Catching them hides defects. Catch `Exception` for recoverable failures; let `Error`s crash so they get fixed.

```dart
// Wrong: hides programmer bugs
try {
  doWork();
} on Error catch (_) {
  // swallowed StateError, ArgumentError, etc.
}

// Correct: catch only recoverable failures
try {
  doWork();
} on FormatException catch (e, st) {
  log.warning('bad input', e, st);
}
```

- **Never use `dynamic` to mean "any value"** — `dynamic` silently disables static type checking, so typos and incompatible operations compile fine and crash at runtime. Use `Object?` plus `is`/pattern checks.

## Records and patterns

Records (Dart 3) are immutable, structurally typed bundles. Field names are part of the type — `({int a, int b})` and `({int x, int y})` do not unify.

```dart
({String name, int age}) parseUser(Map<String, Object?> json) =>
    (name: json['name'] as String, age: json['age'] as int);

final u = parseUser(payload);
print('${u.name}: ${u.age}');
```

Use a class instead of a record when behavior, methods, or computed properties are needed. Records are data only.

Sealed types plus switch expressions give exhaustiveness — the compiler enforces every case, no `default` needed:

```dart
sealed class Shape {}
class Circle extends Shape { Circle(this.r); final double r; }
class Square extends Shape { Square(this.side); final double side; }

double area(Shape s) => switch (s) {
  Circle(:final r) => 3.14159 * r * r,
  Square(:final side) => side * side,
};
```

Irrefutable patterns crash at runtime when the value does not match — `var [a, b] = list` throws if `list.length != 2`. For fallible matches, use `if (... case ...)`:

```dart
// Crashes on length mismatch
final [a, b] = pair;

// Safe: only runs when shape matches
if (list case [final a, final b]) {
  use(a, b);
}
```

`when` guards belong inside `case`, not as a separate `if`:

```dart
// Wrong
switch (point) {
  case Point(:final x):
    if (x > 0) handle(x);
}

// Correct
switch (point) {
  case Point(:final x) when x > 0:
    handle(x);
}
```

## Async, Future, Stream

Wrap `await` in `try`/`catch` (or chain `.catchError`) at the boundary where you can act on failure. `async` propagates errors via the returned `Future` — they do not surface unless awaited.

Avoid `FutureOr<T>` as a return type — callers cannot tell whether to `await`. Pick `T` or `Future<T>`.

For broadcast vs single-subscription streams: HTTP responses, file reads, and most platform streams are single-subscription. Convert with `.asBroadcastStream()` only when multiple consumers need the same events.

Always cancel subscriptions in `dispose`/cleanup:

```dart
class _MyState extends State<MyWidget> {
  StreamSubscription<Event>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = service.events.listen(_handle);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

## Collections

Prefer literals over constructors. Literals are clearer, allow inference, and support `const`:

```dart
// Wrong
final xs = List<Point>();
final m = Map<String, int>();

// Correct
final xs = <Point>[];
final m = <String, int>{};
```

Use spread, `if`, and `for` inside literals rather than imperative `addAll`/`if`/`for` outside:

```dart
final items = [
  ...defaultItems,
  if (showExtras) extraItem,
  for (final id in ids) Item(id),
];
```

Use `isEmpty`/`isNotEmpty`, never `length == 0` or `length > 0` — clearer and cheap on lazy iterables where `length` may walk the whole collection.

Use `whereType<T>()` instead of `where((e) => e is T).cast<T>()` — same intent, one call, fewer chances to drop the type.

`final list = [...]` only prevents rebinding the variable; the items remain mutable. For true immutability use `List.unmodifiable(...)` or a `const` literal:

```dart
final mutableItems = [1, 2, 3];        // can still call .add
final frozen = List<int>.unmodifiable([1, 2, 3]);
const compileTime = [1, 2, 3];          // const list, deeply immutable
```

## Classes

Prefer `final` fields. Add a `const` constructor when all fields are `final` and immutable — enables `const` use sites:

```dart
class Point {
  const Point(this.x, this.y);
  final double x;
  final double y;
}

const origin = Point(0, 0);
```

Class modifiers express different intents — do not conflate them:

| Modifier | Meaning |
|----------|---------|
| `sealed` | Exhaustive switching; cannot be extended outside the library |
| `final` | Cannot be extended or implemented outside the library |
| `base` | Can only be extended (not implemented) |
| `interface` | Can only be implemented (not extended) |

Subclasses do not inherit named constructors — reimplement them in the subclass and forward to `super`.

Factory constructors cannot access `this`. Use them for caching, returning a subtype, validating input before construction, or returning an existing instance:

```dart
class Logger {
  static final _cache = <String, Logger>{};

  factory Logger(String name) => _cache.putIfAbsent(name, () => Logger._(name));

  Logger._(this.name);
  final String name;
}
```

Override `hashCode` whenever overriding `==`. Avoid overriding `==` on mutable classes — using a mutable instance as a `Set` element or `Map` key breaks the collection when the field changes.

## Errors

Custom failure types `implements Exception`, never `extends Error`:

```dart
class PaymentFailed implements Exception {
  PaymentFailed(this.reason);
  final String reason;
  @override
  String toString() => 'PaymentFailed: $reason';
}
```

Use `on Type catch (e, st)` for typed catches with stack traces. `rethrow` preserves the original stack — use it instead of `throw e`:

```dart
try {
  await sendPayment();
} on TimeoutException catch (e, st) {
  log.warning('payment timed out', e, st);
  rethrow;
} on PaymentFailed catch (e, st) {
  log.severe('payment failed: ${e.reason}', e, st);
  return Result.failure(e);
}
```

## Style

Naming follows the official guidelines:

| Element | Style | Example |
|---------|-------|---------|
| Types, extensions, typedefs, enums | `UpperCamelCase` | `HttpClient`, `Iterable` |
| Members, parameters, locals, constants | `lowerCamelCase` | `itemCount`, `defaultTimeout` |
| Libraries, files, directories, prefixes | `lowercase_with_underscores` | `user_profile.dart` |

Acronyms: capitalize only the first letter for 3+ letters (`Http`, `Uri`, `Id`); two-letter acronyms stay fully capitalized (`IO`, `IP`, `OS`).

Use cascade `..` for sequential operations on the same target:

```dart
// Wrong
final btn = Button();
btn.text = 'Save';
btn.onTap = save;
btn.enabled = true;

// Correct
final btn = Button()
  ..text = 'Save'
  ..onTap = save
  ..enabled = true;
```

Trailing commas drive multi-line `dart format` output — add them in argument lists, parameter lists, and collection literals when you want each item on its own line.

Naming signals aliasing: `to___()` returns a snapshot (independent copy), `as___()` returns a view that reflects future changes. Pick the prefix that matches what the method actually returns.

## Common antipatterns

- **Untyped generics fill with `dynamic`** — `List<num>` not bare `List`. A bare `List` is `List<dynamic>` and discards type checking on every element access.
- **Prefer `is` checks and patterns over `as` casts** — `as` throws at runtime on type mismatch; `is` and patterns are statically verified.

```dart
// Wrong: throws if x is not a String
final s = (x as String).toUpperCase();

// Correct: pattern; only runs when x is a String
if (x case final String s) {
  use(s.toUpperCase());
}
```

- **Don't initialize nullable variables to `null` explicitly** — the default for a nullable type is already `null`.

```dart
// Wrong
Item? x = null;

// Correct
Item? x;
```

- **Avoid positional `bool` parameters** — call sites read as `spawn(fn, args, false)` with no clue what `false` means. Use named parameters:

```dart
// Wrong
Isolate.spawn(work, args, false);

// Correct
Isolate.spawn(work, args, paused: false);
```

- **A setter without a matching getter is broken** — `+=`, `??=`, and similar compound operators read before they write, so they fail. Either pair the setter with a getter or expose a regular method.
