# Wireframe M6 — Daily Reminders (Settings → nhắc học hằng ngày)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của màn nhắc học để M99.23 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn nhắc học trong nhánh Settings: entry point, anatomy, mọi trạng thái, dialog chọn giờ, hợp đồng geometry, responsive/a11y, và hình dạng notification. Ngoài phạm vi: luật nghiệp vụ (BR-182…BR-193), luồng (UC-12), quyết định kiến trúc (AD-21), màn Settings đầy đủ (chưa có) |
| **Source of truth for** | Anatomy màn nhắc học · copy các trạng thái nhắc học · hợp đồng geometry của màn nhắc học · responsive/a11y contract của màn nhắc học |
| **Depends on** | `../use-cases.md` (UC-12), `../business-rules.md` (BR-182…BR-193), `../architecture.md` (AD-21) |
| **Updated by task** | M99.23 (phase 6 — recursive UI/UX review, vòng 2) |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

## D-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| R1 | Nhắc học là **một route riêng** `/settings/reminders` do feature `reminder` sở hữu, vào từ **một hàng** trên nhánh Settings — không phải một section nhúng vào màn Settings | Màn Settings thật chưa tồn tại (AD-19: nhánh Settings đang là placeholder). Một section nhúng buộc `features/settings/presentation/` phải import widget của `features/reminder/presentation/` — đúng cái `check_architecture` gọi là cross-feature import. Một route riêng giữ seam sạch: khi màn Settings thật đổ bộ, nó chỉ cần giữ lại đúng một hàng, không phải gỡ một section ra | 2026-08-13 |
| R2 | Toggle là **hàng đầu tiên**, giờ nhắc là hàng ngay dưới nó trong **cùng một** surface card | Hai hàng là một quyết định: "có nhắc không" và "lúc mấy giờ". Tách chúng ra hai card làm giờ trông như một cài đặt độc lập vẫn có tác dụng khi toggle tắt | 2026-08-13 |
| R3 | Hàng giờ **luôn hiển thị**, kể cả khi tắt; khi tắt thì nó bị **vô hiệu** chứ không bị ẩn | Ẩn rồi hiện làm layout nhảy đúng lúc người dùng vừa chạm toggle (BR-192 nói bước bật có thể thất bại, nên cú nhảy đó có thể xảy ra rồi bị hoàn tác). Vô hiệu cũng cho người dùng thấy giờ mặc định 20:00 **trước khi** quyết định bật | 2026-08-13 |
| R4 | Hai dòng supporting copy nằm **dưới** card, không phải trong hàng | Chúng nói về cả tính năng, không về một control: "chỉ nhắc khi còn thẻ đến hạn" (BR-184) và "notification có thể nêu tên deck và số thẻ trên màn khoá" (BR-186). Đặt trong hàng thì chúng phải cạnh tranh chiều rộng với toggle và bị cắt trước tiên ở 320dp | 2026-08-13 |
| R5 | Trạng thái lỗi là một **banner trong luồng**, đặt ngay dưới card và **trên** supporting copy; không dùng snackbar | Snackbar biến mất trong 4 giây và mang theo hành động khôi phục duy nhất. Từ chối quyền (BR-192) là trạng thái tồn tại lâu, không phải một sự kiện — nó phải còn ở đó khi người dùng quay lại từ cài đặt hệ thống | 2026-08-13 |
| R6 | Chọn giờ dùng **dialog** của nền tảng, mở từ hàng giờ | Một dialog chọn giờ là thứ người dùng Android đã biết, và giờ là giá trị duy nhất nó thu. Một màn riêng cho một giá trị là màn hình đi tìm nội dung để lấp | 2026-08-13 |
| R7 | Toggle **không** dùng màu làm tín hiệu duy nhất: giá trị được nói bằng chữ ở hàng giờ và bằng `Semantics` value của chính toggle | Một switch xanh/xám là tín hiệu chỉ-màu. Hàng giờ hiện `8:00 PM` khi bật và bị vô hiệu khi tắt, nên trạng thái đọc được cả khi không phân biệt được màu | 2026-08-13 |
| R8 | Notification là **một** dòng tiêu đề + một dòng thân, không có action button, không có big-text expand | Mọi hành động khả dĩ là "mở app học" — đúng cái chạm vào notification đã làm (BR-189). Một nút "Study now" trùng lặp với thân notification và mời gọi một luồng auto-start mà BR-189 cấm | 2026-08-13 |

## W-cấu trúc

```
┌─ Settings (nhánh 4 của shell) ────────────────┐
│  Settings                                     │  ← MxContentShell title
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ 🔔  Daily reminder                   ›  │  │  ← W1 hàng vào, MxListTile
│  └─────────────────────────────────────────┘  │
│                                               │
│      App settings are being developed         │  ← placeholder cũ, giữ nguyên
│                                               │
├───────────────────────────────────────────────┤
│  [Library] [Study] [Progress] [Settings]      │  ← bottom nav, luôn hiển thị
└───────────────────────────────────────────────┘

┌─ /settings/reminders ─────────────────────────┐
│  ‹  Daily reminder                            │  ← W2 shell, có Back
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ Daily reminder                    [ o]  │  │  ← W3 toggle row
│  │ ─────────────────────────────────────── │  │
│  │ Reminder time                           │  │  ← W4 time row
│  │ 8:00 PM                                 │  │
│  └─────────────────────────────────────────┘  │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │ ⚠ Notifications are turned off          │  │  ← W5 banner (chỉ khi lỗi)
│  │   Turn them on for MemoX in your        │  │
│  │   device settings, then try again.      │  │
│  │                            [Try again]  │  │
│  └─────────────────────────────────────────┘  │
│                                               │
│  You'll only be reminded when cards are due.  │  ← W6 supporting copy
│  The reminder can show a deck name and how    │
│  many cards are due, including on your lock   │
│  screen.                                      │
│                                               │
├───────────────────────────────────────────────┤
│  [Library] [Study] [Progress] [Settings]      │  ← bottom nav vẫn còn (R1)
└───────────────────────────────────────────────┘
```

| # | Phần | Ghi chú |
|---|---|---|
| W1 | Hàng vào ở nhánh Settings | Chỉ nhãn + chevron, **không** hiện trạng thái. Hiện `Off`/giờ ở đây buộc `features/settings/presentation/` phải theo dõi state của `features/reminder/` — đúng cross-feature import mà `check_architecture` chặn (R1). Trạng thái nằm cách một lần chạm, trên màn nói thẳng ra |
| W2 | Shell của màn nhắc học | Cùng `MxContentShell` với mọi màn khác; Back trả về nhánh Settings |
| W3 | Hàng toggle | Nhãn bên trái, `Switch` bên phải. Khoá khi `enabling` và khi nền tảng không hỗ trợ |
| W4 | Hàng giờ | Nhãn trên, **giờ ở dòng dưới** — không phải trailing. Cạnh nhãn, giờ chiếm 157dp trong ~264dp bề rộng hàng ở 320dp scale 2.0, để lại 90dp cho một nhãn có intrinsic 422dp; `MxListTile` trần hai dòng rồi ellipsis, nên nhãn bị **cắt**, đúng thứ A2 cấm. Chạm mở dialog (R6). Vô hiệu khi toggle tắt (R3) |
| W5 | Banner lỗi | Tồn tại ở S6…S10, và ở S7 nó được suy ra từ **capability** chứ không từ một lệnh đã chạy — trên nền tảng không hỗ trợ thì không lệnh nào chạy được, nên chờ một lệnh hỏng sẽ khiến S7 không bao giờ tới được. Mang đúng một CTA khôi phục, và CTA đó **chạy lại đúng lệnh đã hỏng** — không phải một lệnh cố định |
| W6 | Supporting copy | Hai câu, luôn hiển thị, không đổi theo trạng thái |

## S-trạng thái

| # | Trạng thái | W3 | W4 | W5 | Ghi chú |
|---|---|---|---|---|---|
| S1 | loading | **không có** | **không có** | — | `MxAsyncView` render loading state của shell thay vì hai hàng bị khoá. Chấp nhận có chủ đích: điều S1 phải tránh là **nhấp nháy sang `off` rồi bật lại**, và không render gì thì không thể nhấp nháy. Hai hàng bị khoá cần một bản sao thứ hai của card chỉ để sống 100ms |
| S2 | off | tắt, bật được | vô hiệu, hiện 8:00 PM | — | Trạng thái mặc định (BR-182) |
| S3 | enabling | khoá **ở vị trí cũ**, xám đi | khoá | — | Đang xin quyền/đặt lịch. Switch không tự chuyển trước khi biết kết quả: BR-192 nói bước bật có thể hỏng, và một switch đã trượt sang rồi trượt về là lời hứa bị rút lại. Chiều cao card **không** đổi (R3, G5) |
| S4 | on | bật | hoạt động, hiện giờ | — | |
| S5 | time picker mở | khoá | — | — | Dialog nền tảng phủ lên |
| S6 | permission denied | tắt, bật được | vô hiệu | `Notifications are turned off` + `Try again` | Settings vẫn tắt (BR-192) |
| S7 | platform unavailable | tắt, **vô hiệu** | vô hiệu | `Reminders aren't available on this device` — không CTA | Không có đường khôi phục nên không có nút giả (BR-193). Banner suy từ capability **và** khoá toggle: capability được giải một lần lúc mở màn, còn `EnableReminderUseCase` đọc lại lúc chạm, nên nếu chỉ nhìn snapshot thì banner nói "không dùng được" cạnh một switch vẫn gạt được |
| S8 | schedule error | tắt, bật được | vô hiệu | `The reminder couldn't be scheduled` + `Try again` | Không có trạng thái bật giả |
| S9 | settings error | về giá trị đang lưu | theo giá trị đang lưu | `Your change wasn't saved` + `Try again` | |
| S10 | cancel error | tắt, bật được | vô hiệu | `The reminder is off, but a pending alert may remain` + `Try again` | Tắt **đã ghi**, chỉ lịch cũ không huỷ được. Copy của S8 sẽ nói ngược sự thật ở đây (BR-190) |

Không có state `empty`: màn này luôn có nội dung, kể cả khi thư viện rỗng.

## G-hợp đồng geometry

Đo bằng `getRect` trong test, không bằng mắt.

| # | Ràng buộc |
|---|---|
| G1 | Card (W3+W4) và banner (W5) **chung mép trái và mép phải** — cùng một surface column; sai lệch 0 |
| G2 | Mép của card và của supporting copy trùng nhau; gutter đến từ `MxContentShell`, không từ padding tự đặt |
| G3 | Toggle và nhãn của W3 **cùng đường tâm dọc**. W4 xếp dọc (W4), nên hai dòng của nó **cùng mép trái**, không cùng đường tâm |
| G4 | Vùng chạm của W3 và W4 mỗi cái cao ≥ 48dp ở mọi viewport và mọi text scale |
| G5 | Chuyển S2 → S3 → S4 **không đổi chiều cao của card**; đây là điều R3 mua |
| G6 | Đáy nội dung cách bottom navigation ≥ khoảng gutter của shell; không có phần tử nào bị bottom nav che ở 320×568 |
| G7 | W5 xuất hiện đẩy W6 xuống, **không** phủ lên nó và không làm card đổi kích thước |

## A-responsive và a11y

| # | Ràng buộc |
|---|---|
| A1 | Không tràn ở 320dp@2.0, 390dp, 412dp; kiểm cả EN và VI |
| A2 | Không tràn ở text scale 2.0 tại 320×568, và **không nhãn nào bị ellipsis**. Đo bằng `didExceedMaxLines` chứ không bằng `takeException`: một nhãn bị cắt không ném exception nào |
| A3 | `Semantics` **nằm trên chính `Switch`**, mang cả label lẫn value; `Text` nhãn bên trái bị `ExcludeSemantics`. Label ở node anh em thì reader focus vào switch chỉ nghe "Off" — có value mà không có name (WCAG 4.1.2) |
| A4 | Giờ đã bản địa hoá nằm **trong chính nhãn gộp** của node — đọc đúng một lần. `MxListTile` gộp title + subtitle thành một node, nên thêm một `Semantics(value:)` ở ngoài sẽ khiến reader đọc giờ hai lần. Role `button` chỉ có **khi hàng hoạt động**; lúc vô hiệu node giữ `hasEnabledState` với `isEnabled=false` và rời khỏi focus order — hành vi của `ListTile(enabled: false)`, và TalkBack vẫn xướng "disabled" |
| A5 | Banner lỗi mang `Semantics` live region; CTA của nó là một nút thật, không phải text chạm được |
| A6 | Mọi copy đến từ ARB (EN/VI); không có chuỗi người dùng thấy được nằm trong code |

## N-hình dạng notification

| # | Ràng buộc |
|---|---|
| N1 | Tiêu đề: `Time to study` — không đếm, không tên deck |
| N2 | Thân, một deck: `N cards are due in <deck>` |
| N3 | Thân, nhiều deck: `N cards are due in <deck> and M more decks` |
| N4 | Không mặt trước/sau thẻ, không ví dụ, không tag, không lịch sử — kể cả trên lock screen (BR-186) |
| N5 | Một notification id cố định, nên lượt hôm nay thay lượt hôm qua nếu nó còn trên shade (BR-185) |
| N6 | Không action button (R8) |
