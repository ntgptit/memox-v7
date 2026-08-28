# Accessibility and localization hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và harden accessibility/localization toàn app mà giữ nguyên nghiệp vụ và information architecture |
| **Scope** | Semantics, focus, touch targets, text scaling, contrast/non-color cues, ARB parity, copy intent và locale-sensitive layout |
| **Source of truth for** | Hướng dẫn thực thi hardening; message meaning và behavior vẫn thuộc canonical docs/ARB contracts |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, localization rules, accessibility tests, gallery và relevant wireframes |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Không viết lại copy theo sở thích và không đổi behavior để dễ test. Khi meaning giữa docs,
EN và VI mâu thuẫn, dừng hỏi owner nếu canonical intent không đủ rõ.

## 5Why

Viết 5Why có evidence cho: loại lỗi a11y/l10n đang lọt; vì sao golden không đủ; shared
owner nào nên sửa; risk của mass key rename; test nào khóa observable outcome thay vì
implementation detail.

## Inventory và fixes

- Scan hardcoded user text, missing/unused/non-parity ARB keys, duplicate meanings,
  placeholder/plural/date/number misuse và technical copy lọt ra UI.
- Audit semantics name/value/state/hint, duplicated nested semantics, traversal/focus order,
  keyboard/back activation, 48dp interactive target, tooltip và busy/live-region behavior.
- Audit light/dark/high-contrast, color-only state, text scale 2.0, 320dp, long Vietnamese,
  Korean content và RTL resilience của shared components (không cần thêm locale RTL nếu app
  chưa support; chỉ không hardcode order sai).
- Fix ở owner thấp nhất đúng: token/shared component khi lỗi lặp; feature khi semantics
  mang nghiệp vụ riêng. Không thêm wrapper vô nghĩa hoặc giảm font/disable scaling.
- Message key mới phải có EN/VI parity, description/placeholder đúng convention và không
  log private card content.

## Verification và delivery

Thêm tests `meetsGuideline`, semantics traversal, focus/keyboard, text-scale geometry,
ARB parity/placeholder và production route state. Không dùng screenshot OCR thay assertion.
Worktree sạch; changed gate theo cluster, full gate cuối. Không emulator nếu host tests bao
phủ và không có device-only change; ghi status thật. Regenerate affected goldens `TZ=UTC`,
inspect và publish existing gallery. Commit/push, mở non-draft PR; không merge.

Clean stop khi inventory triage hết, không P0/P1/P2, EN/VI parity, no clipped/hidden control,
screen-reader state không sai, full gate/golden xanh và gallery sẵn owner confirm.
