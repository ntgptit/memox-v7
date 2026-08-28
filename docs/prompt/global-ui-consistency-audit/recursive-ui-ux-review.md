# Recursive UI/UX review — Global UI consistency

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh consistency toàn app bằng production renders, không bằng golden acceptance mù |
| **Scope** | Representative screen/state matrix, shared component specimens, geometry, accessibility và gallery |
| **Source of truth for** | Hướng dẫn recursive visual audit; wireframes/tokens/approved divergences vẫn canonical |
| **Depends on** | `docs/prompt/global-ui-consistency-audit/implementation.md`, production gallery, wireframes và latest tree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Render representative production states cho mọi top-level destination
và feature family ở light/dark, EN/VI, 320@2.0, 393, 412. So before/after và concept;
golden mới không phải proof.

Pin bằng `getRect`: screen gutters/shared edges, app bar/body/bottom-nav, section rhythm,
card nesting/elevation, CTA geometry, list baselines, dialog/sheet action edges. Audit typography,
surface ladder, focus/pressed/disabled/loading, contrast, semantics, touch target và no overflow.

Approved divergence phải lấy từ canonical prompt/wireframe trước audit; không hợp thức hóa
implementation sau khi thấy diff. Coordinator auto-fix sequentially, add regression assertions,
run gate, render lại trên latest worktree. **Clean stop** khi không còn P0/P1/P2,
no inconsistent family state và gallery hiện hữu đã
republish từ `TZ=UTC` goldens. Reviewer không commit/push/merge.
