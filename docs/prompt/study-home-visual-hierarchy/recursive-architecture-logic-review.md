# Recursive Architecture and Logic Review — Study Home Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit độc lập và auto-fix regression nghiệp vụ/kiến trúc sau restyle Study Home |
| **Scope** | Study Home presentation, action wiring và tests; không mở rộng study/session feature |
| **Source of truth for** | Quy trình recursive architecture/logic review của Study Home visual hierarchy |
| **Depends on** | `implementation.md`, BR-200…BR-202, UC-14, M5 Study Home và production tests |
| **Updated by task** | Study Home visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Đọc lại worktree mới nhất như reviewer độc lập. Audit diff, không tin summary.

## Phase order và worktree safety

Vòng đầu MUST là **audit-only** trên latest worktree/latest diff: tái hiện và lập
inventory, chưa sửa. Không revert ngoài scope và không commit/push/PR/merge.
Sau inventory mới auto-fix tuần tự; chạy verification/tests sau mỗi batch rồi
recursive audit lại từ đầu.

1. Chứng minh restyle không đổi repository/SQL/domain/controller/clock/route.
2. Reproduce resume hợp lệ/không hợp lệ, multiple session newest, stale
   generation, mixed workload, all-zero, no deck, no card, read error/refresh.
3. Chứng minh vào/scroll/refresh không write; Resume mở đúng persisted session;
   Study chỉ write sau tap; double tap chỉ mở một lần.
4. Chứng minh root aggregation/order/tie và ba metric luôn đúng BR-201; không
   dùng shortcut parent hoặc UI tự sort lại.
5. Audit state ownership, cross-feature imports, `ref.read` callback discipline,
   typed failure, l10n, no raw policy widget và no private logging.
6. Bổ sung test tái hiện trước fix cho mọi regression; chạy targeted + changed gate.

Ghi findings P0/P1/P2 với kịch bản expected/actual/file/BR. Auto-fix tuần tự,
đọc lại diff và lặp audit tới **clean stop** khi không còn finding, mọi state có bằng chứng và
changed gate xanh. Không đổi frozen rule để hợp thức hoá code, không update
golden/gallery, không tạo PR. Emulator ghi `not run — presentation-only`.
