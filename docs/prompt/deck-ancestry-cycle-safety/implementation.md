# Deck ancestry cycle safety

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chặn `childDeckLevel` giữ database isolate vô hạn khi parent chain bị cyclic, không đổi nghiệp vụ Deck hợp lệ |
| **Scope** | Deck Drift ancestry query, boundary truyền max walk, SQLite tests, comment và WBS technical debt |
| **Source of truth for** | Hướng dẫn trả khoản nợ ancestry CTE; BR-55/BR-69/AD-13 vẫn là nguồn nghiệp vụ |
| **Depends on** | `CLAUDE.md`, `docs/business-rules.md`, `docs/architecture.md`, `docs/data-model.md`, `docs/wbs.md`, Deck README |
| **Updated by task** | Terra bounded-data campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là implementation coordinator trên worktree sạch từ latest `origin/main`. Không
đổi UI, aggregate semantics, navigation, schema version hoặc generated files bằng tay.

## 5Why bắt buộc

1. `ancestry(deck_id, distance)` làm mỗi vòng cycle thành row mới dù dùng `UNION`.
2. Query treo giữ Drift isolate, nên lỗi một breadcrumb chặn mọi database consumer.
3. Dữ liệu production hợp lệ sâu tối đa 10 nhưng corrupt/migrated data vẫn phải fail bounded.
4. `progress.drift` đã có bounded-walk precedent; thêm framework mới là thừa.
5. Test giá trị trên cây sạch không thể chứng minh termination; phải fault-inject cycle trên SQLite thật.

Ghi evidence/trade-off/decision cho từng Why trước edit.

## Implementation contract

- Inventory `childDeckLevel`, generated invocation, DAO/repository mapper và bounded
  ancestry precedent trong `progress.drift`.
- Thêm named parameter `:maxWalk` chỉ cho ancestry CTE mang counter. Giữ `UNION` cho
  walks không mang counter và không thay `branch` semantics.
- Giá trị caller phải xuất phát từ domain limit (`DeckEntity.maxTreeDepth` với guard
  step hợp lý), không hardcode rải rác và không đọc wall clock.
- Legal chain tới root trong giới hạn phải trả cùng breadcrumb IDs/names/distance/order
  như baseline. Cycle hoặc chain vượt bound phải kết thúc hữu hạn; không invent deck.
- Sửa comment đang nói sai rằng `UNION` tự deduplicate row có distance tăng.
- Không bump schema: đây là named-query/runtime boundary, không thay table/index.
- Không sửa BR để khớp code. Nếu canonical docs yêu cầu outcome khác, dừng và báo blocker.
- Allocate WBS ID trên latest main và đánh dấu đúng known debt đã trả; không xoá lịch sử.

## Tests bắt buộc

Trên database production schema thật:

- root/level 2/level 10 trả ancestry đúng và ổn định;
- corrupted two-node và longer parent cycle hoàn tất trong timeout test hợp lý;
- ngay sau cycle read, một query database khác vẫn trả về để chứng minh isolate không kẹt;
- chain vượt max walk bounded;
- child aggregates, `nextDueAt` và ordering không đổi trên fixture sạch;
- boundary/source test chứng minh query có `:maxWalk` và caller không dùng magic literal.

Test phải đỏ khi bỏ predicate bound hoặc ngừng truyền max walk. Không dùng mock để
chứng minh SQL termination.

## Verification và delivery

- Inner loop và final consolidated gate theo `CLAUDE.md`; regenerate code bằng workflow
  repo, không edit generated output.
- Không emulator/golden/gallery regeneration: data-query fix không có visual delta.
- Rebase/merge latest main trước final gate. Merge task này trước
  `deck-write-move-ux-hardening` để tránh cùng ownership Deck.
- Commit nhỏ, push branch, non-draft PR với reproduction trước/sau, tests, gate và
  no-visual-delta evidence. Không merge nếu user chưa yêu cầu session này.

## Clean stop

Cycle không thể treo statement, legal breadcrumbs/aggregates giữ nguyên, regression
test đỏ trên defect cũ, full gate xanh và WBS debt được đóng có trace.
