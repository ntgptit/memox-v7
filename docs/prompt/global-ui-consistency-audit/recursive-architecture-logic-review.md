# Recursive architecture and logic review — Global UI consistency

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit shared-boundary refactor không làm thay behavior, dependency hoặc component API quality |
| **Scope** | Repo-wide UI delta, Mx components, feature callers, guards và behavior tests |
| **Source of truth for** | Hướng dẫn recursive architecture review; design-system AD và product BR/UC vẫn canonical |
| **Depends on** | `docs/prompt/global-ui-consistency-audit/implementation.md`, accepted shared-widget contracts, latest worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass audit-only. Review every changed shared API and reverse caller. Tìm trivial wrapper,
feature semantics rò vào shared, public raw `Color/TextStyle/Shape/Decoration/EdgeInsets`,
callback/focus/disabled/loading behavior đổi, nested Ink/Gesture, dependency inversion và
test chỉ đổi finder để xanh.

Đối chiếu **business-rule parity** của từng changed caller: shared refactor không được đổi
visibility, enablement, action, validation, failure mapping hoặc navigation đã được BR/UC khóa.

Trace representative button/card/input/dialog/navigation interactions; fault-inject disabled,
loading, cancel, nested action và failure. Presentation migration MUST NOT tạo persistence/
database/query mutation. Report severity/reproduction/file/contract/fix/test.

Coordinator auto-fix architecture trước, run changed gate, reviewer re-read latest tree và
lặp. Không nới guard/baseline để che debt. Clean stop khi shared component thực sự sở hữu
policy, all callers giữ behavior, full gate xanh. Reviewer không commit/push/merge.
