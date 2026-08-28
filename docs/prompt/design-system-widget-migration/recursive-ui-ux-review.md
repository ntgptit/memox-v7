# Recursive UI/UX Review — Policy Widget Migration

| | |
|---|---|
| **Status** | active |
| **Purpose** | So sánh production states trước/sau migration, auto-fix mọi visual, interaction, responsive hoặc accessibility degradation |
| **Scope** | Affected screens/shared components, geometry, component states, semantics, goldens, Widgetbook và gallery |
| **Source of truth for** | Hướng dẫn recursive UI/UX audit migration; approved visuals vẫn thuộc wireframes, tokens, design parity checklist và concept đã được duyệt |
| **Depends on** | `docs/prompt/design-system-widget-migration/implementation.md`, latest architecture fixes, affected wireframes/goldens, MemoX shared component contracts |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Chạy sau architecture fixes và re-read latest worktree. Golden mới chỉ là
regression baseline, không phải bằng chứng parity.

## Audit-only first pass

Vòng đầu là **audit-only**: render, đo và lập danh sách approved divergence /
unapproved divergence trước, chưa sửa code hay update golden. Auto-fix chỉ bắt
đầu sau khi state matrix và geometry findings đã đầy đủ.

## Recursive visual loop

1. Liệt kê từng affected production screen và state từ diff/inventory.
2. Render real production tree ở light/dark, normal/disabled/loading/error/
   selected/open-overlay khi có.
3. So screenshot mới với approved gallery/wireframe/concept và ghi mọi divergence.
4. Đo geometry/tap target/semantics bằng widget assertions; không đo container vô
   hình thay cho surface người dùng thấy.
5. Auto-fix unapproved delta bằng token/shared component đúng owner.
6. Regenerate, inspect và lặp tới khi không còn finding.

## Visual and interaction contract

- Content gutters, shared edges, row widths, gaps, baselines và bottom action
  placement không đổi ngoài divergence được duyệt.
- Button/input/chip/menu giữ typography, density, radius, color role và
  enabled/disabled/focus/pressed/selected state.
- Inline spinner không biến thành full-state panel và không làm row nhảy size.
- Snackbar/dialog/sheet/picker giữ z-order, barrier, safe area, keyboard inset,
  dismiss/cancel affordance.
- Surface migration giữ clipping, ink, nested controls và focus ring.
- Mọi icon-only action có tooltip/semantic label và target ít nhất 48×48.
- 320px, text scale 2.0, Vietnamese long copy, keyboard-open và landscape không
  overflow hoặc che action.
- Theme-owned raw control còn lại phải nhìn cùng vocabulary ở light/dark và
  không có local style drift.

Thêm `getRect` assertions cho material relationships thực sự có nguy cơ đổi;
không snapshot mọi pixel bằng số cứng.

## Verification and delivery

Sau auto-fix chạy changed gate, goldens với `TZ=UTC`, build gallery, inspect
state-by-state và full gate. Publish lại existing Artifact URL. Chỉ clean khi
không unapproved divergence, a11y/geometry tests xanh và gallery phản ánh commit
đã validate.

## Clean stop

Clean stop chỉ đạt khi recursive rerun không sinh finding mới, mọi unapproved
divergence đã được auto-fix, `getRect`/a11y/golden evidence xanh và gallery đúng
commit đã qua full gate.
