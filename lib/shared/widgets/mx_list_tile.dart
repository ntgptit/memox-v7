import 'package:flutter/material.dart';

import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_focus_ring.dart';

/// A row in a list.
///
/// Deliberately generic. It takes a `String` title and a `Widget?` leading, not
/// a deck or a card: the moment a shared tile knows an entity, every widget test
/// in the project pulls the domain in behind it, and the tile stops being usable
/// by the next feature that has a different entity and the same layout.
///
/// **What a row is, and what it is not** (M100.36 4H). This is the ordinary
/// navigation, settings, control or choice row — a title, a second line, a
/// glyph on either side, one tap. `MxCard` is an entity or content surface
/// whose own grouping and depth carry meaning; a feature-owned row exists only
/// when its composition genuinely exceeds this one (the deck tile's four
/// regions, a progress row's metric grid, a search result's widget body).
/// `docs/design-system/tokyo-component-mapping.md` §7 states the boundary;
/// what it forbids is a screen reaching for a card because a row could not
/// take a fifth thing.
///
/// Padding, minimum height and the selected colour come from `ListTileThemeData`
/// so a row keeps the same shape wherever it is used.
///
/// **The interaction states do not, and that is a `ListTile` limitation rather
/// than a choice.** `ListTileThemeData` has no slot for hover, focus or splash,
/// so a bare `ListTile` takes `ThemeData.hoverColor` and friends — hardcoded
/// washes with no seed in them. They are resolved here from
/// `AppInteractionStates.rowOverlay`, which is the one definition every row in
/// the app shares.
///
/// **Focus draws the shared ring, and only for a keyboard.** The row's focus
/// wash measures around 1.15:1 against the surface behind it where WCAG 1.4.11
/// asks 3:1 of a focus indicator, so on its own it marks the focused row for
/// people who can already see where they are. `MxFocusRing` paints the ring in
/// *front* of the tile — a background decoration would be covered by
/// `selectedTileColor` on a selected row, which is exactly the row most likely
/// to be focused — and gates it to `FocusHighlightMode.traditional`, so a
/// touch screen does not grow a keyboard affordance (M100.36; the row used to
/// hand-roll an ungated ring of its own, one of three focus answers #431
/// counted).
///
/// **Trailing is presentational** (M100.36 4K). A chevron, a count, a glyph — not
/// a button. A control that acts on its own belongs to `MxSwitchRow`,
/// `MxCheckboxRow` or `MxRadioRows`, which own the gesture arena and the
/// doubled semantics a nested control brings; a generic row that admitted one
/// would also have `ListTile` force-colour it to the row's text colour.
class MxListTile extends StatelessWidget {
  const MxListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
    this.isSelected,
    super.key,
  });

  /// Already-localized.
  final String title;
  final String? subtitle;

  final Widget? leading;

  /// Presentational only — see the class note.
  final Widget? trailing;

  /// `null` makes the row non-interactive without greying it out — a heading
  /// row, or a row whose action has not loaded yet.
  ///
  /// **Non-interactive means out of the focus order too** (M100.36 10B). A row
  /// with no tap used to stay Tab-reachable, draw the ring and do nothing on
  /// Enter — an unavailable study mode was the live case (#431 P1-2). An inert
  /// row is now excluded from focus; `ListTile` already withholds the `button`
  /// flag when there is nothing to tap.
  final VoidCallback? onTap;

  /// `false` greys the row and removes it from the focus order. Distinct from a
  /// null [onTap]: one says "not now", the other says "never".
  final bool isEnabled;

  /// Whether this row is the picked one, in a list where picking is the point.
  ///
  /// **Tri-state, the same contract as `MxCard.isSelected`** (M100.36 10D).
  /// `null` is a row with no selection concept — navigation, a setting, an
  /// action — and it says nothing about being chosen. `false` is a selectable
  /// row currently unpicked; `true` is the pick. A non-nullable flag made every
  /// navigation row announce a selection state it did not have (#431 P2-3).
  ///
  /// **A selectable `MxListTile` is one of an exclusive group** (10E): the two
  /// production pickers — study direction, restore target — pick one of N, and
  /// the node says so with `inMutuallyExclusiveGroup`. A pick-many row is
  /// `MxCheckboxRow`, whose semantics are `checked`, not `selected`.
  ///
  /// Selection recolours the **title** to `primary` and the fill to
  /// `semantic.surfaceSelected` — the one app-owned "picked" surface, shared
  /// with `MxCard`'s tint (4I). The subtitle stays the secondary ink: a row's
  /// second line is context, not the thing that was chosen. Typography does
  /// not move (4L).
  ///
  /// **`ListTile` 3.44.8 still emits `hasSelectedState` for a null here** —
  /// it passes a non-nullable `selected` to its own `Semantics`
  /// (`list_tile.dart:997`). The API is tri-state so the SDK's is, the day it
  /// becomes one; until then a null row is `selected: false` at the node,
  /// which TalkBack reads as nothing.
  final bool? isSelected;

  bool get _isInteractive => isEnabled && onTap != null;

  @override
  Widget build(BuildContext context) {
    final overlay = AppInteractionStates.rowOverlay(context.colors);
    final subtitle = this.subtitle;
    final bool? selection = isSelected;

    Widget tile = ListTile(
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          // Two lines then ellipsis rather than unbounded growth: at
          // textScaler 2.0 an unbounded subtitle pushes the trailing action
          // off a 320-wide screen, and the row silently loses its only
          // control.
          //
          // **Its own colour while enabled.** `ListTile` copies one
          // `effectiveColor` onto the title and the subtitle alike, and a
          // selected row's effective colour is `selectedColor` — so a picked
          // row's second line turned `primary` too (#431 P2-14), where the
          // kit selects only the title. Stated on the `Text`, which wins over
          // the tile's `DefaultTextStyle`; left unstated while disabled so
          // the row's grey reaches it.
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: isEnabled
                  ? context.texts.bodyMedium!.inked(context, AppInk.quiet)
                  : null,
            ),
      leading: leading,
      trailing: trailing,
      onTap: _isInteractive ? onTap : null,
      enabled: isEnabled,
      selected: selection ?? false,
      // Resolved from the one row contract rather than passed three loose
      // colours. `ListTile` has no `overlayColor`, so this is where the
      // property is unpacked — the values still have a single definition.
      // The pressed *highlight* has no slot here at all — `ListTile` 3.44.8
      // takes hover, focus and splash and lets the highlight fall to
      // `ThemeData.highlightColor`, which `app_theme.dart` seeds to the same
      // `primary` @ 12% (#431 P3, recorded rather than worked around).
      hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
      focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
      splashColor: overlay.resolve(const <WidgetState>{WidgetState.pressed}),
    );

    if (selection != null) {
      // Exclusive choice, announced as one: see [isSelected].
      tile = Semantics(inMutuallyExclusiveGroup: true, child: tile);
    }

    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.md),
      // An inert row is not a stop on the keyboard.
      child: ExcludeFocus(
        excluding: !_isInteractive,
        // **Its own transparent `Material`, so the row can sit on any surface**
        // — the same move `MxPressable`, `MxRadioRows` and `MxSwitchRow` made.
        // `ListTile` paints its fill and ink onto the nearest `Material`, and
        // inside an `MxCard` that is the Scaffold's, behind the card; two
        // callers hand-wrote this shim until M100.36 (#431 P2-11).
        child: Material(type: MaterialType.transparency, child: tile),
      ),
    );
  }
}
