# Guess

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_guess_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **6**, tất cả là nội dung |
| Rung | **30/600/ls−0.5** (từ hỏi) · 14/400 (đáp án) · 12/600/ls1.1 · 12/600/ls.5 · 12/400 · 11/500/ls1.1 |
| Font weight | 400, 500, 600 |
| Spacer | 8×5, 12×2, 16×2 — **toàn bộ trên scale** |
| Inset | 4×2, 8×12, 16×20, 24×2 + **1×20 = viền của 5 ô + thẻ hỏi** + 2×1 và 40×1 từ `MxSessionTopBar` |
| Trục text trái | 33 ×15 · 324 ×3 · 16 ×3 |
| Tap target | **6 chạm được** (5 đáp án + `✕`), **0 dưới 48** |
| Chiều cao đáp án | ô 1 ≈ **215px**, bốn ô còn lại ≈ **120px** |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ |
| Không overlap | ✅ |
| Safe area | ⚠️ dòng hướng dẫn sát mép dưới |
| Touch target | ✅ 6/6 |
| Text đọc được | ✅ |
| Component đúng chức năng | ❌ **độ dài đáp án tiết lộ đáp án sai** — xem F1 |
| Responsive | ➖ |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ từ hỏi 30/600 là điểm nhấn cấp 1 duy nhất |
| Grouping đúng | ✅ thẻ hỏi tách khỏi khối đáp án; 5 đáp án cách đều nhau |
| Alignment tốt | ✅ trục 33 dùng 15 lần cho cả năm đáp án |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ thẻ hỏi ~730px cho một từ — xem F2 |
| Visual weight cân | ❌ **ô đáp án đầu nặng gấp ~4 lần bốn ô kia** — F1 |
| CTA prominence | ➖ không có CTA; chạm đáp án là hành động |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ dồn hết vào thẻ hỏi |
| Optical alignment | ✅ `WHAT IS THIS?` và từ hỏi cùng căn giữa |
| Typography tinh tế | ✅ 6 rung; **30/600/ls−0.5** cho từ hỏi là rung riêng có chủ đích |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ năm đáp án hoàn toàn trung tính — không gợi ý |
| Mắt đi đúng flow | ❌ F1: mắt bị ô dài kéo vào trước, và nó luôn là đáp án sai |

## Checklist 20 mục

**1. Screen structure** ✅ Hỏi ở trên, trả lời ở dưới. Rõ trong 1 giây.

**2. Visual hierarchy** ✅ Một điểm nhấn cấp 1 (từ hỏi 30/600), năm lựa chọn
ngang hàng. Đúng mô hình.

**3. Grouping** ✅ Thẻ hỏi và khối đáp án tách nhau rõ.

**4. Alignment** ✅ Trục 33 cho cả năm đáp án; nội dung đáp án căn trái — đúng §4,
vì đáp án cần quét nhanh.

**5. Spacing & rhythm** ✅ Giá trị app đều trên scale.

**6. Typography** ✅ 6 rung. Từ hỏi có rung riêng (30/600, tracking âm) — một
ngoại lệ có chủ đích cho phần tử quan trọng nhất màn.

**7. Component sizing** ❌ Năm ô cùng loại, cùng nhóm, chiều cao 215 / 120 / 120 /
120 / 120. §7 nói component cùng loại phải cùng chiều cao. Ở
[study_match](study_match.md) sự chênh lệch là có lý (hai ô cùng hàng vẫn bằng
nhau); ở đây năm ô là **một danh sách lựa chọn ngang hàng**, nên chênh lệch là
tín hiệu sai.

**8. Density** ⚠️ F2.

**9. Balance** ❌ F1.

**10. Color hierarchy** ✅ Trung tính hoàn toàn ở phần đáp án. Primary chỉ ở chip
chế độ và thanh tiến độ.

**11. App bar** ✅ Cùng `MxSessionTopBar`.

**12. List / card** ✅ Toàn bộ ô đáp án là target.

**13. Filter / sort / chips** ➖

**14. CTA** ➖ Không có, đúng. Hướng dẫn `Choose the right meaning` rõ.

**15. Scroll** ✅ Vừa một màn.

**16. Responsive** ➖ Ô đáp án đầu đã ba dòng ở 393px; ở 360 sẽ là bốn và màn phải
cuộn.

**17. Safe area** ⚠️

**18. Empty / loading / error** ➖ `guess_correct` và `guess_wrong` có golden
riêng, ngoài 29 màn.

**19. Content stress** ⚠️ Fixture **có** ca khó (đáp án dài) nhưng nó lộ F1 chứ
không chứng minh màn xử lý được.

**20. Interaction** ✅ Chạm, không vuốt. Năm ô trông chạm được và chạm được.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | một điểm nhấn cấp 1, năm lựa chọn ngang hàng |
| Grouping | 2 | hỏi và trả lời tách rõ |
| Alignment | 2 | trục 33 dùng 15 lần |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 1 | thẻ hỏi 730px cho một từ |
| Typography | 2 | 6 rung, rung riêng cho từ hỏi có chủ đích |
| CTA | 2 | tương tác rõ, mọi ô là target |
| Responsive | 1 | ô đáp án dài sẽ vỡ ở 360 |
| **Tổng** | **14 / 16** | **Pass** — nhưng F1 làm hỏng chính trò chơi |

## Findings

**F1 — Độ dài đáp án tiết lộ đáp án sai.** ❌ **Đây là lỗi nặng nhất trong nhóm
Study.**
Năm lựa chọn là:

```
1  Xin chào / Chào hỏi lịch sự (Câu chào dùng với người lớn tuổi hoặc người mới
   gặp; 안녕: bình an, 하세요: đuôi câu thể lịch sự)     ← 3 dòng, ô cao 215px
2  biển
3  quả táo
4  nước
5  quyển sách
```

Một người **không biết một chữ tiếng Hàn nào** vẫn loại được ô 1 ngay lập tức:
nó là thứ duy nhất trông khác. Bố cục đang rò rỉ thông tin mà bài kiểm tra tồn
tại để giấu.

**Sửa lại sau phản biện của chủ dự án (2026-08-26).** Bản đầu của F1 này kết
luận rằng nên "lấy phần trước dấu `(`". Kết luận đó sai ở cả hai đầu:

- **Phần trước ngoặc không phải "đáp án ngắn"** — nó là nghĩa ngắn gọn gồm
  **tiếng Anh và tiếng Việt**; phần trong ngoặc mới là chi tiết. BR-08 nói thẳng
  vì sao mặt sau được 240 ký tự: *"một nghĩa chứa nhiều hơn một từ — hai ngôn
  ngữ, ngăn bằng dấu phẩy"*. Nên dạng `English / Tiếng Việt (chi tiết)` **là**
  dạng đúng của `back`, không phải một sự phình ra cần cắt.
- **Và cắt ngoặc không sửa được rò rỉ.** `Xin chào / Chào hỏi lịch sự` vẫn dài
  gấp khoảng năm lần `quả táo`. Ô số 1 vẫn là ô duy nhất trông khác.

Nhìn lại bộ 5 thẻ trong `study_modes_demo_test.dart`, thứ bất thường **không phải
thẻ dài**: `quả táo`, `nước`, `quyển sách`, `biển` đều chỉ có tiếng Việt, tức
thiếu hẳn nửa tiếng Anh mà BR-08 mô tả. Chính chú thích của fixture cũng nói vậy —
*"One deliberately long meaning, in the shape a real deck uses."*

Nên gốc của rò rỉ không nằm ở dữ liệu, và **không thể** nằm ở dữ liệu: người dùng
viết mặt sau theo cách của họ, app không chuẩn hoá được độ dài đó.

**Hướng đúng: chuẩn hoá ở tầng trình bày.** Kẹp mọi ô đáp án về cùng một số dòng
(ellipsis khi tràn) để năm ô cao bằng nhau. Khi đó độ dài không còn mang tín hiệu
nào, bất kể dữ liệu ra sao. Nó sửa đồng thời:

- rò rỉ ở đây,
- §7 của chính màn này (năm ô cùng loại, chiều cao 215/120/120/120/120),
- và lệch cột 5:1 ở [study_match](study_match.md).

**Chỉ kẹp ở Guess và Match** — hai chế độ mà người học *quét để chọn*. Browse,
Recall và Fill phải hiện đủ nghĩa, vì ở đó đọc nghĩa mới là việc.

**F2 — Thẻ hỏi cao ~730px cho một từ.** ⚠️
Cùng dạng với [study_browse](study_browse.md) F2: khung thẻ cố định, nội dung
ngắn, phần lớn diện tích là khoảng trống. Ở đây nó còn đẩy đáp án cuối xuống sát
mép dưới.
Nếu thẻ hỏi co theo nội dung, năm đáp án sẽ có thêm ~200px — đủ để ô đáp án dài
không phải chen.

**F3 — Không gợi ý màu ở phần đáp án.** ✅ ghi lại.
Năm ô hoàn toàn trung tính, không ô nào có viền hay nền khác. Đó là điều bắt buộc
với một bài trắc nghiệm và màn này làm đúng — F1 rò rỉ qua **kích thước** chứ
không qua màu.
