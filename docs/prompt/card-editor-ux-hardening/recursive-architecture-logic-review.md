# Recursive Architecture and Logic Review — Card Editor Concept Parity

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa regression về editor-context read, mutation ownership, dirty state, dual Save, exit guard, Tag/Flag và Trash sau khi áp concept mới |
| **Scope** | Diff Card Editor concept parity, shared API tối thiểu, localization, tests và docs liên quan; không thiết kế lại Create/Card Detail/Card List/Study |
| **Source of truth for** | Quy trình recursive architecture/logic review Card Editor concept parity |
| **Depends on** | `docs/prompt/card-editor-ux-hardening/implementation.md`, BR-07…BR-10, BR-92…BR-95, BR-163, BR-239…BR-246, BR-256…BR-267, UC-04, UC-19, UC-21, wireframe M4.11 |
| **Updated by task** | Card Editor concept-parity prompt |
| **Last updated** | 2026-08-27 |

---

Chạy trong latest worktree sau implementation. Đọc lại đầy đủ `CLAUDE.md`,
`docs/document-conventions.md`, implementation prompt, các BR/UC ở header,
wireframe M4.11, production code, tests và latest diff. Concept image là visual
evidence, không phải nguồn business rule. Không commit, push, tạo PR hoặc merge.
Không revert thay đổi ngoài scope của session khác.

Review này gồm một pass `AUDIT_ONLY`, một pass `APPLY_FIXES`, rồi lặp lại từ đầu
cho tới clean stop. Không sửa trong pass audit-only và không đưa nhận xét chung
chung kiểu “looks good”. Mỗi finding phải có severity, file/line, scenario,
expected/actual, root cause và regression test có thể tái hiện.

## Pass 1 — `AUDIT_ONLY`

### A. Editor context và dependency boundaries

1. Xác minh card snapshot, deck name/path và route deck id không được ghép thành
   những snapshot mâu thuẫn trong widget. Nếu có editor-context query mới, nó là
   một read/use case/repository contract rõ, SQL ở `.drift`, mapper ở data và UI
   không thấy Drift type.
2. `card.deckId != route deckId`, card/deck tombstoned hoặc deck không tồn tại
   phải surface typed failure và không render sai context. Không có query N+1,
   repository read trực tiếp từ controller/widget hay cross-feature presentation
   import.
3. Breadcrumb/deck context chỉ đọc. Không có mutation deck, dropdown giả hoặc
   move-card path được lén thêm vào screen.
4. Lối History, nếu có, chỉ điều hướng bằng route constants tới Card Detail hiện
   có. Editor không đọc toàn history, không tự tính recall/accuracy/streak và
   không ghi dữ liệu khi mở link (BR-239/BR-243).

### B. Content Save và dirty state

5. Save gọi đúng một update interaction với đúng năm content field. Nó không
   chạm study state/history, flag, tags, deck type, scheduler hoặc generation.
6. Top Save và footer Save dùng một command coordinator, một canSave source và
   một double-submit guard. Tapping nhanh hai nút không tạo hai writes; loading
   không sinh hai spinners/status operations.
7. Baseline thuộc đúng card snapshot. Prefill không dirty; năm field đều được
   tính; sửa-rồi-revert pristine; disclosure/scroll/focus không dirty; provider
   rebuild không reset draft hoặc baseline.
8. Save failure giữ text, dirty, focus/scroll hợp lý và không pop. Save success
   cho phép đúng một programmatic pop mà PopScope không nuốt hoặc mở confirm.
9. Validation vẫn từ value object/domain constants BR-07/08/95. UI không tạo
   một trim/max-length rule thứ hai và counter không trở thành nguồn rule.

### C. Exit coordination

10. Back arrow, bottom Cancel và system back đi qua đúng một coordinator.
    Pristine pop ngay; content dirty hoặc unsubmitted tag draft mở đúng một
    confirm; Keep editing giữ draft; Discard pop đúng một; submit in-flight
    không rời màn.
11. Không có dialog re-entry, double pop, callback sau dispose, listener leak,
    `setState` trong build, stale bypass flag hoặc race khi card provider reload.
12. Tag đã commit và Flag đã commit không bị “undo” khi Discard content; chúng
    là mutations riêng và feedback riêng.

### D. Tag và Flag

13. Tag add/remove vẫn immediate qua controller/use case. Add chip, suffix Add
    và IME submit hội tụ vào một command; blank/full/busy không write; failure
    giữ draft; success mới clear/collapse.
14. Tag draft chưa submit chặn exit nhưng không bật Content Save. Cap 10 được
    domain enforce; UI chỉ preflight, không nới hoặc duplicate rule.
15. Flag toggle vẫn theo BR-92: typed command, failure giữ committed state,
    system không tự tắt cờ; nó không tham gia Content Save/dirty.

### E. Trash/delete correctness

16. Editor action vẫn soft-delete qua flow hiện có, tạo batch, giữ content/
    study state/history/tag tới purge, đóng session liên quan và áp BR-163/260
    trong repository transaction. Không có hard delete.
17. Confirmation, route fallback và Undo dùng batch id thật. Xoá card cuối
    không điều hướng về một Card List không còn hợp lệ.
18. Copy không nói history mất hoặc delete vĩnh viễn. Soft-delete action không
    dùng destructive role bị BR-266 dành cho purge; đây là semantic contract,
    không chỉ review màu.

### F. Shared API, docs và scope

19. `MxContentShell`, `MxTextField`, `MxActionButton`, `MxIconButton`,
    `MxBreadcrumb` giữ backwards compatibility: API mới typed, default không
    đổi, không feature import/business logic, không arbitrary `Color`, padding,
    decoration hoặc breakpoint.
20. Footer slot không làm Create mode/caller khác đổi Scaffold behavior. Input
    variant/counter mode không đổi default gần-limit của screen khác.
21. ARB EN/VI đầy đủ, generated output đồng bộ, không hardcode copy. Wireframe
    ghi supersession và soft-delete parity; không sửa frozen BR/UC để hợp thức
    hoá code.
22. Không thêm mic/TTS/plugin/permission, recall metric, deck picker, scheduler
    change, schema migration hoặc scope creep sang Card Detail/List/Study.
23. Test dùng production route/screen seam đủ mạnh: fake repository đếm writes,
    route harness chứng minh pop/navigation/Undo, shared defaults có regression
    tests. Golden xanh không được dùng thay logic test.

## Pass 2 — `APPLY_FIXES`

Sau khi đóng băng báo cáo audit-only, xử lý P0 → P1 → P2 tuần tự:

1. thêm test đỏ tái hiện scenario;
2. sửa nhỏ nhất tại layer sở hữu;
3. chạy targeted test qua gate repo;
4. re-read latest worktree trước finding tiếp theo;
5. chạy lại toàn bộ `AUDIT_ONLY` từ đầu.

Không chữa visual state bằng mutation mới; không gom Tag/Flag vào Content Save;
không đưa dirty logic vào domain/repository; không bỏ PopScope để làm test pop
xanh; không hard-delete hoặc dùng destructive soft-delete để khớp ảnh; không
tính metric chưa đặc tả; không mở rộng shared API bằng style escape hatch.

## Verification và clean stop

Chạy targeted Card Editor + editor-context repository/use-case + shared component
tests trong inner loop, sau đó:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không chạy emulator; ghi `not run — scoped host verification`. Clean stop chỉ
khi một audit mới từ đầu không còn P0/P1/P2; mọi mutation count/state/route
test xanh; không stale snapshot/draft, double dialog/pop/submit hoặc wrong-layer
dependency; soft-delete/Undo đúng; shared defaults không regression; docs/l10n/
gates xanh và không còn TODO hoặc assumption không owner.
