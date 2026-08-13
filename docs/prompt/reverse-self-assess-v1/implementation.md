# Implement Reverse Self-assess v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc thêm lựa chọn hướng hỏi cho SM-2 reviewing self-assess mà không làm sai nghiệp vụ Front/Back |
| **Scope** | Korean→Meaning, Meaning→Korean và Mixed cho SM-2 reviewing self_assess; không áp dụng 8-box hoặc learning chain |
| **Source of truth for** | Hướng dẫn thực thi Reverse Self-assess v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, Study scheduler/session/queue/history contracts và card Front/Back business rule |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Reverse Self-assess v1** trong worktree riêng. Front luôn là từ
tiếng Hàn, Back luôn là nghĩa ngôn ngữ đích; hướng hiển thị không được đảo hoặc
ghi lại content.

## Pre-flight và 5Why

Đọc repo contract/docs, Study BR/UC/data model/WBS, scheduler strategies, session/
queue/answer persistence, self-assess UI, mode factory/handler boundaries,
Card README và feature blueprint. Kiểm status/base/diff. Viết 5Why về recall
direction, why SM-2 reviewing only, stable Mixed persistence, resume/retry và
why content schema stays unchanged. Không commit/push/PR/merge trước reviews.

## Docs và nghiệp vụ

Append BR/UC/WBS bằng ID kế tiếp, cập nhật data model/migration docs và Study
wireframe/state matrix. Canonicalize:

1. Feature chỉ khả dụng cho session `reviewing`, scheduler `sm2`, mode
   `self_assess`. Eight-box vẫn chỉ đúng/sai và không nhận UI/enum/action mới.
2. Trước lượt học đầu tiên, người dùng chọn session direction:
   `koreanToMeaning`, `meaningToKorean`, hoặc `mixed`.
3. Korean→Meaning hiển thị Front làm prompt, Back làm reveal. Meaning→Korean
   hiển thị Back làm prompt, Front làm reveal. Dữ liệu card không mutation.
4. Mixed gán actual direction **một lần cho từng queue item/card** khi queue được
   materialize, cân bằng gần 50/50 bằng injected randomness và persisted result.
   Retry, comeback, resume và process restart phải giữ đúng hướng đã gán.
5. Session choice, queue actual direction và answer history direction được lưu
   explicit; không infer từ text/widget order. Old rows có migration/backfill
   tương thích Korean→Meaning.
6. Scheduler action set và SM-2 transition không đổi; direction chỉ đổi recall
   surface, không đổi score/due/ease/interval.
7. Direction bị khóa sau khi session bắt đầu. Exit trước queue creation không
   ghi session; resume không hỏi lại.
8. Privacy: không log Front/Back hoặc revealed content.

## Architecture và UI

- Domain enums/value models đặt trong Study domain; extend session/queue/answer
  contracts exhaustively. Random choice qua injectable seam, không `Random()`
  trong UI/controller.
- Drift migration thêm typed CHECK columns và backfill; transactions giữ session,
  queue và history consistent. Generated outputs không commit.
- Reuse Study mode factory/handler; không tạo second factory hoặc `if (sm2)` rải
  trong widgets. Eight-box paths không import/use reverse models.
- Entry chooser xuất hiện ở Study Entry chỉ khi eligible; lựa chọn rõ Recommended
  và supporting copy. Running self-assess card giữ Browse-established layout/
  progress; prompt/reveal labels phản ánh direction qua l10n.
- States: chooser initial/submitting/failure; three direction examples; mixed
  cards both directions; reveal; resume; long Back/Front; EN/VI, themes,
  compact/large text.

Pin geometry chooser/card gutters, option widths, prompt/reveal shared edges,
label/text baselines, action row và bottom safe area. Không dùng màu duy nhất để
phân biệt direction hoặc revealed state.

## Tests và clean stop

Domain tests eligibility, exhaustive direction mapping, injected random balance
contract và no scheduler effect. Real SQLite tests migration/backfill, persisted
session/queue/answer direction, Mixed stability qua retry/resume/restart, stale
generation, transaction rollback và unchanged card content/schedule semantics.
Controller/widget tests chooser visibility, eight-box absence, lock timing,
double tap, failure retention, reveal directions, resume and production actions.
Visual/semantics tests all states/locales/themes/viewports + `getRect`.

Run host targeted checks; emulator deferred to integration. Stop khi old DB
migrates, Mixed stable, 8-box untouched, docs/code/tests agree, no P0/P1/P2/TODO
and handoff lists schema/router/shared conflicts.
