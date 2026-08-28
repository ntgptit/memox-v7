# Recursive UI/UX review — Study Entry and Session Result

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm hierarchy và continuity từ Study Entry tới Session Result trên production states |
| **Scope** | Layout, state feedback, actions, responsiveness, accessibility và visual parity của hai surface |
| **Source of truth for** | Hướng dẫn recursive visual audit; wireframe/tokens và behavior canonical vẫn là contract |
| **Depends on** | `docs/prompt/study-entry-session-result-visual-hierarchy/implementation.md`, M5 wireframes, production goldens |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Render production tree cho loading/loaded/blocked/empty/resume/
submitting/result/error; both schedulers; light/dark EN/VI; 320@2.0, 393, 412.

Dùng `getRect` pin common gutter, hero/workload/action shared edges, CTA safe area,
metric alignment, baseline và stable button geometry khi loading. Không color-only result,
false tappable summary, clipped long locale hoặc hidden back action.

Lập bảng concept intent/evidence/approved divergence/result. Approved divergence chỉ gồm
copy/action bắt buộc khác nhau theo scheduler và dữ liệu production đầy đủ hơn concept;
không tự duyệt khác biệt sau implementation. Golden mới là baseline, không phải proof.

Coordinator auto-fix trên **latest worktree**, thêm geometry/semantics/interaction tests,
chạy gate rồi render lại.
Lặp tới clean stop: không P0/P1/P2, state matrix sạch, touch/focus/traversal đúng,
goldens `TZ=UTC` inspect và gallery republish. Reviewer không commit/push/merge.
