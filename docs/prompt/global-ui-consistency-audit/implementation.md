# Global UI consistency audit

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa có kiểm soát những drift UI toàn app sau nhiều feature, không redesign sản phẩm |
| **Scope** | Shared shell, Tier-0/Tier-1 usage, tokens, spacing, typography, surfaces, actions, states và representative production screens |
| **Source of truth for** | Hướng dẫn repo-wide UI audit; design-system contracts và canonical screen behavior vẫn là nguồn sự thật |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, accepted design-system ADs, shared widget catalog, wireframes và gallery hiện tại |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Đây là audit có auto-fix, không phải lời mời làm lại mọi màn. Chỉ sửa drift có evidence;
không thay business behavior, information architecture, global typography scale hoặc màu
brand đã duyệt.

Làm việc trên **worktree sạch** tạo từ latest `origin/main`; ghi baseline và `git status`.
Không reset/force-push, không chạm dirty worktree khác và không merge PR khi owner chưa yêu cầu.

## 5Why

Từ inventory/render hiện tại, viết 5Why cho: nguồn drift, vì sao local golden không bắt,
boundary shared nào thiếu/được bypass, cách tránh mass churn và success signal nào cho phép
refactor. Mỗi Why phải mở khóa một quyết định cụ thể.

## Inventory và phân lô

1. Resolve raw Material/Cupertino policy widgets, hardcoded visual decisions, ad-hoc
   surfaces/actions/input/chips và duplicated product patterns.
2. Phân loại: true defect; approved exception; design-system gap; false positive.
3. Lập before screenshots/rects cho Library, Card List/Detail/Editor/Import/Export, Study,
   Progress, Search, Tag, Trash, Settings/Reminder.
4. Sửa theo foundation → shared component → feature caller. Không tạo Mx wrapper chỉ rename/
   forward; shared type phải sở hữu visual/state/semantics/responsive policy thật.
5. Chia commit theo coherent cluster; không đụng behavior/data chỉ để giảm diff.

## Consistency contract

- Screen gutter/shared edges, surface ladder, radius/elevation, section rhythm và bottom
  safe area dùng canonical helpers/recipes.
- Một strong primary CTA mỗi region; destructive/secondary/tonal phân cấp đúng.
- Text dùng semantic styles; không raw fontSize/weight/color, không giảm global font.
- State loading/empty/error/disabled/selected/focus/pressed có non-color cues và stable geometry.
- Feature dùng Mx policy components; primitives layout vẫn được dùng trực tiếp.

## Verification và delivery

Thêm guard/test tại root cause, không snapshot toàn source mong manh. Pin representative
geometry ở 320@2.0/393/412, light/dark EN/VI, shared component state matrix và gallery.
Changed gate sau từng cluster; full gate cuối. Không emulator nếu chỉ presentation/shared
visual refactor; ghi status. Regenerate all affected goldens `TZ=UTC`, inspect diff,
publish existing gallery. Commit/push, mở non-draft PR, không merge.

Clean stop khi inventory được triage hết, không P0/P1/P2, no unapproved visual drift,
shared APIs không phình raw visual params, full gate/goldens xanh và owner có gallery.
