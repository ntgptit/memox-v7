# Recursive Architecture and Logic Review — Card Editor UX Hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa regression về ownership mutation, dirty state, exit guard, delete flow và architecture sau khi sửa Edit flashcard |
| **Scope** | Diff Card Editor UX hardening, shared shell/control API, localization, tests và docs liên quan; không thiết kế lại Card/Create/Study |
| **Source of truth for** | Quy trình recursive architecture/logic review Card Editor UX hardening |
| **Depends on** | `docs/prompt/card-editor-ux-hardening/implementation.md`, BR-07…BR-10, BR-92…BR-95, BR-163, BR-256, UC-04, wireframe M4.11 |
| **Updated by task** | Card Editor UX hardening prompt |
| **Last updated** | 2026-08-26 |

---

Chạy trong worktree đã hoàn tất implementation. Đọc lại `CLAUDE.md`,
`docs/document-conventions.md`, implementation prompt, các BR/UC ở header,
wireframe M4.11, production code, tests và **latest diff**. Không commit, push,
tạo PR hoặc merge. Không revert thay đổi ngoài scope của session khác.

## Pass 1 — `AUDIT_ONLY`

Chỉ tái hiện và báo finding có severity, file/line, scenario, expected/actual và
bằng chứng test; chưa sửa. Chứng minh từng invariant:

1. Save vẫn gọi đúng một `UpdateCardUseCase` với năm field, không chạm study
   state/history, flag, tags, deck type, scheduler hoặc route ngoài pop thành công.
2. Tag add/remove và Flag toggle vẫn là mutation tức thì qua controller riêng;
   chúng không bị gom vào Save, không bị rollback khi discard content và không
   thay content dirty.
3. Draft Add tag chưa submit được bảo vệ khi rời màn nhưng không bật Save. Sau
   add thành công draft clear; sau failure draft giữ nguyên.
4. Content dirty dựa trên snapshot ban đầu của đúng card; prefill không làm dirty,
   sửa-rồi-revert về pristine, disclosure toggle không dirty, năm field đều được
   tính và không có duplicated validation/business rule ở UI.
5. Close và system Back đi cùng một coordinator. Pristine pop một lần; dirty mở
   đúng một confirm; Keep editing không mất state; Discard pop một lần; save
   success không bị PopScope bắt lại; submit in-flight không rời màn.
6. Không có race do controller listener, `setState` trong build, callback sau
   dispose, dialog re-entrancy, double submit, double pop hoặc stale baseline khi
   provider/card rebuild.
7. Delete vẫn soft-delete theo BR-256, dùng confirm hiện có, giữ Undo batch,
   route fallback và source/destination content type behavior; thay visual
   variant không tạo hard delete hay bỏ confirm.
8. Tag cap 10 vẫn enforced bởi domain và UI chỉ preflight. Suffix Add và IME
   submit gọi cùng command; blank/full/busy không sinh write; failure typed giữ
   nguyên.
9. Shared `MxContentShell`, `MxActionButton`, `MxTextField`, `MxIconButton` giữ
   backwards compatibility: optional API default không đổi, không business logic,
   không arbitrary `Color`, `InputDecoration` hoặc feature import.
10. ARB có đủ EN/VI, không hardcode copy; generated localization đồng bộ; key
    `Danger zone` chỉ bị xóa khi không còn caller; docs mới ghi supersession rõ
    chứ không xoá lịch sử.
11. Create mode và các screen dùng shared components không đổi behavior/pixel do
    default mới; không có scope creep sang Card Detail/List/Import/Study.
12. Test không mock mất production seam: route harness thật cho PopScope/save/
    delete; providers/repository fake ghi được số mutation; style test không được
    dùng thay logic test.

Golden mới xanh không phải bằng chứng logic đúng. Tái hiện mỗi failure bằng
targeted regression đỏ trước khi báo finding.

## Pass 2 — `APPLY_FIXES`

Sau khi đóng băng báo cáo audit-only, xử lý P0 → P1 → P2 tuần tự:

1. thêm/sửa test tái hiện;
2. sửa nhỏ nhất tại layer sở hữu;
3. chạy targeted test;
4. re-read latest worktree trước finding kế tiếp;
5. chạy lại toàn bộ audit-only từ đầu.

Không chữa UI state bằng mutation mới, không chuyển tag/flag sang submit chung,
không đưa dirty logic vào repository/domain, không bỏ guard để làm test pop xanh,
không đổi business rule/copy hậu quả delete để khớp snapshot.

## Verification và clean stop

Chạy targeted Card Editor + shared component tests, sau đó:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator; ghi rõ `not run — scoped host verification`. Clean stop chỉ
khi một audit mới từ đầu không còn P0/P1/P2; mutation count/state/route tests
xanh; không stale draft, double dialog/pop/submit hoặc cross-layer import; shared
defaults không regression; docs/l10n/gates xanh và không còn TODO không owner.

