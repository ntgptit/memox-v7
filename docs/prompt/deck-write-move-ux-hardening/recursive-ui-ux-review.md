# Recursive UI/UX review — Deck write and move

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm form/sheet deck dễ hiểu, ổn định và accessible trên mọi state production |
| **Scope** | Create/rename/kind/move/scheduler/reset overlays, action hierarchy và responsive geometry |
| **Source of truth for** | Hướng dẫn recursive visual audit; behavior canonical và MemoX shared UI vẫn là contract |
| **Depends on** | `docs/prompt/deck-write-move-ux-hardening/implementation.md`, relevant production goldens, latest tree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. **Render production states** của mọi overlay bằng production launcher ở loaded/loading/error/
invalid/submitting/disabled/success và long-name states; light/dark EN/VI; 320@2.0/393/412.

Dùng `getRect` assert shared sheet gutter, field/action edges, stable bottom action bar, keyboard/
safe-area clearance, target-row alignment và no size shift. Disabled/incompatible target cần
text/semantics; reset/destructive action phân cấp đúng; focus order và back/cancel rõ.

Lập concept/current-token comparison và approved divergence trước fix. Golden mới không phải
proof. Coordinator auto-fix sequentially, add geometry/semantics/interaction tests, run gate,
render lại. Clean stop khi không P0/P1/P2, không overflow/clipping/false affordance,
goldens `TZ=UTC` và gallery URL cũ đã cập nhật. Reviewer không commit/push/merge.
