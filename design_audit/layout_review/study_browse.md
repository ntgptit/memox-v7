# Browse

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_browse_light.png` · commit `ea80d3f7`

Giai đoạn đọc của learning: xem mặt trước và mặt sau, chưa chấm điểm.

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | 22/500 (từ) · 16/400 (nghĩa) · 12/600/ls1.1 · 12/600/ls.5 · 12/400 · **11/500/ls1.1 ×7** |
| Font weight | 400, 500, 600 |
| Spacer | 8×1, 16×2 — **toàn bộ trên scale** |
| Inset | 4×2, 8×4, 16×12 + 1×1 viền + **2×1 và 40×1 từ `MxSessionTopBar`** |
| Trục text trái | 32 ×6 · 324 ×3 · 16 ×3 · 102 ×3 · 58 ×2 |
| Tap target | **2 chạm được**, 0 dưới 48 |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ nghĩa tiếng Việt hai dòng, hiển thị đủ |
| Không overlap | ✅ |
| Safe area | ⚠️ dòng gợi ý vuốt nằm sát mép dưới |
| Touch target | ✅ 2/2 |
| Text đọc được | ⚠️ nhãn `FRONT`/`BACK`/`5 NEW CARDS` ở **11px** |
| Component đúng chức năng | ✅ |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ từ 22/500 > nghĩa 16/400 > nhãn 11/500 — ba cấp tách bạch |
| Grouping đúng | ✅ một đường kẻ chia FRONT/BACK — **và ở đây divider là đúng**, vì hai nửa là hai mặt của cùng một thẻ |
| Alignment tốt | ⚠️ nội dung căn giữa, nhãn căn trái — hai hệ trong một thẻ |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale (trừ hai giá trị của `MxSessionTopBar`) |
| Density hợp lý | ❌ **~70% diện tích thẻ là khoảng trống** — xem F2 |
| Visual weight cân | ⚠️ hai nửa thẻ đều rỗng ở giữa |
| CTA prominence | ❌ **không có CTA nào** — xem F1 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ rất nhiều, và không có chủ đích rõ |
| Optical alignment | ✅ chip `BROWSE` + thanh tiến độ + `2 / 5` nằm trên một đường |
| Typography tinh tế | ⚠️ 6 rung, một rung 11px dùng 7 lần |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ primary chỉ ở chip chế độ và thanh tiến độ |
| Mắt đi đúng flow | ✅ trên xuống: đang ở đâu → mặt trước → mặt sau → làm gì tiếp |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. Thanh trên nói chế độ, tiến độ và lối ra
trong một dòng — rất gọn.

**2. Visual hierarchy** ✅ Ba cấp.

**3. Grouping** ✅ Divider giữa FRONT và BACK là **ngoại lệ đúng** với §3: hai nửa
cần một ranh giới dứt khoát vì chúng là hai mặt khác nhau của một thẻ, và khoảng
trắng ở đây quá nhiều nên tự nó không tạo ranh giới.

**4. Alignment** ⚠️ Nhãn `FRONT`/`BACK` căn trái ở trục 32; nội dung căn giữa.
Với nội dung ngắn thì ổn; nghĩa hai dòng căn giữa đã bắt đầu khó quét (§4 "không
căn giữa text dài nếu cần đọc nhanh").

**5. Spacing & rhythm** ✅ Giá trị của app đều trên scale. `MxSessionTopBar` dùng
2 và 40 — hai giá trị ngoài scale, đã truy nguồn ở [README](README.md).

**6. Typography** ⚠️ 6 rung, trong đó **11px dùng 7 lần** cho nhãn.

**7. Component sizing** ✅

**8. Density** ❌ F2.

**9. Balance** ⚠️

**10. Color hierarchy** ✅ Primary hai chỗ: chip chế độ và thanh tiến độ. Cả hai
mang nghĩa.

**11. App bar** ✅ **Thanh phiên học là ví dụ tốt về app bar gọn**: `✕` + chip
chế độ + thanh tiến độ + `2 / 5`, tất cả trong một dòng 48px. §11 "app bar không
chiếm diện tích quá lớn đối với màn hình đơn giản" — đạt.

**12. List / card** ➖

**13. Filter / sort / chips** ✅ Chip `BROWSE` là nhãn chế độ, không giả dạng nút.

**14. CTA** ❌ F1.

**15. Scroll** ✅ Không cuộn — thẻ vừa một màn.

**16. Responsive** ➖ Nghĩa tiếng Việt đã hai dòng ở 393px; ở 360 sẽ là ba, và thẻ
vẫn còn thừa chỗ nên không vỡ.

**17. Safe area** ⚠️ Dòng `Swipe left for next, right to go back` là phần tử thấp
nhất màn. Cùng dạng với F2 của [card_import_source](card_import_source.md).

**18. Empty / loading / error** ➖

**19. Content stress** ✅ Từ Hàn dài + nghĩa tiếng Việt có dấu, có ngoặc, hai
dòng. Xử lý đúng.

**20. Interaction** ❌ F1.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | ba cấp tách bạch |
| Grouping | 2 | divider dùng đúng chỗ nó cần |
| Alignment | 1 | hai hệ căn trong một thẻ |
| Spacing | 2 | giá trị app đều trên scale |
| Density | 0 | 70% thẻ là khoảng trống |
| Typography | 1 | 6 rung, 11px dùng 7 lần |
| CTA | 0 | **không có nút nào để đi tiếp** |
| Responsive | 1 | chưa đo |
| **Tổng** | **9 / 16** | **Major layout revision** |

## Findings

**F1 — Vuốt là cách duy nhất để đi tiếp.** ❌ Level 1 theo §20.
Đo được **2 target chạm được trên toàn màn**, và một trong hai là `✕` để thoát.
Không có nút Next, không có vùng chạm để sang thẻ sau. Dòng
`Swipe left for next, right to go back` xác nhận điều đó.

§20 nói thẳng: "Swipe gesture không phải cách duy nhất để truy cập chức năng
quan trọng". Sang thẻ tiếp là chức năng **duy nhất** của màn này.
Hậu quả thật, không chỉ lý thuyết: người dùng chỉ dùng được một tay ở tư thế
khó, người dùng khuyết tật vận động, và trình đọc màn hình đều không có đường
nào khác. Đây cũng là mục accessibility mà Definition of Done yêu cầu.

Hướng: hai vùng chạm vô hình ở nửa trái/nửa phải thẻ, hoặc một cặp nút
`‹ Trước / Tiếp ›` ở đáy — chỗ mà dòng gợi ý vuốt đang chiếm.

**F2 — ~70% diện tích thẻ là khoảng trống.** ❌
Nửa FRONT cao ~800px hiển thị cho một từ 22px; nửa BACK cao ~750px cho hai dòng
16px. Thẻ chiếm gần trọn màn nhưng mực chữ chiếm chưa tới một phần ba.
§8 nói màn không nên trống tới mức phải cuộn không cần thiết — ở đây không phải
cuộn, mà là mắt phải đi rất xa giữa hai mẩu thông tin ngắn.
Với thẻ có Example/Hint/Pronunciation thì chỗ này sẽ đầy. Nhưng thẻ chỉ có
front/back — trường hợp phổ biến nhất — thì bố cục nên co lại thay vì giữ khung
cố định.

**F3 — Nhãn 11px, dùng 7 lần.** ⚠️
`FRONT`, `BACK`, `5 NEW CARDS` và các nhãn khác đều 11/500/ls1.1. Cùng vấn đề với
[card_list](card_list.md) F4 và [card_detail](card_detail.md) F3 — ba màn ở ba
feature khác nhau đều tụt xuống 11px, nên đây là một khoảng trống trong thang
typography chứ không phải ba quyết định riêng lẻ.
