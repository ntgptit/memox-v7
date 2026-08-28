# Recursive UI/UX review — Card List management

| | |
|---|---|
| **Status** | active |
| **Purpose** | So Card List production với M4.11 và design language đã duyệt bằng render/geometry thật |
| **Scope** | Card rows, summary, toolbar, filters, selection, overlays, empty/error states và accessibility |
| **Source of truth for** | Hướng dẫn recursive visual review; M4.11 và tokens là visual contract |
| **Depends on** | `docs/prompt/card-list-management-visual-hierarchy/implementation.md`, `docs/wireframes/m4-11-card-management.md`, production tree/goldens |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass **audit-only**. Render production states, không chỉ isolated row. Golden mới
không chứng minh concept parity.

Dùng `getRect` assert cùng outer gutter/shared edges; toolbar và list không có mép thụt
thứ ba; Front/Back/status baseline đều; row height chỉ tăng khi accessibility cần;
bottom row không bị nav che. Test 320@2.0, 393, 412; EN/VI; light/dark; long Korean/
Vietnamese; empty/search/filter/selection/menu/error/loading.

Approved divergence cố định: Back preview một dòng và density compact được giữ; full
content nằm ở Card Detail. Mọi khác biệt khác phải có bảng concept intent/evidence/
approved difference/result. Audit touch target, focus, traversal, merged semantics,
non-color state và destructive hierarchy.

Coordinator auto-fix findings trên latest tree, thêm geometry/semantics tests, chạy gate,
render và compare lại. **Clean stop** khi không còn P0/P1/P2, không overflow/false affordance,
goldens `TZ=UTC` đã inspect và gallery cũ được republish. Reviewer không edit đồng thời,
không commit/push/merge.
