# Recursive UI/UX Review — Study Home Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit trực quan và auto-fix Study Home tới khi đạt style Card Detail mà vẫn đúng M5 |
| **Scope** | Layout, hierarchy, interaction, responsiveness, semantics và rendered states của Study Home |
| **Source of truth for** | Quy trình recursive UI/UX review của Study Home visual hierarchy |
| **Depends on** | `implementation.md`, M5 Study Home, production Card Detail, MemoX tokens và current goldens |
| **Updated by task** | Study Home visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Chạy sau architecture fixes và re-read worktree. Card Detail cung cấp style về
flat surfaces, compact typography, semantic wells và shared edges; M5 sở hữu
anatomy, copy và action behavior.

## Phase order và worktree safety

Vòng đầu MUST là **audit-only**: đọc latest worktree/latest diff, **render
production states**, so wireframe/golden và lập inventory; chưa sửa. Không revert
ngoài scope, không commit/push/PR/merge. Sau đó mới auto-fix; chạy verification/
tests sau mỗi batch và recursive review lại từ đầu.

**Approved divergences**: Study Home có Resume focal surface và repeated task cards;
không copy Card Detail timeline/progress hero. Ba workload metric luôn hiện kể
cả 0. Card không tappable; button mới là action.

Render light/dark, 320dp @2.0, 393dp, 412dp, EN/VI cho resume+mixed, no-resume,
all-zero, long names/counts, no-deck, no-card, error và refresh snapshot.

Pin bằng `tester.getRect` trên production tree: supporting/resume/heading/rows chung content column; resume
và row edges bằng nhau; row gaps nhất quán; metric well-label không tách; action
không overlap/wrap sai; last row bottom clearance; 48dp targets. Kiểm không card
soup, saturated workload background, double padding, shadow stack hay giant type.

Với mỗi finding, lưu state/viewport/screenshot, expected/actual và rect. Auto-fix
mọi unapproved divergence, render lại và lặp tới **clean stop** khi không còn P0/P1/P2, mọi localized state không overflow,
focus/semantics đúng, hierarchy rõ trong light/dark. Không đổi nghiệp vụ, không
publish gallery và không tạo PR.
