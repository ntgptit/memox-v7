# Recursive UI/UX review — Gallery and shared cleanup

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh gallery phản ánh production HEAD và cleanup không gây visual degradation |
| **Scope** | Before/after production renders, gallery inventory, geometry, shared component states và owner confirmation evidence |
| **Source of truth for** | Hướng dẫn recursive visual audit; canonical wireframes/tokens/approved differences vẫn quyết định parity |
| **Depends on** | `docs/prompt/gallery-shared-pattern-cleanup/implementation.md`, existing Artifact gallery, production goldens/latest tree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass audit-only. Capture before state and render production after state at 393×852;
stress 320@2.0/412 stays in tests. Golden regenerated from implementation is not proof.

Dùng pixel diff cộng `getRect` cho shared gutters, component bounds, baselines, safe area,
focus/loading geometry và migrated callers. Inspect light/dark, EN/VI, loading/empty/error/
disabled/selected states đại diện. Gallery entries phải đúng name, dimensions, commit stamp,
ordering và không duplicate/stale image.

Approved divergences phải được liệt kê trước cleanup; zero-delta extraction là expectation.
Nếu có intended correction, cần visible/measured reason và owner-facing note. Coordinator
auto-fix, add geometry/golden assertions, run gate, regenerate `TZ=UTC`, build và republish
same Artifact URL. **Clean stop** khi không còn P0/P1/P2, no unapproved diff, gallery verified và PR ready
nhưng chưa merge. Reviewer không commit/push/merge.
