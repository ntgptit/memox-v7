# Deck list — root

Library & Deck · `lib/features/deck/presentation/screens/deck_list_screen.dart`
· golden `test/demo/goldens/deck_list_root_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **12** — **2 của bottom nav**, **10 của nội dung** |
| Rung | 32/700 · 22/600 · 16/600 · 14/400 · 14/600 · 12/600/ls.72 · 12/400 |
| Font weight | 400, 500, 600, **700** |
| Spacer | 4×8, 8×1, 12×2, 16×3 — **toàn bộ trên scale** |
| Inset | 4×18, 8×42, 12×6, 16×25, 24×2, 32×1 — **toàn bộ trên scale** |
| Trục text trái | 16 (padding màn) ×7 · 92 (cột chữ trong tile) ×19 · 100 (chữ trong chip) ×6 |
| Tap target | 20 chạm được, **0 dưới 48** sau hit-test thật |
| Nhịp dọc | 16 / 16 / 8 / 0 — đo bằng `deck_list_rhythm_golden_test.dart` |
| Mực heading | cap cách hero 28,09 · baseline cách card 1 19,19 · nghiêng về list 8,9 |

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ✅ suite golden xanh, `audit_clip_test` không báo clip ngoài ý muốn |
| Không overlap | ❌ **FAB đè chữ của card 3** — xem F1 |
| Safe area | ➖ golden dựng ở một khung cố định, không có cutout để kiểm |
| Touch target | ✅ 20/20 đạt sau hit-test; không cái nào dựa vào semantics rect |
| Text đọc được | ✅ `TextContrastRule` gác trong `deck_list_screen_visual_audit_test.dart` |
| Component đúng chức năng | ✅ |
| Responsive | ➖ chỉ đo ở 393; xem §16 |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ⚠️ **ba nút primary tô đặc cùng lúc trong một viewport** — xem F2 |
| Grouping đúng | ✅ `YOUR DECKS` nghiêng về list 8,9px, hơn một bậc `AppSpacing.sm` |
| Alignment tốt | ✅ ba trục: 16 (màn), 92 (cột tile), 100 (chữ trong chip) — không có trục lẻ |
| Spacing có rhythm | ✅ 0 giá trị ngoài scale trên toàn màn |
| Density hợp lý | ✅ hero chiếm 119/852 = **14%**, ba card trọn vẹn + card 4 lộ mép |
| Visual weight cân | ✅ đầu màn nhẹ sau bốn vòng siết; xem F4 về đáy |
| CTA prominence | ⚠️ cùng vấn đề F2 |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ✅ |
| Optical alignment | ✅ numeral `15` đã cắt internal leading (`heroNumeralCapTrim`) |
| Typography tinh tế | ❌ 10 rung nội dung và **bốn** font weight; 700 chỉ phục vụ đúng numeral hero |
| Icon/text proportion | ✅ glyph 16px dẫn label 12px ở control sort |
| Surface/color hierarchy | ⚠️ primary dùng ở 5 chỗ — xem F3 |
| Mắt đi đúng flow | ⚠️ bị F2 làm gãy ở nửa dưới |

## Checklist 20 mục

**1. Screen structure** ✅ mục tiêu rõ (hôm nay học gì → deck nào). App Bar →
Hero → Heading → List → Bottom nav phân vùng rõ. Không có phần tử mồ côi.

**2. Visual hierarchy** ⚠️ Title 22/600 > section 12/600/ls.72 > body 16/600 >
supporting 12/400 — bốn cấp phân biệt được. Nhưng **F2**.

**3. Grouping** ✅ Item 4–8 < group 12–16 < section 16. Heading nghiêng về list
8,9px. Không dùng divider ở đâu spacing đã đủ. Card chỉ bọc thứ thật sự là một
khối (hero, mỗi deck).

**4. Alignment** ✅ Ba trục dọc, không có trục nào lệch 2–5px vô chủ đích. Card
cùng loại cùng padding (`insets` chỉ có giá trị trên scale). Không căn giữa
đoạn dài nào.

**5. Spacing & rhythm** ✅ **Không một giá trị nào ngoài `AppSpacing.scale`**,
trên cả 8 loại spacer và 6 loại inset. Padding ngang màn = 16 nhất quán.

**6. Typography** ❌ **10 rung nội dung** — gấp đôi mốc 3–5. Bốn weight
(400/500/600/700), trong đó 700 tồn tại cho **một** numeral. Xem F5.

**7. Component sizing** ✅ Deck tile cao 160 đều nhau. Không có kích thước tuỳ ý.

**8. Density** ✅ Ba deck trọn vẹn trong viewport đầu, đủ để hiểu ngữ cảnh.

**9. Balance** ⚠️ Đầu màn nhẹ. Đáy nặng bất thường vì FAB + bottom nav + nút
Study của card cùng chồng lên góc phải dưới.

**10. Color hierarchy** ⚠️ Xem F3.

**11. App bar** ✅ Cao 84 (`_toolbarHeight` giữ chỗ đúng bằng thứ nó dựng), title
rõ, hai action bên phải. Sort **không** nằm trong app bar — đúng, nó thuộc list.

**12. List / card** ⚠️ Mỗi item có hierarchy rõ. Nhưng trong một tile có **ba**
vùng chạm cạnh nhau: thân tile (mở), ⋮ (menu), Study (học) — và F1 khiến vùng ⋮
của card 3 bị FAB ăn mất.

**13. Filter / sort / chips** ✅ Chip workload cùng chiều cao, spacing đều.
Control sort ở rung `label-md`, thấp hơn heading — đúng thứ bậc.

**14. CTA** ❌ Xem F1 (FAB che content) và F2 (nhiều primary CTA).

**15. Scroll** ✅ Một `CustomScrollView`, không nested scroll. Bottom nav không
che item cuối (card 4 vẫn cuộn tới được).

**16. Responsive** ➖ Chỉ đo ở 393px, text scale 1.0, tiếng Anh. Chưa có bằng
chứng cho 360 / 412 / font scale 120–150% / chuỗi tiếng Việt dài. Cần render bổ
sung mới kết luận được.

**17. Safe area** ➖ Không kiểm được từ golden.

**18. Empty / loading / error** ➖ Với màn này: `deck_list_empty` là file riêng.
Loading/error của chính root chưa có golden.

**19. Content stress** ➖ Chỉ có bộ 4 deck. Chưa có 0 / 1 / 50+ item, chưa có
tên deck 2–3 dòng.

**20. Interaction** ⚠️ Thứ trông bấm được thì bấm được. Nhưng ⋮ và Study nằm gần
nhau ở cùng nửa phải của tile, và F1 làm chúng còn gần FAB nữa.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 1 | bốn cấp chữ rõ, nhưng ba primary CTA tranh nhau |
| Grouping | 2 | đo được, nghiêng đúng phía, hơn một bậc scale |
| Alignment | 2 | ba trục sạch, không lệch vô chủ đích |
| Spacing | 2 | 0 giá trị ngoài scale |
| Density | 2 | 14% hero, ba card trọn |
| Typography | 0 | 10 rung nội dung, 4 weight |
| CTA | 1 | primary bị pha loãng, FAB che content |
| Responsive | 1 | không có bằng chứng ngoài 393/scale 1.0 |
| **Tổng** | **11 / 16** | **Minor fix** |

## Findings

**F1 — FAB che nội dung của card thứ ba.** ❌ Level 1.
Trên render, FAB phủ hết chữ `100% le|arned` của Phrasal verbs. Lần đo trước
cho thấy nó đè 48 × 22px lên vùng menu ⋮, còn chừa dải 26px chạm được. Đây là
mục §14 "Floating button không che content" — trượt thẳng.
Hai kit đang bất đồng: `design_system/ui_kits/memox-app/DeckLevelScreen.jsx` đặt
Create trên app bar kèm ghi chú "no inset fixes it", app Flutter dùng FAB.
Đã đo, chưa sửa, chờ quyết định.

**F2 — Ba nút primary tô đặc trong một viewport.** ⚠️ Level 2.
Hero `Study 15 due cards` (full width) + `Study` trên card 1 + `Study` trên card
2, cùng một màu nền primary. Hero là hành động của **cả thư viện**, nút trên
card là hành động của **một** deck; vẽ cùng độ đặc thì lớp trên không còn là
cấp 1. Hướng rẻ nhất: nút trên tile hạ xuống tonal/outlined, giữ fill cho hero.

**F3 — Primary xuất hiện 5 chỗ.** ⚠️ Level 3.
Nút hero, hai nút Study, FAB, tab đang chọn, control sort. §10 nói primary chỉ
nhấn thứ **thực sự** quan trọng. Sửa F2 sẽ tự giảm còn 3.

**F4 — Góc phải dưới dồn ba thứ chạm được.** ⚠️
FAB, nút Study của card, và ⋮ cùng nằm ở nửa phải; §20 "action quan trọng không
nằm quá sát nhau". Hệ quả của F1 chứ không phải nguyên nhân riêng.

**F5 — Bốn font weight cho một màn.** ⚠️ Level 3.
400/500/600/700, trong đó 700 chỉ dùng cho numeral `15` (32/700 ×2). §6 nói
không quá 2 weight chính nếu không thật cần. Đây **có thể** là cần — numeral là
điểm nhấn cấp 1 duy nhất — nhưng nó đáng được ghi là một ngoại lệ có chủ đích
thay vì để mặc.
