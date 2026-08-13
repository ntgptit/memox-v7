# Recursive UI/UX Review — Progress Overview v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa đệ quy visual fidelity, geometry, interaction và accessibility của Progress Overview |
| **Scope** | Production Progress screen, ba section, mọi state, locale/theme/viewport và visual tests |
| **Source of truth for** | Quy trình recursive UI/UX review Progress Overview v1 |
| **Depends on** | `docs/prompt/progress-v1/implementation.md`, Progress wireframe, MemoX tokens và production states |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Đọc `CLAUDE.md`, design-system/testing skills, Progress wireframe, approved
divergences, Mx shared components/tokens và production tree mới nhất. Không coi
golden vừa tạo là bằng chứng parity.

## Execution mode

- `AUDIT_ONLY`: render và inspect, không edit; trả findings có severity,
  screenshot/state/viewport, measured rects, expected relationship và fix.
- `APPLY_FIXES` hoặc standalone: sửa tuần tự trên latest worktree, rerender,
  inspect và lặp đến clean stop; không commit/push/PR/merge.

## Ma trận bắt buộc

Render qua production route: loading; normal mixed activity; today 0 nhưng
streak từ hôm qua còn; lifetime empty+CTA; error+Retry; long streak/count;
midnight/live refresh. Mỗi state kiểm EN/VI, light/dark, 320dp @ 2.0 text scale,
390dp và 412dp.

Đo bằng `tester.getRect` và pin tối thiểu: screen gutter; left/right shared edge
của hero, Today và Last 7 days; section widths; internal padding; vertical gaps;
headline/label baselines; chart bar width/gap/baseline; safe-area và bottom-nav
clearance. Kiểm text wrap không đổi alignment, không intrinsic-width làm section
thụt mép và không overflow/clip.

Review hierarchy, neutral zero state, contrast ở cả theme, color-independent
meaning, 48dp targets, TalkBack order/labels cho streak và từng ngày, CTA/Retry
behavior, focus và reduced-motion implications. Chỉ dùng repo tokens/Mx widgets;
không hardcode màu/spacing/duration để vá ảnh.

Mỗi visual defect phải có regression assertion trên production tree trước hoặc
cùng fix. Sau repair chạy targeted widget/geometry/semantics/strict-audit tests
và inspect ảnh render thật. Clean stop khi không còn unapproved divergence hoặc
P0/P1/P2, mọi state/viewport đã xem, rect assertions pin shared geometry và báo
cáo phân biệt rõ verified, approved divergence và deferred emulator IT.
