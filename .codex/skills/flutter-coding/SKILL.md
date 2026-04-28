---
name: flutter-coding
description: Apply when writing or editing Flutter widgets in Dart (.dart) files. Behavioral corrections for widget composition, BuildContext, state management, performance, lifecycle, and common antipatterns. Pairs with dart-coding for language rules. Project conventions always override these defaults.
---

# Flutter Coding

Match the project's existing conventions. When uncertain, read 2-3 existing widgets to infer the local style. Check `pubspec.yaml` for Flutter/Dart version and dependencies, and the project's state-management package (Provider, Riverpod, Bloc, GetIt) before introducing a new pattern. These defaults apply only when the project has no established convention. For Dart language rules (null safety, async, records, patterns), see the `dart-coding` skill.

## Never rules

These are unconditional. They prevent rebuild storms, corrupted state, and lifecycle bugs regardless of project style.

- **Never use a helper function that returns `Widget`** -- helper functions skip the `const` constructor cache and rebuild on every parent build. Promote to a `StatelessWidget` so Flutter can short-circuit identical instances via `==`.

```dart
// Wrong: rebuilds every time the enclosing build runs
Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Text(title, style: const TextStyle(fontSize: 24)),
  );
}

// Correct: a const StatelessWidget caches via instance equality
class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: const TextStyle(fontSize: 24)),
    );
  }
}
```

- **Never pass mutable arguments where `const` constructors would work** -- `const Text('hi')` short-circuits rebuilds via instance equality. Prefer `const` literals everywhere they apply.

```dart
// Wrong: a fresh Text every rebuild, even though args never change
Text('Save', style: TextStyle(fontWeight: FontWeight.bold))

// Correct: const literal is cached
const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))
```

- **Never extend `Scaffold`, `Container`, or other concrete widgets** -- compose. Pass child widgets in via constructor, route events up via callbacks, and pass state down through fields. Inheritance from concrete widgets fights the framework.

- **Never override `Widget.operator ==`** (except for trivially-cheap leaf widgets) -- the framework already short-circuits identical `const` instances. Custom `==` runs O(N^2) over the tree and blocks compiler optimizations.

- **Never create a `Future` or `Stream` inside `build`** -- `FutureBuilder(future: fetch())` reruns on every parent rebuild, causing infinite loops and wasted requests. Cache the future on `State` (in `initState` or `didChangeDependencies`).

```dart
// Wrong: a new Future on every rebuild -> reload storm
class UserView extends StatelessWidget {
  const UserView({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: fetchUser(id), // recreated each build
      builder: (context, snap) => /* ... */,
    );
  }
}

// Correct: cache the future on State
class UserView extends StatefulWidget {
  const UserView({super.key, required this.id});
  final String id;

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  late Future<User> _user = fetchUser(widget.id);

  @override
  void didUpdateWidget(UserView old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) _user = fetchUser(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _user,
      builder: (context, snap) => /* ... */,
    );
  }
}
```

- **Never use `BuildContext` after an `await` without checking `mounted`** -- once the widget unmounts, the context is invalid. Applies to `Navigator`, `Theme.of`, `ScaffoldMessenger.of`, `setState`, and anything else that touches the tree.

```dart
// Wrong: context may be unmounted by the time we use it
Future<void> _save() async {
  await api.save();
  Navigator.of(context).pop(); // crashes if disposed
}

// Correct: gate context use after every await
Future<void> _save() async {
  await api.save();
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```

- **Never store a `BuildContext` in a field, captured closure, or async callback** -- the captured reference outlives the build it was issued in. Re-derive context at the call site or pass a typed callback up.

- **Never put I/O, allocations of long-lived objects, or controller construction in `build`** -- `build` must be pure and may run many times per frame. Move work to `initState`, `didChangeDependencies`, an event handler, or a higher-level state object.

```dart
// Wrong: a new controller each build leaks the old one
@override
Widget build(BuildContext context) {
  final controller = TextEditingController(); // leak on every rebuild
  return TextField(controller: controller);
}

// Correct: own the controller on State and dispose it
class _FormState extends State<Form> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: _controller);
}
```

- **Never use `Opacity`, `Transform`, or `Clip*` in animations or hot paths** -- they force expensive saveLayer calls. Use the cheap variants: `AnimatedOpacity`/`FadeTransition`, `FadeInImage`, the `opacity` parameter on `Image`, `borderRadius` on `BoxDecoration` instead of `ClipRRect`.

```dart
// Wrong: Opacity forces a saveLayer every frame of the animation
AnimatedBuilder(
  animation: anim,
  builder: (_, __) => Opacity(opacity: anim.value, child: const _Card()),
)

// Correct: FadeTransition uses the GPU-friendly path
FadeTransition(opacity: anim, child: const _Card())
```

- **Never `setState` inside `initState`, `build`, or `dispose`** -- builds must be pure and `dispose` runs after the element is unmounted. Defer with `WidgetsBinding.instance.addPostFrameCallback` only when absolutely needed; gate post-async `setState` with `if (mounted)`.

- **Never create a `GlobalKey` inside `build`** -- a fresh key each build causes the framework to reparent state, triggering `State.deactivate` and InheritedWidget rebuilds. Store keys as `final` fields on `State`.

- **Never reorder, insert, or delete stateful list children without keys** -- without a `Key`, internal `State` and `Element` attach to position, so removing the first item swaps state across surviving items. Use `ValueKey(item.id)` or `ObjectKey(item)`.

```dart
// Wrong: removing index 0 corrupts the surviving items' state
ListView(
  children: [for (final t in todos) TodoTile(todo: t)],
)

// Correct: identity-bound key keeps state attached to the right item
ListView(
  children: [for (final t in todos) TodoTile(key: ValueKey(t.id), todo: t)],
)
```

- **Never use `Navigator.pushNamed` or string-based routes for non-trivial apps** -- named routes are discouraged officially and lose type safety. Use `go_router` or an equivalent declarative router. Plain `Navigator.push(MaterialPageRoute(...))` is fine for tiny apps.

- **Never use deprecated `WillPopScope`** -- it was replaced by `PopScope<T>` in Flutter 3.24+. The new API is async-safe and predicate-based.

- **Never mutate `Widget` fields after construction** -- widgets are immutable build configs. Mutate `State`, not `Widget`. If you need to react to incoming widget changes, use `didUpdateWidget`.

## Keys

Reach for a key when widget identity must survive position changes -- typically children of a list, grid, or animated collection that hold their own `State`.

- `ValueKey(item.id)` is the default for items with stable IDs.
- `ObjectKey(item)` when you have the object reference but no natural ID.
- `PageStorageKey` to persist scroll offsets across rebuilds.
- `GlobalKey` only for cross-tree `State` access or explicit reparenting -- it triggers `State.deactivate` and InheritedWidget rebuilds when moved, so it is the most expensive option.

```dart
// Cross-tree access: open a Drawer from outside the Scaffold
class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(key: _scaffoldKey, drawer: const _Menu(), body: /* ... */);
  }
}
```

## BuildContext

`BuildContext` is the element's locator into the tree. Two rules cover almost everything:

- The `context` passed to `build` belongs to the parent. `Theme.of(context)` finds ancestors, not the widgets you return below. Wrap descendants in a `Builder` when you need their context (for example to open a `Drawer` or read an `InheritedWidget` you just installed).

```dart
// Wrong: Scaffold.of(context) here looks above the Scaffold we return below
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ElevatedButton(
      onPressed: () => Scaffold.of(context).openDrawer(), // crashes
      child: const Text('Menu'),
    ),
  );
}

// Correct: Builder gives a context beneath the Scaffold
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(
      builder: (innerContext) => ElevatedButton(
        onPressed: () => Scaffold.of(innerContext).openDrawer(),
        child: const Text('Menu'),
      ),
    ),
  );
}
```

- Pick the right lookup. `Theme.of(context)` throws when no ancestor exists; use `Theme.maybeOf(context)` when an ancestor may legitimately be absent. `dependOnInheritedWidgetOfExactType` (what `.of` uses) registers a dependency so the widget rebuilds when the inherited value changes. `findAncestorStateOfType` is one-shot and abuse-prone -- it gives no rebuild reactivity and couples to tree shape.

## State management

Built-ins (neutral, listed by scope):

- `setState` -- ephemeral state owned by one widget.
- `ValueNotifier<T>` + `ValueListenableBuilder<T>` -- single-field state with granular rebuilds.
- `ChangeNotifier` + `InheritedNotifier` -- multi-field state shared in a subtree.
- `InheritedWidget` / `InheritedModel` -- foundation primitives; rebuilds dependents on change.

Packages (neutral, no recommendation): Provider, Riverpod, Bloc, GetIt. Pick by team and scale; do not mix patterns within a feature. Read existing code first.

Guidelines:

- **Localize state.** Keep it on the smallest widget that needs it. `setState` rebuilds the entire subtree, so lifting state higher than necessary widens the rebuild blast radius.
- **Don't prop-drill 3+ levels.** Reach for an `InheritedWidget`, Provider, or your project's chosen container.
- **Use granular rebuild surfaces.** `Selector`, Riverpod's `select`, and `ValueListenableBuilder` rebuild only when the watched slice changes.

```dart
// Granular: only the counter text rebuilds
class Counter extends StatefulWidget {
  const Counter({super.key});
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  final _count = ValueNotifier<int>(0);

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _count,
          builder: (_, value, __) => Text('$value'),
        ),
        ElevatedButton(
          onPressed: () => _count.value++,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
```

## Performance

- **Lazy lists for non-trivial counts.** `ListView.builder` and `GridView.builder` only build visible items. Provide `itemExtent` or `prototypeItem` when sizes are uniform -- the framework can then skip the layout pass.
- **`AnimatedBuilder` with a static `child`.** The `builder` runs every tick; the `child` does not.

```dart
AnimatedBuilder(
  animation: _controller,
  // Built once and reused across every tick
  child: const _ExpensiveSubtree(),
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * pi,
    child: child,
  ),
)
```

- **`RepaintBoundary` around expensive subtrees that repaint independently** (charts, maps, animated cards inside otherwise static screens). Don't sprinkle them everywhere -- each one allocates a layer.
- **Avoid intrinsic passes in lists.** `IntrinsicHeight`, `IntrinsicWidth`, and unbounded children inside `Row`/`Column` force the framework to lay each child out twice. Prefer fixed-size cells or `Flexible`/`Expanded` with concrete constraints.
- **Prefer `const` widgets.** A `const` constructor is cached by instance equality; the framework can skip its rebuild entirely.

## Lifecycle

`StatefulWidget` lifecycle hooks each have one job. Get them mixed up and you'll fight the framework.

- **`initState`** -- create controllers, futures, subscriptions. Sync only. Cannot call `dependOnInheritedWidgetOfExactType` (use `didChangeDependencies` for that).
- **`didChangeDependencies`** -- read `InheritedWidget`s that should rebuild this widget when they change (`Theme`, `MediaQuery`, `Localizations`). Runs after `initState` and any time a watched ancestor changes.
- **`didUpdateWidget(oldWidget)`** -- react to `widget.x` changing. Re-subscribe streams, restart animations. Don't `setState` here -- a rebuild is already scheduled.
- **`build`** -- pure. No I/O, no `setState`, no `Future` allocation, no controller construction.
- **`dispose`** -- dispose every owned resource: `AnimationController`, `TextEditingController`, `ScrollController`, `FocusNode`, `StreamSubscription`, `Timer`. Call `super.dispose()` last.

```dart
class _PlayerState extends State<Player> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late StreamSubscription<Track> _sub;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _sub = widget.player.tracks.listen(_onTrack);
  }

  @override
  void didUpdateWidget(Player old) {
    super.didUpdateWidget(old);
    if (old.player != widget.player) {
      _sub.cancel();
      _sub = widget.player.tracks.listen(_onTrack);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _anim.dispose();
    super.dispose();
  }

  // ...
}
```

## Async in widgets

The single most common Flutter bug: creating async work inside `build`.

- **Cache `Future` and `Stream` on `State`.** Recreate them in `didUpdateWidget` when their inputs change; never inline them in `build`.
- **Handle every `AsyncSnapshot` state.** Check `connectionState`, `hasError`, and `hasData`. Even an already-completed `Future` emits one `waiting` frame before its value.

```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<User>(
    future: _user, // cached on State
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const _Skeleton();
      }
      if (snap.hasError) return _ErrorView(error: snap.error!);
      final user = snap.requireData;
      return _UserCard(user: user);
    },
  );
}
```

`StreamBuilder` follows the same rule -- store the stream on `State` and cancel any owned subscriptions in `dispose`.

## Navigation

- Use a declarative router (`go_router` or equivalent) for non-trivial apps. Plain `Navigator.push(MaterialPageRoute(...))` is fine for prototypes and tiny apps.
- **Typed results.** `Navigator.pop<T>(context, value)` and `await Navigator.push<T>(...)` round-trip a typed value.
- **`PopScope<T>`** (Flutter 3.24+) replaces `WillPopScope`. Use it to intercept back gestures; access the popped result via the `onPopInvokedWithResult` callback.
- Page-backed routes deep-link cleanly; pageless routes (`showDialog`, `Navigator.push` outside the router) do not. Removing a page-backed route also drops the pageless routes attached to it.
- After `await showDialog(...)` (or any awaited navigation call), gate context with `if (!context.mounted) return;`.

```dart
final result = await context.push<bool>('/confirm');
if (!context.mounted) return;
if (result ?? false) ScaffoldMessenger.of(context).showSnackBar(/* ... */);
```

## Common antipatterns

- **Logic or side effects in `build`.** No API calls, no `setState`, no `Future` allocation, no controller construction.
- **Mutating widget fields after construction.** Widgets are immutable. Mutate `State`, not `Widget`.
- **`findAncestorStateOfType` to call methods on a parent.** Couples to tree shape, no reactivity. Pass a callback down or expose state through `InheritedWidget`/`InheritedNotifier`.
- **Missing keys when reordering stateful list children.** State follows position, not identity, without a key.
- **Recreating controllers or futures per build.** Always own them on `State` and dispose them.

## Recent API drift

A few rename/replacement pairs you'll hit on modern Flutter (3.24+):

- `Color.withOpacity(x)` -> `Color.withValues(alpha: x)`
- `MediaQuery.textScaleFactor` -> `TextScaler` (`MediaQuery.textScalerOf(context)`)
- `MaterialState` / `MaterialStateProperty` -> `WidgetState` / `WidgetStateProperty`
- `RouteInformation.location` -> `RouteInformation.uri`
- `useMaterial3` defaults to `true`; pass `false` only to opt out.
- `AppLifecycleState.hidden` exists alongside `inactive`/`paused`/`resumed`/`detached`.
- `WillPopScope` -> `PopScope<T>` with `onPopInvokedWithResult`.
