# Recursive architecture and logic review — Gallery and shared cleanup

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit cleanup không tạo abstraction noise hoặc làm đổi interaction behavior |
| **Scope** | Shared extractions, migrated callers, gallery tooling contract, tests và docs traceability |
| **Source of truth for** | Hướng dẫn recursive architecture review; shared-widget AD và feature behavior vẫn canonical |
| **Depends on** | `docs/prompt/gallery-shared-pattern-cleanup/implementation.md`, latest worktree và shared component contracts |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Với mỗi extraction, chứng minh policy ownership, mindestens hai/ba
semantic-equivalent callers, no feature dependency và API không expose raw visual primitives.
Trace callback/focus/loading/disabled/cancel của callers trước/sau; tìm trivial wrapper,
mega-configurable component, dead compatibility shim, gallery tool hardcode hoặc stale docs.

Fault-inject new caller state, long label, disabled/loading và nested action. Cleanup MUST NOT
đổi database/persistence/business flow. Report reproduction/file/contract/fix/test.

Coordinator auto-fix architecture, run changed gate, reviewer re-read latest tree và lặp.
Không nới guard hoặc nhận pixel snapshot làm behavior proof. Clean stop khi extractions đều
justify, callers parity, tooling deterministic và full gate xanh. Reviewer không commit/
push/merge.
