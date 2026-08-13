# Recursive UI/UX Review — Study Home v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa hierarchy, workload scanning, geometry và interaction của Study Home |
| **Scope** | Resume, root-deck list, empty/error/loading states và responsive/accessibility behavior |
| **Source of truth for** | Quy trình recursive UI/UX review Study Home v1 |
| **Depends on** | `docs/prompt/study-home-v1/implementation.md`, Study Home wireframe và MemoX tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production `/study`. `AUDIT_ONLY` chỉ inspect/measure/report;
`APPLY_FIXES`/standalone sửa đệ quy trên latest tree. Không commit/push/PR/merge.

Ma trận: loading; Resume + mixed decks; no Resume; all-zero; empty library;
error/retry; long deck names/counts; post-session refresh; EN/VI; light/dark;
320dp@2.0, 390/412dp. Đo `getRect` cho gutters, Resume/list shared edges,
row widths/padding/gaps, workload text/icon baselines, Study button alignment,
safe area và bottom-nav clearance. Bảo đảm workload hierarchy scan nhanh nhưng
không biến card thành badge soup; overdue/due/new có icon+label đồng bộ, color
không là tín hiệu duy nhất, zero state không rối mắt.

Kiểm 48dp targets, TalkBack order, semantic action names, focus, double-tap
feedback và no route-wide spinner khi stream refresh. Mỗi geometry fix có
production assertion; golden phải đối chiếu wireframe. Clean stop khi mọi state
đã inspect, không unapproved difference/P0/P1/P2 và visual tests xanh.
