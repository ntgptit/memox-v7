# Implement Settings v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc thay Settings placeholder bằng global study defaults, theme và language thật |
| **Scope** | Card limit, new-card order, app theme, app language và reset root override; reminder nằm ngoài feature này |
| **Source of truth for** | Hướng dẫn thực thi Settings v1; nghiệp vụ chính thức thuộc BR/UC/AD/data model/wireframe trên branch |
| **Depends on** | `CLAUDE.md`, `app_settings` contract, effective Study options, theme/l10n/router contracts và `docs/wbs.md` |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Triển khai **Settings v1** production trong worktree riêng. Không thêm account,
sync, backup hoặc reminder vào task này.

## Pre-flight và 5Why

Đọc repo contract, document conventions, product/AD/BR/data model/UC/WBS,
`app_settings`, Study options/override flow, theme/bootstrap/l10n/router code,
Deck/Card README và feature blueprint. Kiểm branch/status/base; không ghi đè
worktree khác. Viết 5Why về placeholder, one-row typed settings, future-session
semantics, System defaults và separation của Reminder. Implementation phase
không commit/push/PR/merge.

## Docs và nghiệp vụ

Append BR/UC/WBS bằng ID tiếp theo, cập nhật AD-19 và data model/migration docs
nếu schema đổi, tạo Settings wireframe. Canonicalize:

1. Global study defaults gồm card limit và new-card order. Reuse production
   validation/enums; không tạo duplicate constants.
2. Root deck có override tiếp tục giữ override. Root không override đọc global.
   Action `Use app defaults` xóa root override atomically; sub-deck không sở hữu
   override.
3. Setting đổi chỉ áp dụng cho **session tạo sau đó**. Running session giữ
   persisted `card_limit`, queue/order hiện có không bị rebuild.
4. Theme có System/Light/Dark. Language có System/English/Vietnamese. System
   theo platform hiện tại; lựa chọn explicit bền qua restart.
5. App settings là one-row typed persistence, watchable và local-first. Không
   key-value map/string casts hoặc provider-memory-only truth.
6. Mỗi submit atomic, typed failure, double-submit guarded; failure giữ draft và
   giá trị persisted vẫn hiển thị.
7. Reset về app/system defaults là explicit action với hậu quả rõ; không reset
   study progress, scheduler, cards hoặc history.
8. Reminder/notification, account/sync, import/export/backup và advanced SM-2
   parameters ngoài scope.

## Architecture và UI

- Domain: immutable settings/read models, validation, repository contract và
  focused watch/update/reset use cases. Domain không Flutter/Drift.
- Data: mở rộng `app_settings` bằng migration chuẩn nếu theme/locale chưa có;
  single-row upsert/transaction, watch stream và mapper. Không commit generated.
- DI/app: binding đúng composition root; bootstrap/theme/locale consume domain
  provider qua explicit seam, không instantiate repository trong app widget.
- Presentation: `SettingsScreen`, controller state cho load/save/failure và
  sections đúng taxonomy. `/settings`/RouteNames/shell index giữ nguyên.
- UI sections: Study defaults; Appearance; Language. Mỗi choice dùng radio/
  segmented/list pattern phù hợp, current value rõ và supporting copy ngắn.
  Root `Use app defaults` sống ở deck options surface, không nhét vào global page.
- Copy EN/VI qua ARB; tokens/Mx components; theme switch không gây flash, mất
  navigation state hoặc restart giả.

States: loading, loaded defaults, non-defaults, saving, validation failure,
persistence failure+retry và platform System resolution. Wireframe pin gutters,
section edges, label/control baselines, divider/row rhythm và bottom-nav clearance;
kiểm EN/VI, both themes, 320dp@2.0, 390/412dp.

## Tests và clean stop

Domain/data tests validation, singleton row, migration old→new, watch updates,
atomic failure, theme/locale persistence, root override preservation/clear and
running-session immutability on real SQLite. App/controller/widget tests cover
bootstrap resolution, System changes, saving/error/retry/double tap, route/tab
state, locales/themes/viewports/semantics and `getRect` geometry.

Run targeted host checks; emulator IT deferred to integration worktree. Dừng
khi placeholder bị thay, restart persistence có test, session semantics đúng,
docs/schema/code/tests đồng nhất, không P0/P1/P2/TODO và handoff nêu rõ shared
schema/bootstrap/ARB conflicts.
