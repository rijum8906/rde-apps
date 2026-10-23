# Flutter Linux workspace

A Linux-only Flutter monorepo with one Material 3 **Expressive** design system,
shared routing/localization/services, a component gallery host, and an
expression-based calculator. The workspace targets Linux desktop exclusively.

## Tooling decision: native Pub workspaces

This workspace is verified on **Flutter 3.47.7 / Dart 3.13.5** (Linux, stable
channel), newer than the native-workspace thresholds (Dart ≥ 3.5, Flutter ≥
3.24). It therefore uses **native Pub workspaces**:

- the root `pubspec.yaml` declares the `workspace:` members and owns the single
  root `pubspec.lock`;
- every member declares `resolution: workspace` and resolves against the same
  dependency graph;
- **no `melos.yaml`** is used: there is no second tool to install, `dart pub
  get` at the root is the only bootstrap step, and `flutter analyze` /
  `flutter test` run from the root or per member without wrapper scripts.

## Layout

```
.
├── pubspec.yaml                  # workspace root (no app code)
├── analysis_options.yaml         # shared flutter_lints + very_good_analysis
├── .github/workflows/ci.yaml     # format, analyze, test, Linux build
├── packages/
│   ├── core/                     # pure Dart: Result, Logger, math engine, extensions
│   ├── design_system/            # M3 Expressive theme, widgets, motion, gallery
│   ├── app_routing/              # typed go_router wrapper + page transitions
│   ├── app_localization/         # en/de ARB resources and delegates
│   └── app_shared/               # DI, storage, notifications, platform helpers
└── apps/
    ├── desktop_app/              # flutter create --platforms=linux
    └── calculator/               # flutter create --platforms=linux
```

## Packages

| Package | Responsibility |
| --- | --- |
| `core` | No Flutter dependency. Sealed `Result<T, E>`, `Logger`, JSON/async typedefs, string/iterable/date extensions, and a dependency-free tokenizer, parser, and evaluator for arithmetic expressions. |
| `design_system` | `AppTheme`, seven dynamic color variants, M3 type scale + emphasis, shape scale, centralized motion tokens, themed widgets, accessible motion widgets, and the shared `DesignSystemGallery`. |
| `app_routing` | Typed `AppRoute`/`AppPage` table, `AppRouter` that registers `AppPageTransitions` with `CustomTransitionPage`, an optional tabbed shell (`StatefulShellRoute`) with `AppShellNavigation`, typed `goTo`/`pushRoute` helpers, and a built-in not-found page. |
| `app_localization` | English template + German placeholder ARB files, generated `AppLocalizations` with Flutter/Material delegates. |
| `app_shared` | Zero-dependency `ServiceLocator`, `KeyValueStore`/`SecureStore` wrappers (shared_preferences and libsecret), `NotificationService` abstraction (D-Bus), platform and debug helpers. |

Apps only contain platform scaffolding, bootstrapping, and app-level state.
The gallery demo lives in `design_system`; the calculator's math lives in
`core`.

## Apps

### Gallery host (`apps/desktop_app`)

Renders the shared `DesignSystemGallery`, which exercises every widget and
motion primitive: theme toggle, buttons, cards, text field, list tiles, dialog,
empty/loading states, staggered list, fade-slide entrance, pressable, and page
transitions on the detail page.

### Calculator (`apps/calculator`)

An expression calculator (`2 + 3 * (4 - 1) / 2`) backed by `core`'s parser:

- `core`'s `MathEvaluator` supports `+ - * / % ^`, parentheses, unary minus,
  decimals, the constants `pi` and `e`, and the functions `sin`, `cos`, `tan`,
  `asin`, `acos`, `atan`, `ln`, `log`, and `sqrt`. Exponentiation is
  right-associative, and division by zero (or any non-finite result) returns
  `Result.err(MathError)`.
- Three pages share one responsive shell: **Calculator**, **History**, and
  **Settings**. Wide windows get a `NavigationRail` (extended above 1180 px),
  narrow ones a `NavigationBar`; each branch keeps its scroll position, and the
  calculator bloc lives above `MaterialApp` so state survives tab changes.
- The history page lists every persisted calculation, restores one with a tap,
  and clears the list behind a confirmation dialog.
- The settings page owns the persisted preferences: theme mode (system, light,
  dark), Material 3 color style, and the trigonometric unit. The **About** page
  is pushed above the shell and lists the keyboard shortcuts and licenses.
- All keys are buttons wrapped in `AnimatedPressable`; the keypad fills the
  available height, uses `Semantics` labels, and takes its theme entirely from
  `design_system`. `=` is a filled primary button, `⌫` deletes one character,
  `C` clears.
- Keyboard: main-row and numpad digits and operators, `Enter`/`=` evaluate,
  `Backspace` deletes, `Escape` clears; focus returns to the keypad when the
  shell switches back to the calculator.
- History and preferences share `app_shared`'s `KeyValueStore`
  (`shared_preferences` on Linux); history keeps the last 20 expressions +
  results, preferences survive a restart, and corrupt payloads fall back to
  defaults instead of blocking startup.
- Invalid input shows an inline error under the display; the next keypress
  clears it.

## Material 3 Expressive

**Color.** `AppColorSchemes` wraps `ColorScheme.fromSeed` with the expressive
`DynamicSchemeVariant`s (`expressive`, `vibrant`, `content`, `fidelity`,
`monochrome`, `neutral`, `tonalSpot`). `AppTheme.light()` / `AppTheme.dark()`
accept a `dynamicScheme` and a `highContrast` flag. `AppDynamicColors.load()`
reads the GTK accent color on Linux and uses it as the seed; the static brand
seed is the fallback everywhere.

**Typography.** `AppTypography.scaleFor` builds the complete 2021 M3 scale
(display/headline/title/body/label, all sizes) for the active brightness.
`AppTextTheme` (a `ThemeExtension`) adds `emphasisLarge`, `emphasisMedium`, and
`emphasisSmall`; widgets read them via `context.text.emphasisLarge` and the base
scale via `context.text.scale`.

**Shapes.** `AppShapes` is a `ThemeExtension` with `extraSmall` (8) through
`extraLarge` (32), plus pill/card/dialog/input helpers. The expressive radii are
applied to cards, dialogs, inputs, buttons, list tiles, snack bars, sheets, and
tooltips in `AppTheme`.

**Motion.** `AppDurations`, `AppCurves`, and `AppSprings` define the canonical
durations (`short`/`medium`/`long`/`extraLong` + stagger), curves
(`emphasized`, `emphasizedDecelerate`, `emphasizedAccelerate`, `standard`), and
springs. They are exposed through the `AppMotionTokens` extension. Every motion
widget reads from `context.motion`; there are no ad-hoc `Duration` or `Curve`
values in widgets or apps.

- `AnimatedPressable` scales down on tap-down and springs back with a
  `SpringSimulation`; one controller, disposed with the state.
- `FadeSlideIn` fades and offsets on either axis, with optional delay.
- `StaggeredList` drives all children from one ticker with per-index intervals.
- `AnimatedThemeSwitcher` wraps `AnimatedTheme` with the token duration/curve.
  The gallery uses it to preview the other brightness; the calculator animates
  theme changes through `MaterialApp`'s token-duration theme animation.
- `AppPageTransitions` provides shared-axis X/Y and fade-through transitions
  and is registered with `go_router` in `app_routing`.

**Elevation and surfaces.** Tonal cards use `surfaceContainerLow` and the
scheme's `surfaceTintColor`; the app bar uses `scrolledUnderElevation`; no
widget hardcodes a shadow.

**Accessibility.** `AppMotionTokens.resolve(context)` collapses every duration
to `Duration.zero` when `MediaQuery.disableAnimations` is set, and the motion
widgets short-circuit to a static state. `AppTheme` reads
`MediaQuery.highContrast` and generates a `contrastLevel: 1` scheme, which takes
precedence over dynamic color.

## Other decisions

- **Linux-only scope.** Both apps were created with `--platforms=linux` and
  no other platform folders exist in the tree. Plugins without Linux
  implementations are not used; `flutter_local_notifications`, `flutter_secure_storage`,
  `shared_preferences`, and `dynamic_color` all have Linux implementations
  (D-Bus notifications, libsecret keyring, GSettings/file storage, and the GTK
  accent color).
- **Math in `core`.** The tokenizer, recursive-descent parser, and evaluator
  live in `packages/core/lib/src/math/` and are dependency-free — no `eval`
  and no expression package. The calculator app only wires UI and state.
- **Dart 3.13 primary constructors.** `very_good_analysis` 11 enables
  `unnecessary_type_name_in_constructor`, so hand-written classes use the new
  `const new({...})` syntax. Redirecting factories keep their class name (the
  language requires it); the two unavoidable analyzer false positives are
  documented inline in `core`.
- **Generated localization sources are committed.** CI needs no generation
  step, while `flutter gen-l10n` in `packages/app_localization` regenerates
  them after ARB edits.
- **Simple service locator over Riverpod.** The apps need composition at
  startup, not reactive state, so `app_shared` ships a dependency-free locator.
- **Shared gallery.** `DesignSystemGallery` and `GalleryDetailPage` are part of
  `design_system` (not an app) because they are reusable preview surfaces; the
  hosts supply theme state and navigation callbacks.

## Run the calculator

```bash
cd apps/calculator
flutter run -d linux
```

## Getting started

```bash
# 1. Bootstrap the whole workspace (one lockfile).
dart pub get

# 2. Gallery host
cd apps/desktop_app
flutter run -d linux

# 3. Calculator
cd apps/calculator
flutter run -d linux

# 4. Quality gates
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
(cd packages/core && flutter test)
(cd packages/design_system && flutter test)
(cd packages/app_routing && flutter test)
(cd packages/app_localization && flutter test)
(cd packages/app_shared && flutter test)
(cd apps/desktop_app && flutter test)
(cd apps/calculator && flutter test)

# 5. Regenerate localization after ARB changes
cd packages/app_localization && flutter gen-l10n
```

Hot reload works in both apps: theme mode/variant live in app state, and the
gallery/calculator screens are regular widget subtrees.

## CI

`.github/workflows/ci.yaml` runs on `ubuntu-latest`, installs Flutter stable,
runs `dart pub get`, checks `dart format --set-exit-if-changed`, runs
`flutter analyze` with `--fatal-infos --fatal-warnings`, runs `flutter test`
in every package and app, and builds every app with
`flutter build linux --debug` (installing the GTK/libsecret build
dependencies first).

## Verification

All gates below were run locally on Linux (Arch, Flutter 3.47.7 / Dart 3.13.5):

| Check | Result |
| --- | --- |
| `dart pub get` at root | pass |
| `flutter analyze --fatal-infos` at root | 0 issues |
| `dart format --output=none --set-exit-if-changed .` | pass |
| `flutter test` in `core`, `design_system`, `app_routing`, `app_localization`, `app_shared` | pass |
| `flutter test` in `desktop_app`, `calculator` | pass |
| `flutter build linux --debug` in `apps/desktop_app` | pass |
| `flutter build linux --debug` in `apps/calculator` | pass |

The calculator test suite covers button and keyboard input (including numpad
keys and focus restoration after tab switches), clearing, backspace, inline
errors, the scientific panel, history persistence through a fake store, the
20-entry cap, the history and about pages, settings persistence across a
restart, angle-unit evaluation, responsive layout at 360×600 and 1200×800, the
rail/bar breakpoint, and theme switching.
