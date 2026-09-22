# Security và quyền riêng tư

| | |
|---|---|
| **Status** | active |
| **Purpose** | Nói rõ dữ liệu nào là riêng tư, nó được phép đi tới đâu, và chỗ nào trong code đang giữ ranh giới đó — vì ở MVP không có dữ liệu rời thiết bị, nên rủi ro thật nằm ở log và ở thông báo |
| **Scope** | Tài sản cần bảo vệ, ranh giới tin cậy, nơi nội dung riêng tư được phép hiện ra, và các biện pháp đang có trong code. Ngoài phạm vi: phân loại dữ liệu nhạy cảm ở mức sản phẩm (`product.md`), quyết định chưa mã hoá DB (AD-08) |
| **Source of truth for** | Ranh giới tin cậy và bề mặt rò rỉ đã kiểm · biện pháp đang có trong code và vị trí của chúng · rủi ro còn mở |
| **Depends on** | `document-conventions.md`, `product.md`, `architecture.md` (AD-03, AD-08) |
| **Updated by task** | project-documentation FULL_SYNC (no WBS id) |
| **Last updated** | 2026-09-23 |

---

## 1 · Mô hình mối đe doạ ở MVP, nói thẳng

**Không có dữ liệu nào rời thiết bị.** Không backend được gọi (`interfaces.md` §3),
không analytics, không network dependency. Nên ba đường rò rỉ thật sự còn lại là:

1. **Log** — phản xạ tự nhiên khi debug là in ra cái đang sai, và cái đang sai
   thường là nội dung thẻ.
2. **Thông báo hệ thống** — nó hiện trên màn hình khoá, ngoài phạm vi kiểm soát
   của app.
3. **File export** — người dùng chủ động tạo, rồi nó nằm ở nơi app không quản.

Cả ba đều đã có biện pháp; mục 3–5 nói từng cái.

## 2 · Tài sản cần bảo vệ

`product.md` là nguồn gốc của bảng phân loại. Tóm tắt để đọc được, không chép lại
chi tiết: nội dung deck và thẻ, ghi chú, **lịch sử học** (suy ra được thói quen và
giờ giấc), file import, media, và dữ liệu export — tất cả là dữ liệu cá nhân, chỉ
nằm trên thiết bị ở MVP.

Token và email **chưa tồn tại**. Khi backend xuất hiện: `flutter_secure_storage`,
không lưu trong Drift, không xuất hiện trong log, xoá khi logout (AD-03).

## 3 · Log: luật là "không bao giờ", và nó được giữ ở đâu

**BR-52: MUST NOT log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào.**
Log ID thì MAY. Đây là rule, không phải sự cẩn thận, chính vì nó là thứ dễ vi
phạm nhất.

Những chỗ đã kiểm trong lần sync này:

| Nơi | Trạng thái |
|---|---|
| `lib/features/search/**` | Không có lời gọi log nào |
| `lib/features/trash/**` | Không có lời gọi log nào |
| `lib/features/settings/**` | Không có lời gọi log nào |
| `lib/features/reminder/**` | **Một** chỗ có `developer.log` (`deliver_daily_reminder_use_case.dart:89`): chỉ một message cố định + `error`/`stackTrace`, không bao giờ log chính `summary` |
| `lib/app/reminder/**` | **Một** chỗ (`reminder_worker_entry.dart:103`): chỉ `outcome.name` — một tên enum. Comment ngay trên nó ghi rõ: *"No count, no deck name, no copy (BR-222)"*. Đây là tầng `app/`, không phải `features/` — ranh giới đó có ý nghĩa ở repo này |

Hai ranh giới nữa được giữ bằng **kiểu**, không bằng kỷ luật:

- `TrashBatchEntity` (`lib/features/trash/domain/entities/trash_batch_entity.dart:41`)
  mang tên deck hoặc **mặt trước của thẻ**, và comment ngay trên nó nói:
  *"Displayed, never logged (BR-267)."*
- `FillOutcome` (`lib/features/study/domain/models/fill_mode.dart:28-31`) **không
  mang** chuỗi người dùng gõ. Không phải "không log nó" — nó không có chỗ để đi
  tiếp (BR-138).

**Rủi ro còn lại, nói rõ:** hai chỗ log ở Reminder có truyền nguyên `error` /
`stackTrace`. Nếu một exception nền tảng hay Drift nào đó nhúng nội dung vào
`toString()` của nó, nội dung đó sẽ tới log. Chưa thấy bằng chứng việc này xảy
ra — kiểu `ReminderSummary` và `ReminderSettings` không bao giờ chảy vào hai lời
gọi đó — nhưng đây là một suy luận, không phải một chứng minh.

## 4 · Thông báo: rò rỉ có chủ đích, và người dùng được báo trước

Nhắc học hằng ngày **cố ý** hiện tên một deck và số thẻ đến hạn, kể cả trên màn
hình khoá. Đó là lý do tồn tại của nó.

Điều làm nó đúng chứ không phải một lỗ hổng: app nói trước, **trong app**, trước
khi người dùng bật. Chuỗi `reminderPrivacyNote` trong `lib/l10n/app_en.arb`:
*"The reminder can show a deck name and how many cards are due, including on your
lock screen."*

Và nội dung bị chặn trên bằng **hình dạng kiểu**, không bằng review:
`ReminderSummary` (`lib/features/reminder/domain/models/reminder_summary_model.dart`)
chỉ có ba trường: `totalDueCount`, `otherDeckCount` (hai con số) và
`leadDeckName` (một tên deck). Không có trường nào để nội dung thẻ, tag hay lịch
sử đi vào (BR-222).

## 5 · Export và media

- Export **chỉ chạy khi người dùng chủ động yêu cầu** — không tự động, không chạy
  nền (BR-181).
- Bản export mang **nội dung**, không phải backup: không id, không timestamp,
  không lịch (BR-175).
- Implementation của đích đến **không được xin quyền lưu trữ rộng**, và không
  được ghi ra ngoài vùng riêng của app trước khi người dùng chọn đích
  (`card_export_destination_repository.dart:25-27`).
- Media nằm trong thư mục riêng của ứng dụng, không phải bộ nhớ dùng chung.
- Export **không bao giờ ghi vào database** — DAO của nó không có method ghi nào
  (BR-178). Đây là bảo đảm cấu trúc, không phải lời hứa.

## 6 · Ranh giới lỗi: người dùng không bao giờ thấy nội bộ

Exception của tầng data được map thành `Failure` của domain ngay tại ranh giới
repository. UI không bao giờ thấy một `DriftException`.

`Failure.message` được khai ở khắp nơi là *"a sanitized diagnostic, not a UI
string"* — màn hình switch trên `reason`/`problems`, không render message.
`card_detail_repository_test.dart:184` ghim chuyện này cho nội dung thẻ: message
không nêu id, path hay SQL (BR-53).

Search đi thêm một bước và ghi rõ lý do
(`library_search_body_widget.dart:56-64`): message gốc bị **vứt đi** và thay bằng
chuỗi ARB, vì *"a Drift message would tell the user nothing they can act on, and
can carry card content."*

## 7 · Rủi ro đang mở

**Database chưa mã hoá — xem AD-08.** Quyết định, lý do và điều kiện cần xem lại
đều nằm ở đó; không nhắc lại ở đây để hai bản không lệch nhau
(`document-conventions.md` §5).

**Quyền thông báo bị thu hồi sau khi đã cấp thì app không biết.**
`reminder_notification_data_source.dart` có `await` lời gọi
`areNotificationsEnabled()` nhưng **bỏ giá trị boolean trả về** — nó chỉ trả
`unsupported` khi có exception. `DeliverDailyReminderUseCase` không kiểm quyền
trước khi gọi `showSummary`. Hệ quả: người dùng cấp quyền lúc bật rồi thu hồi
trong Settings của hệ thống thì `isEnabled` vẫn `true`, màn hình vẫn báo
`supported`, lần chạy nền vẫn diễn ra và vẫn tự đánh dấu đã gửi (BR-221) — trong
khi OS im lặng bỏ thông báo. **Không có BR nào hiện yêu cầu kiểm lại quyền theo
thời gian**, nên đây là một khoảng trống chứ không phải vi phạm một luật đã có.
Nó là rủi ro về tính đúng đắn và trải nghiệm, không phải rò rỉ dữ liệu.

**`study_answers` là append-only theo quy ước, không theo database.** Không có
`CREATE TRIGGER` nào trong toàn bộ `.drift` (kiểm: 0 kết quả), và không câu query
nào định nghĩa `UPDATE`/`DELETE` trên bảng đó. Bảo đảm này có thật hôm nay, nhưng
nó do code giữ, không do schema. Một `customStatement` tương lai có thể phá nó mà
không gì báo.
