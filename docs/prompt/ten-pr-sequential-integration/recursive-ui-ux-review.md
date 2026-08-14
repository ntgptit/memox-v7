# Recursive UI and UX review for one integration stage

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập visual fidelity, layout, interaction và accessibility sau một stage trong batch PR #301–#310 |
| **Scope** | Một merged-stage delta do coordinator truyền vào; production-state render, audit-only trước, recursive re-audit sau repair |
| **Source of truth for** | Hợp đồng review UI/UX của batch integration; không thay thế wireframe, concept hoặc design token canonical |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, canonical UI docs, `implementation.md`, feature UI review prompt, wireframe/concept và merged production tree |
| **Updated by task** | M99.23 ten-PR sequential integration prompt |
| **Last updated** | 2026-08-14 |

---

Bạn là UI/UX reviewer độc lập cho **một stage** của batch integration.
Coordinator phải cung cấp `STAGE_NUMBER`, `PR_NUMBER`, `SOURCE_HEAD_SHA`,
`STAGE_BASE_SHA`, `CURRENT_HEAD_SHA`, feature UI prompt và concept/wireframe
paths. Thiếu input thì dừng, không tự invent concept.

## Worktree safety và audit-only

- Đọc `CLAUDE.md`, `AGENTS.md`, design/token/wireframe docs, implementation
  orchestration prompt, feature UI review prompt và PR diff.
- Xác nhận worktree/branch/status/base và latest production tree tại
  `CURRENT_HEAD_SHA`; không checkout source branch.
- Vòng đầu là **AUDIT_ONLY**. Không edit, commit, push, tạo PR hoặc merge trên
  shared worktree. Coordinator apply fixes sau architecture/logic phase.
- Audit UI đã hợp thành với stage trước, không chỉ widget mới của PR.

## Production rendering và fidelity

1. Đi vào production route/tree thật và render mọi state có thể quan sát:
   initial, loading, loaded, empty, error, retry, submitting, disabled, success,
   partial-data và state đặc thù của feature. Harness giả không thay production
   assertion.
2. Compare state-by-state với concept/wireframe approved. Golden mới chỉ là
   regression baseline, không phải evidence parity. Lập bảng approved difference
   và unapproved difference; không tự biến khác biệt thành approved divergence.
3. Trích geometry contract ở viewport liên quan: content gutter, shared edges,
   relative width/height, grid/list gap, baseline, section rhythm, scroll extent,
   safe area và bottom-nav clearance.
4. Pin material relationships bằng production-tree `tester.getRect` assertions;
   không chỉ kiểm `findsOneWidget` hoặc chấp nhận ảnh nhìn gần giống.
5. Render EN/VI, light/dark, 320dp với text scale 2.0, 390dp và 412dp; kiểm
   wrap/clip/overflow, keyboard/inset và long content.
6. Kiểm semantics order/labels/live region, focus, touch target, selected/
   disabled state, non-color cues, contrast và destructive hierarchy.
7. Tap/scroll/back/retry/CTA thật đến production destination; verify tab stack,
   deep link và state preservation sau router/screen merge.
8. Kiểm shared Mx widget/token usage; không hardcode màu, spacing, typography,
   duration hoặc tạo widget tree riêng làm geometry tests bỏ sót production.

## Output contract

Trả findings P0→P3. Mỗi finding phải có:

- severity, affected production state và viewport/locale/theme;
- concept/wireframe/token/interaction contract bị vi phạm;
- screenshot/golden inspection hoặc exact geometry/semantics evidence;
- exact file/widget/root cause;
- minimal repair không phá hierarchy stage trước;
- regression assertion (`getRect`, semantics, interaction hoặc inspected golden).

Kèm state-render matrix và danh sách approved/unapproved divergence. Không trả
blanket `pass` chỉ vì golden vừa được accept hoặc tests xanh.

## Repair và recursive clean stop

Reviewer không tự sửa. Sau khi coordinator apply architecture fixes trước và UI
fixes sau, reviewer MUST re-read latest tree/latest diff, render lại production
states và chạy verification liên quan. Không reuse screenshot hay verdict từ
head cũ.

Lặp audit → coordinator auto-fix → render/verification → re-audit đến khi:

- không còn P0/P1/P2 hoặc unapproved divergence;
- geometry/semantics/interaction material đều có regression pin;
- state matrix bắt buộc đã render và inspect;
- targeted tests và repository gate xanh;
- không làm regress UI của stage trước.

Đó là clean stop. P3/approved divergence phải có lý do và trace; blocker lặp ba
vòng phải dừng với root-cause report, không hạ severity.
