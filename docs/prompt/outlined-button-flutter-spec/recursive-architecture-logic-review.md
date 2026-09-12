# Recursive Architecture and Logic Review — OutlinedButton

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập audit và auto-fix mọi sai lệch business-rule/role-contract phát sinh từ việc đối chiếu `OutlinedButton`/`MxActionButton.secondary` với component contract của kit, và xác nhận không hợp đồng đóng băng nào bị mở lại |
| **Scope** | `buildOutlinedButtonTheme`, `MxActionButton` (nhánh `secondary`), role-binding/guard test liên quan, `docs/wbs.md` dòng ghi nhận kết quả; không redesign token hay palette |
| **Source of truth for** | Quy trình recursive architecture/logic review của prompt set OutlinedButton |
| **Depends on** | `implementation.md` (cùng thư mục), latest `origin/main`, `docs/design-system/v1-freeze.md`, `test/core/theme/contracts/m3_role_bindings.dart`, `.claude/skills/flutter-theme-design/references/buttons-actions.md` §16 |
| **Updated by task** | OutlinedButton Flutter handoff spec |
| **Last updated** | 2026-09-12 |

---

Bạn là reviewer độc lập. Bắt đầu sau khi implementation phase (theo
`implementation.md`) báo hoàn tất. Re-read worktree hiện tại từ đầu — không dựa
vào implementation report như bằng chứng đã đủ; nếu report nói "không sửa code",
tự verify lại bằng cách chạy test, không chỉ tin lời report. Review này là
**audit-only ở pass đầu**: liệt kê finding trước, auto-fix trong scope sau, chạy
lại verification rồi lặp đến clean-stop. Report-only không đủ.

Không sửa song song cùng UI/UX reviewer trên cùng worktree. Cả hai audit-only
pass có thể chạy song song; khi coordinator giao lượt fix, review này áp trước
(architecture/logic), UI/UX review re-read worktree mới nhất rồi mới áp fix của
nó sau.

## 5Why audit

| Why | Rủi ro cần chứng minh | Quyết định review |
|---|---|---|
| 1 | Implementation phase có thể đã đổi border role sang `outlineVariant` để "khớp kit" mà không nhận ra đó là mở một hợp đồng đóng băng | Xác nhận `m3_role_bindings.dart` cho `OutlinedButton.side` vẫn `requires: ['outline', 'primary']`, `refuses: ['outlineVariant']`, và test tương ứng còn xanh |
| 2 | "Không cần sửa code" trong report có thể là kết luận không kiểm chứng, không phải kết quả chạy test thật | Tự chạy lại năm suite mà `implementation.md` liệt kê, không tin report suông |
| 3 | Một fix nhỏ (nếu có) cho một suite đỏ có thể vô tình đổi `MxActionButtonVariant`, thêm tham số `Color`/`borderColor`, hoặc tạo widget song song | Đối chiếu public API của `MxActionButton` trước/sau; fail nếu API mở rộng ngoài phạm vi đã khai |
| 4 | Khối test bị TOKYO-2/M100.84 comment có thể bị vô tình bật lại hoặc viết đè trong lúc "tiện tay sửa" | Diff phải KHÔNG chạm các khối `/* ... */` mang tag `TOKYO-2`; nếu chạm, coi là scope violation |
| 5 | Dòng ghi vào `docs/wbs.md` có thể không phản ánh đúng đã sửa code hay chỉ xác nhận | Đối chiếu chính xác nội dung dòng WBS với git diff thật của PR |

## Audit pass 1 — nguồn và phạm vi diff

1. Sync `origin/main`, ghi `git status`/base SHA; không merge/rebase khi chưa
   được coordinator cho phép giữa lúc audit.
2. Đọc `implementation.md`, `docs/design-system/v1-freeze.md` §2 (đặc biệt dòng
   1, 2, 6, 13) và §3, `buttons-actions.md` §16.
3. So diff implementation với `origin/main`: liệt kê mọi file bị chạm. Fail nếu
   có file ngoài `app_button_themes.dart`, `mx_action_button.dart`, test tương
   ứng, và `docs/wbs.md` — trừ khi implementation report chứng minh cụ thể vì
   sao cần chạm thêm file và điều đó không mở rộng nghiệp vụ.
4. Xác nhận không domain/data/repository/controller/BR/UC/navigation/copy nào
   đổi. Đây là task presentation/theme thuần; bất kỳ đổi nào ở layer khác là
   scope violation phải revert hoặc báo blocker.

## Audit pass 2 — role-contract và hợp đồng đóng băng (business-rule parity)

Đây là phần "nghiệp vụ" của một component design-system: role nào ánh xạ vào
đâu là **luật**, không phải thẩm mỹ, và `v1-freeze.md` §2 là BR-tương-đương của
tầng theme. Chứng minh (không suy đoán):

- `test/core/theme/contracts/m3_role_bindings.dart`: binding của `OutlinedButton`
  (`foregroundColor` → `requires: ['primary']`, `refuses: ['secondary',
  'onSurfaceVariant']`; `side` → `requires: ['outline', 'primary']`, `refuses:
  ['outlineVariant']`) còn nguyên văn, chưa bị nới `refuses` hay xoá invariant;
- `flutter test test/core/theme/contracts/m3_role_contract_test.dart` xanh —
  đây là bằng chứng máy-kiểm rằng role không bị đổi, không phải đọc code bằng
  mắt;
- không dòng nào trong `v1-freeze.md` §2 bị sửa nội dung. Nếu implementation
  report đề xuất sửa một dòng ở §2, đó là vi phạm §3 (cấm task feature/component
  tự mở hợp đồng đóng băng) — auto-fix bằng cách revert, không bằng cách hợp
  thức hoá thay đổi;
- disabled label vẫn đọc `semantic.onDisabled` (alpha ~38%, `AppColors.
  onDisabledLight/Dark`) và disabled border vẫn đọc `semantic.disabledSurface`
  — hai role "disabled chung" của mọi button, không bị tách riêng cho
  `OutlinedButton` theo kiểu tạo ngoại lệ.

Đây cũng là "invariant" cần prove theo nghĩa hẹp của task này: **prove** rằng
guard/test ở trên vẫn refuses đúng giá trị bị cấm — không có double-count nào
giữa "role đổi" và "chỉ đổi giá trị trong cùng role" (retune trong role vẫn hợp
lệ theo §2 dòng 2; đổi sang role khác thì không).

## Audit pass 3 — component responsibility và API closure

- `MxActionButton.secondary` vẫn dùng chung `buildSharedButtonStyle` (geometry,
  padding, radius, typography) với `primary`/`tonal`/`destructive` — không tự
  khai một geometry riêng;
- không tham số mới cho phép caller truyền `Color`/`BorderSide`/`borderColor`
  vào `MxActionButton` — kiểm public constructor của `MxActionButton` bằng cách
  đọc resolved signature, không chỉ đọc tên tham số;
- không class `MxOutlinedButton` hay export `OutlinedButton` trần mới nào được
  thêm vào `lib/shared/widgets/` hay bất kỳ feature nào;
- guard `no_raw_button` (v1-freeze.md §2 dòng 13) vẫn pass repo-wide — chạy
  guard suite, không chỉ tin implementation report.

## Audit pass 4 — persistence và failure handling

Task này **không chạm persistence**: đây là theme/presentation-only, không
domain/data/DB/schema/migration/query/transaction nào được phép đổi. Xác nhận:

- diff không chạm bất kỳ file nào dưới `lib/features/*/data/`,
  `lib/features/*/domain/`, hay bất kỳ `.drift` nào;
- không repository/DAO/use case nào bị import mới vào
  `app_button_themes.dart` hay `mx_action_button.dart`;
- không failure/exception path nào bị đổi — component này không catch, không
  swallow và không tạo `Failure` mới; nếu implementation report nhắc tới bất kỳ
  thay đổi persistence/database/transaction/query/mutation nào, đó là scope
  violation, coi như failure của audit và phải revert.

Nếu audit này tìm thấy bất kỳ chạm nào vào persistence, đó là auto-fix bằng
cách loại bỏ thay đổi đó khỏi PR, không phải bằng cách biện minh cho nó.

## Audit pass 5 — TOKYO-2 boundary

- Diff KHÔNG được mở lại (uncomment) khối `/* ... */` mang
  `// TODO(M100.84): colour gate off for the Tokyo palette swap — re-enable.
  (TOKYO-2)` trong `mx_action_button_state_matrix_test.dart` hay bất kỳ file
  nào khác;
- nếu implementation report đề xuất bật lại khối đó "vì tiện", đó là scope
  creep vào một task cross-cutting khác (tokyo-palette-plan) — auto-fix bằng
  cách giữ nguyên trạng thái comment, ghi lại vào review report thay vì tự
  quyết định số phận của TOKYO-2.

## Auto-fix loop

Cho mỗi finding từ pass 1–5:

1. Ghi severity, file:line chính xác, cách tái hiện (lệnh test cụ thể) và điều
   khoản bị vi phạm (`v1-freeze.md` §2 dòng nào, hoặc phạm vi
   `implementation.md`).
2. Nếu finding là regression thật (một suite đỏ không giải thích được bằng
   TOKYO-2), sửa tối thiểu để xanh lại — không đổi role border.
3. Nếu finding là scope violation (chạm file/role/persistence ngoài phạm vi),
   auto-fix bằng cách revert phần đó, giữ lại phần trong scope.
4. Chạy lại đúng lệnh test đã dùng để tái hiện; xác nhận xanh.
5. Lặp đến khi hai vòng liên tiếp không phát sinh finding mới.

Nếu một finding đòi đổi role ngữ nghĩa đã đóng băng hoặc đổi business
behavior, dừng và báo blocker cho coordinator — không tự quyết mở hợp đồng.

## Verification

Inner loop sau mỗi auto-fix:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Chạy lại đầy đủ năm suite liệt kê trong `implementation.md` mục "Việc phải
làm" bước 2. Reviewer không claim clean nếu chỉ một phần suite được chạy lại.
Coordinator chạy full gate sau khi cả hai review (architecture rồi UI/UX) đã
được áp.

## Clean stop

Chỉ trả clean khi:

- `m3_role_bindings.dart`/`m3_role_contract_test.dart` xác nhận `OutlinedButton`
  vẫn refuses `outlineVariant`, requires `outline` + `primary`;
- không dòng nào của `v1-freeze.md` §2 bị sửa;
- không file persistence/domain/data nào bị chạm;
- khối TOKYO-2 trong `mx_action_button_state_matrix_test.dart` còn nguyên
  trạng thái comment;
- năm suite của `implementation.md` xanh;
- `docs/wbs.md` có đúng một dòng phản ánh chính xác PR đã sửa code hay chỉ xác
  nhận;
- changed gate xanh;
- report liệt kê finding đã auto-fix (nếu có), lệnh test đã chạy và kết quả —
  không ghi blanket "pass" thiếu bằng chứng.
