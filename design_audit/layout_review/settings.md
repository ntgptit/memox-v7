# Settings

Settings & Reminder · `lib/features/settings/presentation/` · golden
`test/demo/goldens/settings_light.png` · commit `ea80d3f7` · UC-16

**Golden này không có bottom navigation** dù Settings là một tab — xem
[README](README.md).

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | 22/600 (title) · 16/400 ×36 (nhãn lựa chọn) · 14/600 (nhãn nhóm + nút) · 12/500/ls1.1 (nhãn section) · 12/400 |
| Font weight | 400, 500, 600 — **không có 700** |
| Spacer | 4×5, 16×3, 24×4 — **toàn bộ trên scale** |
| Inset | 4×2, 8×4, 12×2, 16×22, 24×2 — **toàn bộ trên scale, không có 1px viền** |
| Trục text trái | **88 ×32** (nhãn lựa chọn) · 16 ×10 · 36 ×5 · 52 ×4 |
| Tap target | 15 chạm được, **7 "dưới 48"** — **cả 7 đều được hàng 329/361×56 phủ** |
| Chiều cao hàng | radio row = **56** đều nhau |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ➖ không kiểm được — golden thiếu thanh nav |
| Touch target | ✅ **15/15 hiệu dụng** — radio 40px nằm trong hàng 56px |
| Text đọc được | ✅ |
| Component đúng chức năng | ❌ **hai mô hình lưu trên một màn** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ section label → nhóm → lựa chọn, ba cấp rõ |
| Grouping đúng | ✅ 24 giữa section, 16 trong nhóm, 0 giữa các hàng radio |
| Alignment tốt | ✅ **trục 88 dùng 32 lần** cho mọi nhãn lựa chọn trên cả ba nhóm |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale |
| Density hợp lý | ✅ |
| Visual weight cân | ⚠️ khối `Save` là thứ nặng nhất màn và nó chỉ thuộc một trong ba section |
| CTA prominence | ❌ F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ radio căn giữa theo nhãn |
| Typography tinh tế | ✅ **6 rung, 3 weight** |
| Icon/text proportion | ➖ không có icon |
| Surface/color hierarchy | ⚠️ primary ở radio đã chọn **và** ở nút `Save` — nút hút mắt khỏi lựa chọn |
| Mắt đi đúng flow | ⚠️ F1 |

## Checklist 20 mục

**1. Screen structure** ⚠️ Ba nhóm cài đặt rõ. Nhưng chúng **không hành xử giống
nhau** — F1.

**2. Visual hierarchy** ✅ `STUDY DEFAULTS` / `APPEARANCE` / `LANGUAGE` ở
12/500/ls1.1 chữ hoa, **đặt ngoài thẻ** — cùng cách với `YOUR DECKS` của deck
list. Nhất quán xuyên feature.

**3. Grouping** ✅ Section 24, trong nhóm 16, hàng radio liền nhau. Quy tắc nhanh
của checklist (`item < group < section`) đúng.

**4. Alignment** ✅ **Trục 88 dùng 32 lần** — mọi nhãn lựa chọn trên cả ba nhóm
cùng một đường, kể cả khi nhóm có thêm field hoặc nút.

**5. Spacing & rhythm** ✅ Không giá trị nào ngoài scale, và **không có inset 1px**
— thẻ dùng viền qua `ShapeDecoration` chứ không sinh `Padding`.

**6. Typography** ✅ **6 rung, 3 weight.** Với một màn có field, radio, nút và ba
nhóm, đây là con số tốt.

**7. Component sizing** ✅ Bảy hàng radio đều cao 56.

**8. Density** ✅

**9. Balance** ⚠️

**10. Color hierarchy** ⚠️ Primary hai vai trò: đánh dấu lựa chọn (7 radio) và
hành động (`Save`). Với 7 radio đã dùng primary, nút `Save` không còn nổi bằng
cách dùng cùng màu.

**11. App bar** ✅ Title đơn giản, không action.

**12. List / card** ✅ **Cả hàng radio là target** — 7 "target nhỏ" mà probe báo
đều nằm trong hàng 56px. Xem F3.

**13. Filter / sort / chips** ➖

**14. CTA** ❌ F1.

**15. Scroll** ✅

**16. Responsive** ➖ Nhãn ngắn (`As added`, `Shuffled`, `System`) nên rủi ro thấp
kể cả ở tiếng Việt.

**17. Safe area** ➖ Không kiểm được.

**18. Empty / loading / error** ➖ Chưa có golden cho trạng thái lưu thất bại.

**19. Content stress** ➖ Chỉ có nhãn ngắn.

**20. Interaction** ⚠️ Radio đã chọn rõ ràng ✅. Nhưng F1 làm người dùng không
biết lựa chọn nào đã có hiệu lực.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | ba cấp rõ, nhãn section đặt ngoài thẻ nhất quán với app |
| Grouping | 2 | 24 < 16 < 0, đúng quy tắc nhanh |
| Alignment | 2 | **trục 88 dùng 32 lần xuyên ba nhóm** |
| Spacing | 2 | 0 giá trị ngoài scale, không viền sinh padding |
| Density | 2 | |
| Typography | 2 | 6 rung, 3 weight |
| CTA | 0 | **hai mô hình lưu, người dùng không biết cái nào cần bấm** |
| Responsive | 1 | chưa đo, thiếu thanh nav trong ảnh |
| **Tổng** | **13 / 16** | **Minor fix** — nhưng F1 là vấn đề mô hình, không phải pixel |

## Findings

**F1 — Hai mô hình lưu trên cùng một màn.** ❌
`STUDY DEFAULTS` có nút `Save` — thay đổi chỉ có hiệu lực khi bấm.
`APPEARANCE` và `LANGUAGE` **không có nút nào** — chọn radio là áp dụng ngay
(đổi theme thấy được tức thì).
Ba nhóm trông giống hệt nhau: cùng thẻ, cùng viền, cùng hàng radio 56px, cùng
trục 88. Không có tín hiệu thị giác nào phân biệt "cần lưu" với "đã áp dụng".

Hậu quả thật: người dùng đổi `Cards per session` rồi cuộn xuống đổi theme, thấy
theme đổi ngay, và kết luận mọi thứ đã lưu — rồi rời màn, mất thay đổi đầu tiên.
§14 nói CTA phải xuất hiện đúng lúc người dùng cần; §20 nói trạng thái phải rõ.

Ba lối, theo thứ tự tôi ưu tiên:
1. **Bỏ nút, lưu ngay cả ba nhóm.** Nhất quán nhất; dòng giải thích hiện có
   (`Applies to sessions you start after saving…`) chỉ cần đổi `after saving`
   thành `from now on`.
2. Giữ nút nhưng cho nhóm cần-lưu một dấu hiệu thị giác khi có thay đổi chưa lưu.
3. Đưa nút thành sticky bottom cho toàn màn — kém nhất, vì nó bắt hai nhóm kia
   giả vờ cần lưu.

**F2 — Nút `Save` là khối nặng nhất màn nhưng chỉ thuộc một phần ba màn.** ⚠️
Nó full-width, tô đặc, nằm trong thẻ đầu tiên. Mắt đọc nó như hành động của **cả
màn**. Đây là mặt thị giác của F1.

**F3 — Bảy radio 40×40, và tại sao chúng không phải lỗi.** ✅ ghi lại.
Probe báo 7 target dưới sàn. Kiểm tra bao phủ: cả 7 nằm trong `InkWell` 329×56
hoặc 361×56 — tức `RadioListTile` biến cả hàng thành target.
Cụm dương tính giả lớn thứ hai trong 29 màn, sau
[tag_filter_sheet](tag_filter_sheet.md) F2. Cùng một bài học: đo target mà không
kiểm bao phủ thì báo cáo này sẽ mở đầu bằng 13 lỗi Level 1 không tồn tại.

**F4 — Trục 88 dùng 32 lần.** ✅ ghi lại làm mốc.
Cao thứ hai trong 29 màn sau [tag_catalog](tag_catalog.md) (trục 32 ×48). Ba
nhóm với ba loại nội dung khác nhau — field, radio, radio — vẫn giữ chung một
đường cho nhãn. Đây là §4 làm đúng ở mức khó.
