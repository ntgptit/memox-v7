# Recursive Architecture and Logic Review — Progress Overview v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa đệ quy kiến trúc, metric semantics, persistence và lifecycle của Progress Overview |
| **Scope** | Docs, domain, Drift query, DI, controller, router integration và tests của Progress Overview |
| **Source of truth for** | Quy trình recursive architecture/logic review Progress Overview v1 |
| **Depends on** | `docs/prompt/progress-v1/implementation.md`, canonical BR/UC/AD/data model/wireframe trên branch |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Review production diff của Progress Overview, không review prompt theo trí nhớ.
Đọc lại `CLAUDE.md`, document conventions, canonical docs đã đổi, feature
blueprint, Deck/Card README, Study write path và toàn bộ changed files/tests.

## Execution mode

- Khi coordinator truyền `AUDIT_ONLY`, tuyệt đối không edit. Reproduce findings,
  ghi severity, file:line, violated rule, scenario và fix boundary.
- Khi chạy standalone hoặc coordinator truyền `APPLY_FIXES`, tự sửa findings
  trong scope, chạy targeted verification, đọc lại diff và lặp đến clean stop.
- Không reset/revert diff người khác; không commit/push/PR/merge. Nếu cần sửa
  forbidden/shared surface ngoài scope, báo coordinator bằng concrete dependency.

## Invariants phải chứng minh

1. Query đếm distinct card-day, không đếm answer rows; Learning ưu tiên và
   partition cộng đúng total.
2. Local-day dùng injected now/offset thống nhất; không `DateTime.now()` hoặc
   host timezone ẩn.
3. Browse không tạo activity; reset giữ history; Trash/hard-delete không để
   deleted card xuất hiện.
4. Live stream invalidates đúng bảng; midnight/offset refresh one-shot,
   dispose-safe, không loop hoặc subscription thủ công.
5. Không persistent aggregate/N+1/raw-history grouping trong presentation.
6. Dependency flow là presentation → use case → domain contract ← data; UI
   không biết Drift/repository, domain không biết Flutter.
7. Route/path/name/branch giữ ổn định; mở Progress không mutation DB.
8. Migration/index chỉ tồn tại khi benchmark và schema docs/tests đầy đủ.

Tạo hoặc bổ sung test tái hiện trước mỗi fix logic. Dùng real in-memory SQLite
cho query, transaction và stream; fake domain contract cho controller/widget.
Kiểm tra generated inputs nhưng không edit generated outputs. Chạy targeted
tests rồi `.claude/skills/flutter-workflow/scripts/dod_check.sh` ở repair pass.
Emulator IT để integration worktree, ghi deferred chứ không pass.

Clean stop chỉ khi không còn P0/P1/P2, mọi invariant có test âm/dương, docs và
code thống nhất, gate xanh và báo cáo liệt kê command + kết quả thật. Nếu một
blocker lặp lại hoặc product meaning chưa canonical, dừng với blocker cụ thể.
