# Recursive architecture and logic review — local prompt handoff tooling

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập audit trust boundary, path/hash validation và tính nguyên tử của local prompt handoff |
| **Scope** | Delta task handoff tooling với `origin/main`, tests và contract liên quan |
| **Source of truth for** | Hướng dẫn recursive architecture/logic review của tooling; không thay thế repo contract |
| **Depends on** | `docs/prompt/local-prompt-handoff-tooling/implementation.md`, `AGENTS.md`, latest worktree |
| **Updated by task** | Terra tooling campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là reviewer độc lập. Pass đầu **audit-only**, không edit. Re-read latest tree,
baseline và toàn diff; reviewer không commit, push hoặc merge.

## Audit bắt buộc

- Trace mọi input tới canonical path, Git-root verification, feature containment,
  exact file set, hash comparison và emission.
- Tái hiện traversal, prefix-collision, symlink/junction, path có space/Unicode,
  source=target, nested root, missing Git và hash mismatch.
- Chứng minh script không TOCTOU theo kiểu in file 1 trước khi biết file 3 sai; mọi
  validation phải hoàn tất trước output.
- Kiểm script không mutate source/target, không eval command text, không swallow error,
  không log prompt body trên failure.
- Đối chiếu `AGENTS.md` với API thật và test; không chấp nhận contract nói có option
  mà script không support.
- Fault-inject bỏ root check, hash check, containment check và pre-emission barrier;
  từng mutation phải làm ít nhất một test đỏ.

Mỗi finding ghi severity, reproduction, exact file/line, impact, fix và regression
test. Sau report, coordinator auto-fix tuần tự, chạy tests/changed gate, rồi reviewer
audit lại từ đầu. Không nới test để hợp thức hóa defect.

Clean stop khi không còn P0/P1/P2, negative matrix kín, docs/API/tests parity, failure
không phát body và final gate xanh.
