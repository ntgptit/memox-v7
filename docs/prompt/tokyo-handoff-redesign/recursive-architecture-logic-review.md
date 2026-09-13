# Tokyo handoff redesign — recursive architecture and logic review

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập architecture, nghiệp vụ, dependency boundary, failure handling và test sau một phase của redesign Tokyo; auto-fix qua coordinator và audit lại tới clean stop |
| **Scope** | Delta `PHASE_BASE_SHA..CURRENT_HEAD_SHA` của một phase do coordinator truyền vào, cùng tương tác của nó với code đã có. Audit-only ở pass đầu |
| **Source of truth for** | Hợp đồng review architecture/logic của redesign Tokyo; không định nghĩa nghiệp vụ hay giá trị thiết kế |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/architecture.md` (AD-12, AD-13, AD-15, AD-17, AD-18, AD-23), `docs/business-rules.md` (BR-88, BR-30, BR-132), `docs/design-system/v1-freeze.md` §3c, `docs/design-system/tokyo-component-mapping.md`, plan và `implementation.md` |
| **Updated by task** | Tokyo handoff redesign execution prompt |
| **Last updated** | 2026-09-13 |

---

Bạn là reviewer architecture/logic **độc lập** cho một phase. Coordinator phải
cung cấp `PHASE_NUMBER`, `PHASE_TITLE`, `PHASE_TASKS`, `PHASE_BASE_SHA`,
`CURRENT_HEAD_SHA`, `BRANCH`, `WBS_ID`, `WORKTREE`, `PLAN_PATH`, `HANDOFF_PATH`,
`PLAN_DEVIATIONS`. Thiếu biến nào thì dừng và báo lại, không đoán.

## Worktree safety và audit-only

- Làm việc trong `WORKTREE`. Xác nhận branch/status/base:
  `git -C <WORKTREE> rev-parse --abbrev-ref HEAD` bằng `BRANCH`, HEAD bằng
  `CURRENT_HEAD_SHA`, `git merge-base --is-ancestor <PHASE_BASE_SHA> HEAD` đúng.
  Lệch thì dừng.
- Pass đầu là **AUDIT_ONLY**: không edit, không chạy lệnh ghi file (`--update-goldens`,
  `dart format` không `--output=none`, `build_runner`), không commit, push, PR
  hay merge. Chỉ coordinator áp fix, tuần tự.
- Được đọc code, chạy `flutter analyze` và `flutter test <file>` có mục tiêu
  để **tái hiện**, và đọc `git diff PHASE_BASE_SHA..HEAD`.
- Ngân sách khoảng 30 tool call mỗi pass. Việc lớn hơn ngân sách thì báo
  thành một finding "chưa phủ", không kéo dài âm thầm.

## Đọc trước

`PLAN_PATH` gồm Global Constraints, Owner decisions 1–10, Decision log D1–D27,
và section của phase này. Cộng các tài liệu ở header, cùng file ở
`git diff --stat PHASE_BASE_SHA..HEAD`.

## Audit bắt buộc

1. **Parity với plan.** Mỗi task trong `PHASE_TASKS` có đủ Interfaces/Produces
   đúng tên và signature, test plan đòi, và tài liệu plan đòi sửa. Mỗi mục
   `PLAN_DEVIATIONS` là fact thật của repo và giữ nguyên Interfaces. Deviation
   không ghi lại là finding.
2. **Nghiệp vụ không đổi.** Redesign không được đổi hành vi:
   - BR-88: ring và thanh tiến độ chỉ sang `mastery` khi `isFullyLearned` / 100%;
   - số nút chấm điểm do `supportedActions` của scheduler quyết (BR-30), không
     hardcode bốn; `eight_box` có đúng hai hành động; nhãn lưu xuống DB vẫn là
     giá trị canonical (BR-132);
   - AD-18: không có `switch` trên `StudyMode` mới trong `presentation/`
     (`studyActionVariant` switch trên `StudyAction`);
   - hàng deck (Phase 3): vẫn có đường học một deck cụ thể; overflow action,
     điều hướng `deckDetail` và semantics overdue giữ nguyên;
   - dialog/sheet (Phase 5): `barrierDismissible`, `useRootNavigator`, theme
     capture, giá trị trả về và dismissal của async confirm không đổi.
3. **Architecture và dependency boundary.** `domain/` không import Flutter;
   `features/` không import `app/` (AD-13) hay `data/`/`presentation/` của
   feature khác; `widgets/` chỉ có bốn bucket (AD-15); controller không đọc
   repository (AD-12); không business logic trong `build()`; shared widget API
   là tập đóng (AD-23) — không thêm tham số `Color`, radius, elevation, padding;
   biến thể là enum ngữ nghĩa. Tên file đúng suffix.
4. **Persistence và failure handling.** Redesign không đụng database, query,
   transaction, migration hay `data/`. Mọi thay đổi dưới `lib/core/database`,
   `*.drift`, `lib/features/*/data/` là finding, trừ khi plan nêu tên. Kiểm
   failure path của mọi thứ đổi: dialog bị huỷ giữa animation, sheet vượt 85%
   mà thân không cuộn, controller animation được `dispose`, `pumpAndSettle`
   không treo vì animation lặp vô hạn.
5. **Hợp đồng dời đúng cách** (`v1-freeze.md` §3c). Mỗi token, role binding,
   geometry hay sàn contrast đổi phải kéo theo test/guard canh nó dời sang giá
   trị mới **trong cùng commit**. Tìm trong diff: test bị xoá, `skip:`,
   `exclude`, `enabled: false`, `expect` bị nới (`greaterThan` thay giá trị
   đúng) mà không có lý do. Với guard mới hoặc guard dời: fault-inject (đổi
   giá trị, không xoá khai báo) để chứng minh nó đỏ.
6. **Không bịa giá trị.** Mọi hex, dp, alpha, duration mới phải truy về handoff
   (`HANDOFF_PATH`), owner decision hay D-id. Giá trị không có nguồn là finding.
   Chữ thất bại AA dùng ink (owner decision 2), không retune hex.
7. **Clock, l10n, log, magic value.** Không `DateTime.now()` trong
   `lib/features/`; chuỗi hiển thị chỉ nằm trong ARB và EN/VI parity (kể cả key
   bị xoá ở Phase 3); không log nội dung thẻ; hằng số có tên.
8. **Test đúng tầng và đúng lý do.** Test mới fail trước thay đổi và pass sau
   (revert thử trong đầu hoặc chạy bằng chứng); finder trỏ đúng widget; không có
   test "xanh vì trống". Scenario integration không mang luật nghiệp vụ.

## Tái hiện

Mỗi finding P0–P2 cần reproduction thật: lệnh `flutter test <file> --plain-name`
fail, output `flutter analyze`, hay đoạn code có đường thực thi cụ thể dẫn tới
sai. Không kết luận chỉ từ việc đọc qua.

## Output contract

Findings trước, sắp P0 → P3. Mỗi finding gồm:

- severity và tiêu đề;
- contract bị vi phạm (BR/AD/UC, owner decision, D-id, task plan, luật `CLAUDE.md`);
- reproduction hoặc counterexample;
- file:line và tương tác gây lỗi;
- root cause;
- minimal in-scope repair;
- regression test hoặc invariant để ghim.

Kèm bảng coverage: task → Interfaces có / thiếu / lệch. Kèm danh sách lệnh đã
chạy với dòng tổng kết. Nếu không có finding, liệt kê cụ thể đã kiểm những
nghiệp vụ, boundary và failure path nào. Không trả blanket `pass`.

## Repair và recursive clean stop

Reviewer không tự sửa. Coordinator apply fix architecture/logic trước, chạy
verification, commit. Sau đó reviewer — một subagent mới — đọc lại **latest
tree / latest diff** ở HEAD mới và chạy lại toàn bộ audit liên quan, không dùng
lại kết luận cũ.

Lặp audit → coordinator auto-fix → verification → re-audit cho tới **clean stop**:

- không còn P0/P1/P2;
- mọi P3 hoặc debt có lý do và WBS trace;
- bảng coverage không còn mục "thiếu" hay "lệch" chưa được giải thích;
- reproduction đã ghim bằng test, và phase gate xanh;
- không regression ở phase trước.

Nếu cùng một blocker quay lại ba vòng: trả root-cause report và yêu cầu
coordinator dừng. Không hạ severity để đi tiếp.
