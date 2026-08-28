# Recursive Architecture and Logic Review — Tag Catalog Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix mọi regression kiến trúc/nghiệp vụ sau restyle Tag Catalog |
| **Scope** | Tag Catalog screen, tag overlays và tests liên quan; không mở rộng tính năng tag |
| **Source of truth for** | Quy trình recursive architecture/logic review của Tag Catalog visual hierarchy |
| **Depends on** | `implementation.md`, BR-230…BR-238, UC-18, M4.14, repo guards và production tests |
| **Updated by task** | Tag Catalog visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Đóng vai reviewer độc lập. Đọc lại worktree mới nhất; không tin report của phase
implementation và không coi test cũ xanh là bằng chứng đủ.

## Phase order và worktree safety

Vòng đầu MUST là **audit-only**: đọc latest worktree, `git status` và latest diff,
tái hiện lỗi rồi lập inventory P0/P1/P2; chưa sửa file trong vòng này. Không
revert diff ngoài scope, không commit/push/PR/merge. Chỉ sau khi inventory hoàn
chỉnh mới sang repair pass, auto-fix tuần tự và chạy verification sau mỗi batch.

## Audit bắt buộc

1. Diff phải presentation-first; flag mọi thay đổi domain/data/repository/DAO,
   route, normalization, sort, count hoặc filter predicate.
2. Reproduce populated/empty/search-empty/error, rename thường, rename collision,
   validation/write error và delete 0/many-card.
3. Chứng minh BR-230…BR-238 vẫn đúng: library scope, folded search/sort, zero tag,
   rename giữ ID, merge/delete atomic và không đụng card/study data.
4. Kiểm tra state ownership: widget chỉ render/callback; không business logic,
   `ref.read` trong build, duplicate draft hoặc swallowed failure.
5. Kiểm tra shared boundary: không raw policy-bearing Material component khi có
   `Mx*`; không trivial shared wrapper hoặc local visual token.
6. Kiểm tra l10n, typed failures, focus lifecycle, retry đúng command và không
   log private card/tag content.
7. Rerun targeted tests và changed gate; thiếu test cho regression cụ thể phải
   thêm test trước khi sửa.

## Recursive auto-fix

- Ghi finding theo severity với file/line, kịch bản tái hiện, expected/actual và
  BR/UC liên quan.
- Auto-fix mọi finding trong scope theo thứ tự P0 → P1 → P2; không chỉ report.
- Sau mỗi batch, đọc lại diff, chạy tests liên quan và lặp audit từ đầu.
- Không sửa frozen docs hoặc nới nghiệp vụ để làm test xanh.

Clean stop chỉ khi không còn P0/P1/P2, mọi face có bằng chứng, changed gate xanh,
diff không đổi business/data/navigation và report nêu rõ emulator không chạy vì
presentation-only. Reviewer này không update golden/gallery và không tạo PR.
