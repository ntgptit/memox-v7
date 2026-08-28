# Gallery confirmation and shared-pattern cleanup

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đóng chiến dịch UI bằng gallery trung thực và cleanup các pattern lặp đã được chứng minh, không redesign |
| **Scope** | Affected demo goldens, screen gallery, duplicate presentation patterns, shared ownership, docs/WBS traceability và delivery PR |
| **Source of truth for** | Hướng dẫn gallery/cleanup execution; UI behavior vẫn thuộc canonical screens/wireframes/components |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, latest merged UI PRs, Widgetbook/shared catalog và existing Artifact URL |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Task này chỉ chạy sau các UI task liên quan đã merge/rebase vào branch. Không tạo component
chỉ vì hai đoạn code trông giống nhau; extraction cần ít nhất pattern lặp có cùng semantic,
state và geometry policy hoặc design-system owner rõ.

## 5Why

Viết 5Why cho stale gallery risk, duplicate-pattern root cause, tiêu chí shared admission,
vì sao cleanup sau merge an toàn hơn trước và evidence nào chứng minh zero degradation.

## Preflight và inventory

- Worktree sạch từ latest `origin/main`; ghi baseline SHA và danh sách UI PR đã hiện diện.
- Build gallery hiện tại trước sửa và đối chiếu commit stamp, file inventory, 393×852 rule,
  duplicate names và stale/missing screen states.
- Inventory duplicate composition theo semantic contract, không chỉ text similarity. Phân
  loại extract/shared, keep feature-owned, remove dead, hoặc blocker.

## Cleanup contract

- Shared component phải sở hữu visual/state/semantics/responsive policy; không forward raw
  visual params, không feature model/import, không barrel/typedef alias.
- Migrate callers giữ callbacks, focus, disabled/loading geometry và pixels trừ approved fix.
- Không thay global tokens để làm nhiều golden “đồng bộ”; root cause phải cụ thể.
- Gallery chỉ nhúng canonical 393×852 demo states; stress widths ở tests, không thêm vào `SCREENS`.
- Regenerate với `TZ=UTC`; build từ committed-equivalent goldens, inspect every changed image,
  publish đúng existing Artifact URL, không tạo gallery thứ hai.

## Verification và delivery

Thêm shared API/behavior tests và before/after geometry assertions cho migrated callers.
Changed gate theo cluster, full gate cuối. Không emulator cho cleanup presentation-only;
ghi status. Commit validated result, republish gallery, push và mở non-draft PR. PR body có
before/after inventory, extracted/kept decisions, recursive reviews, gate, emulator status
và gallery URL. Không merge trước owner visual confirmation.

Clean stop khi gallery stamp đúng HEAD, mọi PNG đúng size/state, no stale/missing entry,
shared APIs có policy thật, zero unapproved pixel/behavior drift, full gate xanh và PR ready.
