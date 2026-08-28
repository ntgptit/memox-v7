# Recursive architecture and logic review — Accessibility and localization

| | |
|---|---|
| **Status** | active |
| **Purpose** | Kiểm hardening không đổi business meaning, command flow hoặc ownership của localization |
| **Scope** | ARB/generated usage, semantics callbacks, shared/feature ownership và affected tests |
| **Source of truth for** | Hướng dẫn recursive logic review; canonical message intent/BR/UC vẫn quyết định nghĩa |
| **Depends on** | `docs/prompt/accessibility-localization-hardening/implementation.md`, latest ARB/docs/worktree |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only first pass. Map mỗi changed key/semantic action tới canonical meaning và callback.
Tìm key reuse khác nghĩa, translated business enum, placeholder type mismatch, raw locale
branch trong domain, semantics action bypass controller, duplicate activation, hidden enabled
control và generated file edit.

Fault-inject missing translation, long plural/count, disabled/loading action, screen-reader
tap và back. Presentation/a11y fixes MUST NOT mutation database/query/persistence.
Report severity/reproduction/file/contract/fix/test.

Coordinator auto-fix logic/ownership trước, run changed gate, reviewer re-read latest tree
và lặp. Không đổi canonical meaning để làm EN/VI khớp; ambiguity là blocker. Clean stop khi
key parity, callback behavior, dependency boundary và full gate sạch. Reviewer không commit/
push/merge.
