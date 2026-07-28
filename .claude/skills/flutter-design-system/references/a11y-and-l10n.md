# Localization and accessibility patterns

## ARB setup

`pubspec.yaml`:

```yaml
flutter:
  generate: true
```

`l10n.yaml` at the project root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/generated
synthetic-package: false
nullable-getter: false
```

`nullable-getter: false` means `AppLocalizations.of(context)` returns
non-nullable, so call sites lose a `!` on every string.

## Writing ARB entries

```json
{
  "deckCount": "{count, plural, =0{No decks} =1{1 deck} other{{count} decks}}",
  "@deckCount": {
    "description": "Number of decks on the library screen",
    "placeholders": { "count": { "type": "int" } }
  },

  "lastReviewed": "Last reviewed {date}",
  "@lastReviewed": {
    "description": "Subtitle on a deck card",
    "placeholders": {
      "date": { "type": "DateTime", "format": "yMMMd" }
    }
  }
}
```

Always fill in `description`. A translator sees the string without the screen,
and "Open" as a verb and "Open" as a status translate differently in most
languages.

**Never build a sentence from parts.** `l10n.youHave + count + l10n.items` is
untranslatable — word order, gender agreement and plural forms all differ. One
key holds one complete sentence with placeholders, which is what lets the plural
syntax above do its job.

**Never `DateTime.toString()`.** Format through `intl` with the active locale, or
via the ARB `format` above.

## Fallback

Declare `supportedLocales` and a `localeResolutionCallback` that falls back to
the template locale on an unsupported request. Without it, an unsupported device
locale can render blank strings.

## Accessibility patterns

**Icon-only control:**

```dart
IconButton(
  icon: const Icon(Icons.delete_outline),
  tooltip: l10n.deleteDeck,          // also serves as the semantic label
  onPressed: onDelete,
)
```

**Decorative image** — hide it, so a screen reader does not announce noise:

```dart
ExcludeSemantics(child: Image.asset('assets/illustration.png'))
```

**Grouping** — announce a card as one item instead of four fragments:

```dart
Semantics(
  container: true,
  label: l10n.deckCardSemantics(deck.name, deck.cardCount),
  child: const _DeckCardContent(),
)
```

**Never colour alone:**

```dart
// no — invisible to a colour-blind user
Text(status, style: TextStyle(color: isOverdue ? red : green))

// yes — icon plus text carry the meaning too
Row(children: [
  Icon(isOverdue ? Icons.warning_amber : Icons.check_circle),
  Text(isOverdue ? l10n.overdue : l10n.upToDate),
])
```

**Reduced motion:**

```dart
final disableAnimations = MediaQuery.disableAnimationsOf(context);
final duration = disableAnimations ? Duration.zero : AppDurations.normal;
```

**Touch target** — pad rather than enlarging the icon:

```dart
ConstrainedBox(
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  child: child,
)
```

## Testing these

Text scale and small screen, in a widget test:

```dart
await tester.pumpWidget(
  MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2)),
    child: const ProviderScope(child: MyApp()),
  ),
);
expect(tester.takeException(), isNull);   // catches overflow
```

Semantics:

```dart
final handle = tester.ensureSemantics();
expect(find.bySemanticsLabel(l10n.deleteDeck), findsOneWidget);
handle.dispose();
```

Missing translation keys — worth running in CI, because a key added to `app_en`
and forgotten elsewhere fails silently at runtime:

```bash
dart run scripts/check_arb_parity.dart   # compare key sets across ARB files
```

**Never** fix an overflow by clamping the text scaler:

```dart
// no — breaks the app for users who need large text
MediaQuery.withNoTextScaling(child: ...)
```

The overflow is telling you a fixed height or a non-wrapping row is wrong. Fix
that instead.
