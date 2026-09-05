# Recursive architecture and logic review — Flutter SDK version enforcement

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit planner integration, cache correctness và fail-fast behavior của SDK version gate |
| **Scope** | Delta verification tooling, fake executables, planner/stamp consumers và tests |
| **Source of truth for** | Hướng dẫn recursive tooling review; không thay verification contract |
| **Depends on** | `docs/prompt/flutter-sdk-version-enforcement/implementation.md`, `CLAUDE.md`, latest tooling tree |
| **Updated by task** | Terra verification campaign |
| **Last updated** | 2026-08-28 |

---

Audit-only pass đầu. Trace plan classification → decision check/skip → `.fvmrc` parse →
resolved executable → machine output → comparison → stop order. Kiểm prompt-only không
gọi Flutter, selected multi-step gọi một lần, stamp không che SDK swap và error không
tiếp tục xuống expensive steps.

Re-read latest worktree và latest diff trước mỗi vòng; reviewer không
commit/push/merge. Chứng minh business rules, database persistence và app
dependency boundaries không đổi; failure handling chỉ thuộc verification process
và không bị nuốt hoặc map thành success.

Fault-inject mismatch, stale cache, malformed JSON, PATH có hai SDK và fake command
non-zero. Kiểm implementation không tạo verifier entry thứ hai hoặc hardcode version.
Finding có severity/repro/file-line/fix/test; coordinator auto-fix, rerun tooling +
changed gate, reviewer lặp. Clean stop khi không P0/P1/P2 và full gate xanh.
