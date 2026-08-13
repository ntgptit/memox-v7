# Recursive architecture and logic review — Card Export

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập kiểm toán và auto-fix kiến trúc, nghiệp vụ, persistence và tests của Card Export |
| **Scope** | Card Export và ranh giới Card Transfer liên quan; không review visual fidelity |
| **Source of truth for** | Prompt recursive architecture/logic review Card Export |
| **Depends on** | `docs/prompt/card-export/implementation.md`, các BR/AD/UC/wireframe Card Export trong repo |
| **Updated by task** | User-requested prompt workflow update |
| **Last updated** | 2026-08-13 |

---

Hãy recursive review và auto-fix Card Export trong
`D:\workspace\memox-v7` như một phiên độc lập. Không tin PR description, tests
hiện có hoặc lời khẳng định `pass`; tái dựng yêu cầu từ docs và tìm
counterexample thực tế.

## Chế độ chạy dưới coordinator

Nếu coordinator chạy prompt này song song với UI/UX reviewer, lượt đầu tiên là
**audit-only**:

- đọc source-of-truth và latest worktree;
- reproduce vấn đề, chạy read-only/targeted diagnostics và lập findings;
- không sửa file, không format và không regenerate golden;
- gửi findings cùng reproduction/test cần thêm cho coordinator rồi pause.

Chỉ bắt đầu auto-fix khi coordinator gửi follow-up rõ ràng sau khi cả hai audit
song song đã hoàn tất. Khi nhận follow-up, đọc lại `git status`, diff và các file
liên quan vì worktree có thể đã thay đổi. Architecture/logic fixes được áp dụng
trước UI/UX fixes. Nếu không chạy dưới coordinator hoặc không có reviewer song
song, thực hiện toàn bộ audit → auto-fix loop bình thường.

## Worktree và source of truth

- Đọc `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, N1/private-data
  contract, AD-20, BR/UC Export mới, BR-51…BR-54, BR-168…BR-173, UC-04/UC-10,
  wireframe Export và Card README.
- Kiểm tra `git status`/diff; không reset, checkout hoặc ghi đè session khác.
- Chỉ auto-fix Card Export/Card Transfer trong scope. Docs thắng nếu code/test
  mâu thuẫn.

## Recursive loop

1. Dựng dependency graph production thực tế.
2. Liệt kê findings P0/P1/P2/P3 với file/line.
3. Viết/chỉnh test tái hiện finding trước khi fix khi khả thi.
4. Auto-fix finding trong scope.
5. Chạy targeted verification.
6. Đọc lại toàn diff để tìm regression/abstraction thừa.
7. Lặp ít nhất một vòng sau khi không còn finding ban đầu.

## Audit bắt buộc

### Scope và snapshot

- All có lấy toàn deck, độc lập filter/search/pagination không?
- Selected có đúng exact IDs không? ID trùng normalize chưa?
- Missing/wrong-deck selected ID có fail toàn request hay silent partial?
- Empty/missing deck có typed failure?
- Selection có bị clear ngoài ý muốn không?
- Có export descendant/card ngoài deck không?
- Deck name/content/tags có cùng snapshot, tránh N+1 không?
- Card/tag ordering có deterministic không?
- Có mutation timestamp/content type/state/history không?

### Round-trip counterexamples

Tạo fixture gồm Hangul, tiếng Việt, `001`, `1e3`, `+84`, comma, semicolon,
tab, quotes, CRLF, embedded newline, optional empty, tags chứa `;` và `\`,
cùng XLSX text bắt đầu `=`, `+`, `-`, `@`.

Với CSV, TSV và XLSX: production encoder → production decoder → production
mapping → compare sáu fields và tags. Không dùng helper decoder của chính
encoder làm oracle. Kiểm Import legacy tags không regression và shared tag codec
chỉ có một owner.

### Content-only boundary

Source scan và tests phải chứng minh artifact không chứa ID, deck ID, timestamps,
flag, scheduler/version/generation, box/ease/interval/due, learned state,
history hoặc session data.

### Strategy và layering

- Không `ImportExportFactory`/God Object.
- Decoder và encoder là pipeline riêng.
- Format dispatch chỉ ở resolver.
- CSV/TSV chung delimited strategy, XLSX riêng.
- Domain không import Flutter/plugin/Drift.
- Presentation không import data/share/database.
- Controller không giữ context hoặc gọi repository.
- Composition root bind đủ contracts; harness dùng binding list chung.
- Không có dead API để dành cho tương lai.

### Platform, privacy và concurrency

- `share_plus` version tương thích build.
- Dismiss là cancel; platform exception map typed Failure.
- Copy không khẳng định Saved khi OS không xác nhận.
- Không broad storage permission, private-data logging hoặc persistent export
  trước explicit action; Web vẫn build.
- Reproduce deck/card bị xóa/move, double tap, encoder failure, share
  unavailable, Back/Close khi generating và async result sau dispose.

## Test integrity

- Tests mount production classes; fakes chỉ thay external boundary.
- Fault-injection ít nhất một material defect phù hợp để chứng minh test đỏ,
  sau đó hoàn nguyên bằng patch.
- Không regenerate golden để che lỗi.
- Mỗi BR/UC branch có test owner rõ.

## Verification

- Chạy targeted tests sau mỗi nhóm fix.
- Chạy `.claude/skills/flutter-workflow/scripts/dod_check.sh`.
- Chạy `flutter test integration_test/ -d emulator-5554 --flavor development`.
- Không tuyên bố pass nếu required gate chưa chạy; báo exact blocker/command.

## Clean stop và báo cáo

Chỉ dừng khi không còn P0/P1/P2, mọi counterexample xanh ba format, DB
no-mutation được chứng minh, Import regression/architecture/docs/gates xanh và
vòng cuối không sinh finding mới.

Báo cáo theo thứ tự: findings, reproduction, root cause, files/fixes,
tests/gates và residual risks hoặc gate chưa chạy.
