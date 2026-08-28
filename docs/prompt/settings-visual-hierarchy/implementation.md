# Upgrade Settings — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp Settings thành form cấu hình compact, rõ nhóm và nhất quán với Card Detail |
| **Scope** | Presentation Settings, study-default/appearance/language/reminder-entry/reset sections, tests/goldens/gallery; không đổi persistence hoặc settings semantics |
| **Source of truth for** | Hướng dẫn thực thi Settings visual hierarchy; nghiệp vụ vẫn thuộc BR-210…BR-217, UC-16 và M99 Settings |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-210…BR-217, UC-16, `docs/wireframes/m99-settings.md`, production Card Detail và MemoX design tokens |
| **Updated by task** | Settings visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Restyle production **Settings**. Giữ nguyên một settings snapshot, group-scoped
writes, study-default draft/save, immediate theme/language writes, reset scope,
Reminder route entry và bottom-nav branch.

## Pre-flight và 5Why

Đọc repo contract, BR-210…BR-217, UC-16, M99 Settings, code/tests/goldens hiện
tại, Card Detail và shared form/list/radio/button components. Lập reduced UI
Contract và widget tree; kiểm branch/base/dirty state. Không commit/push/PR trong
implementation phase.

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Các control/radio đang quá lớn, làm Settings giống form demo hơn product screen. | Dùng compact type và grouped flat surfaces, vẫn giữ touch target 48dp. |
| 2 | Mọi nhóm là card lớn ngang nhau nên thiếu phân cấp giữa editable draft và instant choice. | Study defaults là working panel; choice groups là compact selection panels. |
| 3 | Save sáng dù draft chưa đổi tạo cảm giác có việc chưa lưu. | Nút Save disabled khi pristine/invalid/submitting và enabled khi dirty hợp lệ. |
| 4 | Reminder entry và reset dễ bị đọc như nhóm lựa chọn thứ tư/thứ năm. | Dùng navigation row riêng và destructive text region nhẹ ở cuối. |
| 5 | Restyle form dễ phá persistence rollback/draft. | Không đổi controllers; pin state transitions và group-level error geometry. |

## Visual thesis

- `MxContentShell`, one scroll owner, centered max-width column, canonical gutter.
- Background page tách khỏi flat `MxCard`; subtle borders, không shadow stack.
- Uppercase section labels + compact `bodySmall/titleSmall` như Card Detail.
- Choice row full-width touch/ink; radio glyph là selected signal, không color-only.
- Một CTA mạnh trong Study Defaults; reset nhẹ/danger text, không red card.

## UI Contract

```text
MxContentShell / Settings branch
└─ centered column
   ├─ STUDY DEFAULTS + working MxCard
   ├─ APPEARANCE + compact choice MxCard
   ├─ LANGUAGE + compact choice MxCard
   ├─ Daily reminder navigation row/surface
   └─ Reset-to-defaults destructive region
```

### Study defaults

- Giữ Card limit field, New card order radio choices, BR-213 explanation và
  Save. Không đổi validation/bounds/default/order.
- Front-loaded hierarchy: labels compact, field/control readable, explanatory
  copy quiet. Không dùng giant outlined field nếu shared `MxTextField` có
  compact approved geometry.
- Save dùng `MxActionButton`, full content width. Disabled khi draft pristine,
  invalid hoặc submitting; loading giữ width/height. Dirty state phải dẫn xuất
  từ local form draft so với persisted input, không ghi vào domain/provider.
- Error band nằm trong same card/column, giữ draft và retry đúng command.

### Appearance và language

- Giữ `RadioGroup` + radio rows theo M99 Settings; không đổi thành pill/
  segmented button.
- Surface chỉ có vertical outer padding; row sở hữu canonical horizontal inset
  để touch/ink full-width. Divider subtle giữa rows MAY dùng nếu component
  contract hỗ trợ, nhưng không vừa divider vừa gap lớn.
- Theme/language apply ngay và group đang submit mới disabled. Selected state có
  radio glyph + semantics; không tạo Save chung.

### Reminder entry và reset

- Reminder là compact navigation row có leading semantic well, label và
  chevron; không import/watch Reminder state.
- Reset là destructive text action cùng explanatory copy hiện có, tách bằng
  spacing/divider subtle; không card danger, không background đỏ.
- Confirm dialog giữ nguyên copy/scope/cancel-default và transaction behavior.

## Files dự kiến

- `lib/features/settings/presentation/screens/settings_screen.dart`
- sections/items/overlays hiện có dưới `features/settings/presentation/widgets/`
- shared component chỉ khi gap đã chứng minh và API semantic, không local wrapper
- append visual revision vào M99 Settings, cập nhật `docs/wbs.md`
- ARB chỉ khi thiếu semantic key; tests/goldens/Widgetbook/visual audit.

## Không được thay đổi

- BR-210…BR-217, UC-16, one-row settings source, typed values.
- Group transaction/rollback, immediate theme/language, study-default submit,
  reset scope, active session behavior.
- Settings branch/route, Reminder cross-feature seam, domain/data/schema.
- Radio semantics hoặc global tokens/type scale.

## Tests bắt buộc

- Regression loading/read error, default/custom, dirty/pristine/invalid,
  group saving/failure/retry, theme/language immediate, reset cancel/success/error.
- Test Save disabled pristine, enabled only dirty+valid, loading stable, failed
  save preserves draft and persisted values elsewhere.
- `getRect`: all labels/cards/reset same content edges; cards same width; choice
  row text aligns with study-card content; rows/Save ≥48dp; error bands same
  column; bottom content scrolls above nav.
- 320dp @2.0, 393dp, 412dp; EN/VI; light/dark; keyboard open; long localized
  labels. No ellipsis for settings labels.
- Semantics group names disambiguate two “System” rows; selected/disabled/busy
  announced; focus order follows screen.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không emulator IT: `not run — presentation-only restyle`. Clean stop khi state,
geometry, a11y và changed gate xanh; persistence/navigation unchanged; worktree
sẵn sàng reviews. Coordinator chịu trách nhiệm gallery và PR.
