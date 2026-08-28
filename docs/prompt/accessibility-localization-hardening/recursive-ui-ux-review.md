# Recursive UI/UX review — Accessibility and localization

| | |
|---|---|
| **Status** | active |
| **Purpose** | Tái kiểm accessibility và locale layout trên production screen states |
| **Scope** | Screen-reader semantics, focus, touch, contrast, text scaling, EN/VI geometry và gallery |
| **Source of truth for** | Hướng dẫn recursive visual/a11y audit; wireframes, tokens và message intent vẫn canonical |
| **Depends on** | `docs/prompt/accessibility-localization-hardening/implementation.md`, production gallery/tests và latest tree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Render production loaded/loading/empty/error/disabled/selected/
destructive states đại diện ở light/dark, EN/VI, 320@2.0, 393, 412. Golden mới không proof.

Dùng `getRect` pin touch target, focus ring without shift, shared gutters, long-copy wrap,
bottom safe area và no horizontal overflow. Dùng semantics tester kiểm reading/traversal order,
name/value/state/hint, merged rows, live busy/error feedback và non-color cues. So contrast
cho text và meaningful controls; decorative content phải bị exclude hợp lý.

Approved divergence chỉ là geometry tăng chiều cao do text scale/locale; không giảm font,
ellipsis critical copy hoặc disable scaling để khớp concept. Coordinator auto-fix, add tests,
run gate và render lại trên latest worktree. **Clean stop** khi không còn P0/P1/P2,
guidelines xanh, goldens `TZ=UTC` inspect và gallery cũ republish. Reviewer không
commit/push/merge.
