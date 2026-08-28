# Recursive Architecture and Logic Review — Progress Overview Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix regression nghiệp vụ/kiến trúc của Progress Overview sau restyle |
| **Scope** | Overview presentation/composition/tests; không mở rộng analytics hoặc Progress by Deck |
| **Source of truth for** | Quy trình recursive architecture/logic review của Progress Overview visual hierarchy |
| **Depends on** | `implementation.md`, BR-190…BR-199, UC-12, M99.23 và production tests |
| **Updated by task** | Progress Overview visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Re-read worktree và audit độc lập:

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: tái hiện và lập
inventory trước khi sửa. Không revert ngoài scope, không commit/push/PR/merge.
Sau inventory mới auto-fix; chạy verification/tests sau mỗi batch và recursive
audit lại tới clean stop.

1. Diff không được đổi domain/data/SQL/repository/clock/range/route.
2. Reproduce card-day distinct, Learning priority partition, 7-day zero-fill,
   streak active/held/zero, deletion/reset effects và local midnight.
3. Chứng minh mở/scroll/retry/tab không write; reload giữ loaded face/scroll.
4. Cấm mọi metric/control thuộc BR-191 và mọi count suy từ rows đã render.
5. Audit one snapshot/clock seam, typed failures, controller ownership, no raw
   policy widgets, no hardcoded tokens/l10n/private logs.
6. Kiểm Overview và by-deck vẫn một scroll/composition, không duplicate provider
   hoặc query vì visual refactor.
7. Thêm regression test trước fix; chạy targeted + changed gate.

Ghi finding P0/P1/P2 với scenario/expected/actual/file/BR, auto-fix theo severity,
đọc lại diff và lặp đến clean. Không đổi rule để làm code pass; không update
golden/gallery/PR. Clean stop: không finding, all state/edge tests xanh, changed
gate xanh, emulator `not run — presentation-only`.
