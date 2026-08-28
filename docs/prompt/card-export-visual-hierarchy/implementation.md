# Card Export visual hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nâng hierarchy và trạng thái của Card Export theo Card Detail/design system mà giữ nguyên pipeline export |
| **Scope** | Export sheet, scope summary, format options, content lines, action bar, generating/scope-changed/error/cancel states |
| **Source of truth for** | Hướng dẫn presentation restyle; export behavior vẫn thuộc AD-20, BR-174…181, UC-11 và M4.13 |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/architecture.md#AD-20`, `docs/wireframes/m4-13-card-export.md`, relevant BR/UC |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Chỉ đổi layout, surface, typography, semantic color và interaction clarity. Không đổi scope,
schema sáu field, encoder, tag codec, filename, snapshot, selection retention, privacy,
share-sheet semantics hoặc cancel/error mapping.

## 5Why

Viết 5Why bằng ảnh/golden hiện tại: hierarchy nào phẳng; vì sao Card Detail recipes phù
hợp nhưng không được copy nguyên widget tree; state nào dễ mất khi restyle; token/shared
component nào giải quyết; evidence nào khóa pipeline read-only.

## UI contract

- Header/context → scope/card count → format selection → content/privacy explanation →
  primary export action. Một interaction region chỉ có một strong primary CTA.
- `all` và `selected` nói rõ phạm vi; scope changed/error phải nổi đủ nhưng không tô toàn
  panel gây rối. Format options có selected semantics và non-color cue.
- Generating giữ geometry, chặn double-submit và có busy semantics. Cancel share sheet là
  cancel, không success/error giả; copy không nói “saved” nếu OS chưa xác nhận.
- Dùng Mx shared surfaces/buttons/options và tokens; không raw Material policy widget,
  magic spacing/color/radius hoặc shared wrapper vô nghĩa.
- Long deck name, large count và VI copy wrap; action bar không bị keyboard/safe area che.

## Tests, verification và delivery

Giữ/extend tests cho all/selected, empty/stale selection, scope changed, generating,
repository/encoder/destination failure, share cancel/success, double tap và no mutation.
Render light/dark EN/VI, 320@2.0/393/412; `getRect` pin common edges, equal options,
action bar và stable loading geometry; test semantics/tap/focus.

Worktree sạch từ `origin/main`; không sửa AD/BR/UC frozen. Changed gate, full gate cuối.
UI-only không emulator. Regenerate goldens `TZ=UTC`, build/publish gallery URL hiện hữu,
commit/push và mở non-draft PR; không merge.

Clean stop khi pipeline parity có test, mọi state render sạch, full gate/golden xanh,
không P0/P1/P2 và gallery sẵn để owner confirm.
