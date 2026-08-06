repo: ntgptit/memox-v7
branch: main

## Last sync

date: 2026-07-31T04:40:00Z

### Updated in this project
- Built the full token set from `lib/core/theme/` — colour, type, spacing, radius, elevation, motion, breakpoints.
- Recreated the `lib/shared/widgets/mx_*.dart` inventory as React primitives (plus one `MxIcon` wrapper).
- Recreated four app screens as a click-through UI kit from the deck feature and the golden design previews.
- Copied the bundled Inter and Plus Jakarta Sans variable fonts and the upstream golden screenshots.

## Screen map

| Screen / artifact | Built from |
|---|---|
| `tokens/*.css` | `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_elevation.dart`, `app_icon_size.dart`, `app_durations.dart`, `app_breakpoints.dart`, `app_semantic_colors.dart`, `app_theme.dart`, `app_button_themes.dart`, `app_compact_scale.dart` |
| `components/core/*` | `lib/shared/widgets/mx_action_button.dart`, `mx_icon_button.dart`, `mx_pill_button.dart`, `mx_card.dart`, `mx_text_field.dart`, `mx_list_tile.dart` |
| `components/feedback/*` | `lib/shared/widgets/mx_empty_state.dart`, `mx_error_state.dart`, `mx_loading_state.dart`, `mx_async_view.dart`, `mx_confirm_dialog.dart`, `mx_action_sheet.dart` |
| `components/navigation/*` | `lib/shared/widgets/mx_navigation_bar.dart`, `mx_breadcrumb.dart`, `mx_content_shell.dart`, `lib/app/shell/app_navigation_shell.dart` |
| `ui_kits/memox-app/DeckLevelScreen.jsx` | `lib/features/deck/presentation/screens/deck_list_screen.dart`, `widgets/items/deck_tile_widget.dart`, `widgets/sections/deck_list_toolbar_widget.dart`, `widgets/sections/deck_path_widget.dart`, `test/demo/deck_screens_demo_test.dart` |
| `ui_kits/memox-app/ReviewScreen.jsx` | `test/design_preview/review_screen_preview_test.dart`, `preview_harness.dart` |
| `ui_kits/memox-app/SettingsScreen.jsx` | `test/design_preview/settings_preview_test.dart` |
| `ui_kits/memox-app/DeckForms.jsx` | `lib/features/deck/presentation/widgets/overlays/deck_form_widget.dart` |
| `assets/fonts/*`, `test/design_preview/goldens/*` | copied verbatim from the repo |
