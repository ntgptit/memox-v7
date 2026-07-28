# Design tokens

Location: `core/theme/`.

```
core/theme/
├── app_theme.dart          # buildLightTheme() / buildDarkTheme()
├── app_colors.dart         # semantic colour tokens
├── app_typography.dart     # TextTheme construction
├── app_spacing.dart        # spacing scale
├── app_radius.dart         # corner radii
├── app_elevation.dart      # elevation steps
├── app_durations.dart      # animation durations
├── app_breakpoints.dart    # responsive breakpoints
└── app_semantic_colors.dart # ThemeExtension for success/warning/info
```

## Scales

```dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double full = 999;
}

abstract final class AppIconSize {
  static const double sm = 16;
  static const double md = 24;   // Material default
  static const double lg = 32;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

abstract final class AppBreakpoints {
  static const double compact = 600;    // phone
  static const double medium = 840;     // tablet / foldable
  static const double expanded = 1200;  // desktop
}
```

`abstract final class` is the idiomatic Dart namespace for constants — it cannot
be instantiated or extended, which is exactly what you want from a token holder.

## Semantic colours

`ColorScheme` covers primary/secondary/tertiary/error and their containers. It
has no success, warning or info, so add them as a `ThemeExtension` rather than
as loose constants — an extension is theme-aware, so it changes with light/dark
automatically, and it survives `Theme.of(context)` lookups.

```dart
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  AppSemanticColors copyWith({Color? success, /* ... */}) => AppSemanticColors(
        success: success ?? this.success,
        // ...
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      // ...
    );
  }

  static const light = AppSemanticColors(/* ... */);
  static const dark = AppSemanticColors(/* ... */);
}
```

Read it with a short extension so call sites stay clean:

```dart
extension ThemeContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
```

This is the one extension worth having on `BuildContext`. Resist adding more —
the checklist's "không lạm dụng extension" exists because a `BuildContext` with
thirty extension getters becomes impossible to discover.

## Typography

Build a `TextTheme` once and let widgets read roles from it. Never construct a
`TextStyle` inside a feature widget.

```dart
Text('Title', style: context.texts.titleLarge)                    // yes
Text('Title', style: TextStyle(fontSize: 22, color: Colors.black)) // no
```

Two reasons this matters beyond consistency: a hardcoded `fontSize` does not
respond to the platform text-scale setting the same way, and a hardcoded
`Colors.black` is invisible in dark mode.

When a variant is needed, derive it: `context.texts.bodyMedium?.copyWith(color:
context.colors.error)`.

## Theme construction

```dart
ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: buildTextTheme(scheme),
    extensions: const [AppSemanticColors.light],
    appBarTheme: /* ... */,
    cardTheme: /* ... */,
    inputDecorationTheme: /* ... */,
    filledButtonTheme: /* ... */,
    // ... and the rest of the component themes
  );
}
```

Seeding produces a coherent, contrast-checked palette for free. Override
individual roles where the brand requires it, but re-check contrast after each
override — that is exactly where seeded guarantees stop applying.

## Verifying tokens are actually used

```bash
# hardcoded colours in feature code
grep -rnE 'Colors\.[a-z]|Color\(0x' lib/features lib/shared

# hardcoded text styles
grep -rn 'TextStyle(' lib/features

# raw padding values
grep -rnE 'EdgeInsets\.(all|symmetric|only)\([^)]*[0-9]' lib/features
```

Hits in `core/theme/` are expected and fine — that is where the values are
supposed to live. Hits anywhere else are the defect.
