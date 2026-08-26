# Match

Study · `lib/features/study/presentation/` · golden
`test/demo/goldens/study_match_light.png` · commit `ea80d3f7`

## Số đo

| | |
|---|---|
| Typography rungs | **5**, tất cả là nội dung — **ít nhất trong nhóm Study** |
| Rung | 16/500 (nội dung ô) · 12/600/ls1.1 · 12/600/ls.5 · 12/400 · 11/500/ls1.1 |
| Font weight | 400, 500, 600 |
| Spacer | 8×5, 16×2 — **toàn bộ trên scale** |
| Inset | 4×2, 8×42, 16×8 + **1×40 = viền của 20 ô** + 2×1 và 40×1 từ `MxSessionTopBar` |
| Trục text trái | 25 ×12 · 259 ×12 · 324 ×3 · 16 ×3 |
| Tap target | **11 chạm được, 0 dưới 48** |

Trục 25 và 259 — hai cột, mỗi cột 12 lần, hoàn toàn đối xứng.

## Level 1 — Correct

| | |
|---|---|
| Không overflow | ⚠️ **ô đầu tiên bị cắt bằng `…`** — xem F1 |
| Không overlap | ✅ |
| Safe area | ⚠️ dòng hướng dẫn sát mép dưới |
| Touch target | ✅ **11/11** — mọi ô đều là target lớn |
| Text đọc được | ✅ |
| Component đúng chức năng | ✅ |
| Responsive | ⚠️ đã cắt chữ ở 393px |

## Level 2 — Balanced

| | |
|---|---|
| Hierarchy rõ | ✅ mọi ô cùng cấp — đúng, chúng là các lựa chọn ngang hàng |
| Grouping đúng | ✅ hai ô cùng hàng là một cặp ứng viên; 8 trong hàng, 16 giữa hàng |
| Alignment tốt | ✅ **hai cột đối xứng tuyệt đối** (trục 25 và 259, mỗi trục 12 lần) |
| Spacing có rhythm | ✅ 0 giá trị app ngoài scale |
| Density hợp lý | ⚠️ 5 cặp lấp trọn màn, không cuộn — đúng cho một bàn ghép |
| Visual weight cân | ❌ **cột trái nặng gấp ~5 lần cột phải** — xem F2 |
| CTA prominence | ➖ không có CTA; chạm ô là hành động, và có hướng dẫn |

## Level 3 — Beautiful

| | |
|---|---|
| Whitespace | ⚠️ ô ngắn (`Be shy`) có rất nhiều khoảng trống, ô dài thì chật |
| Optical alignment | ✅ nội dung căn giữa trong ô, ô căn giữa theo hàng |
| Typography tinh tế | ✅ **5 rung** |
| Icon/text proportion | ✅ |
| Surface/color hierarchy | ✅ mọi ô trung tính — đúng, không ô nào được gợi ý |
| Mắt đi đúng flow | ❌ F2: mắt phải đọc 6 dòng bên trái để so với 1 từ bên phải |

## Checklist 20 mục

**1. Screen structure** ✅ Một mục tiêu. Dòng trạng thái
`5 CARDS DUE · ROUND 1 · BOARD 1/1 · 3 PAIRS LEFT` nói đủ bốn thứ trong một dòng.

**2. Visual hierarchy** ✅ Không ô nào nổi hơn ô nào — đúng cho một bài ghép.

**3. Grouping** ✅ 8 trong hàng, 16 giữa hàng — item gap < group gap, đúng quy tắc
nhanh của checklist.

**4. Alignment** ✅ Hai cột đối xứng.

**5. Spacing & rhythm** ✅ Giá trị app đều trên scale; 40 inset 1px là viền 20 ô.

**6. Typography** ✅ **5 rung — thấp nhất nhóm Study**, và chỉ một cỡ cho nội dung
ô (16/500) dù ô chứa tiếng Việt lẫn tiếng Hàn.

**7. Component sizing** ⚠️ Chiều cao ô thay đổi theo hàng (300–340px hiển thị),
nhưng **hai ô trong cùng hàng luôn bằng nhau**. Đây là quyết định đúng: bằng nhau
ở chỗ mắt so sánh, tự do ở chỗ không so sánh.

**8. Density** ⚠️ 5 cặp vừa đúng một màn, không cuộn. Tốt cho một bàn ghép — người
chơi thấy toàn bộ lựa chọn.

**9. Balance** ❌ F2.

**10. Color hierarchy** ✅ Bàn hoàn toàn trung tính. Primary chỉ ở chip chế độ và
thanh tiến độ. Đúng: tô màu một ô sẽ là gợi ý đáp án.

**11. App bar** ✅ Cùng `MxSessionTopBar` gọn như [study_browse](study_browse.md).

**12. List / card** ✅ **Toàn bộ ô là target**, không có vùng chạm con nào gây
nhầm.

**13. Filter / sort / chips** ➖

**14. CTA** ➖ Không có, và đúng. Hướng dẫn `Tap one tile, then its match` nói rõ
tương tác.

**15. Scroll** ✅ Không cuộn.

**16. Responsive** ⚠️ F1 — đã cắt chữ ở kích thước mặc định.

**17. Safe area** ⚠️ Dòng hướng dẫn là phần tử thấp nhất.

**18. Empty / loading / error** ➖ Bốn biến thể trạng thái (`_idle`, `_selected`,
`_paired`, `_wrong`) có golden riêng, ngoài 29 màn — **coverage tốt**.

**19. Content stress** ✅ Fixture rất mạnh: nghĩa dài 7 dòng, nghĩa ngắn 1 dòng,
tiếng Việt có dấu, tiếng Hàn. Và nó **lộ ra F1 và F2**.

**20. Interaction** ✅ **Chạm, không vuốt** — ngược với
[study_browse](study_browse.md) F1. Cùng một feature, hai mô hình tương tác, và
cái ở đây đúng.

## Điểm

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Hierarchy | 2 | mọi ô ngang hàng, đúng cho bài ghép |
| Grouping | 2 | 8 < 16, đúng quy tắc nhanh |
| Alignment | 2 | hai cột đối xứng tuyệt đối |
| Spacing | 2 | 0 giá trị app ngoài scale |
| Density | 2 | toàn bàn trong một màn, không cuộn |
| Typography | 2 | 5 rung, một cỡ cho nội dung ô |
| CTA | 2 | tương tác nói rõ, mọi ô là target lớn |
| Responsive | 0 | **đã cắt chữ ở 393px** |
| **Tổng** | **14 / 16** | **Pass** — nhưng F2 là vấn đề thiết kế thật |

## Findings

**F1 — Nội dung ô bị cắt bằng `…` ở kích thước mặc định.** ⚠️
Ô đầu tiên kết thúc bằng `khi một điều quen thuộc…`. §16 nói không truncate dữ
liệu quan trọng.
Biện hộ hợp lý: để **ghép**, người chơi không cần đọc hết định nghĩa — vài từ
đầu là đủ. Nếu đó là chủ đích thì cắt không phải lỗi.
Nhưng nếu vậy thì F2 mới là câu hỏi thật: vì sao ô lại chứa cả định nghĩa?

**F2 — Cột trái nặng gấp ~5 lần cột phải.** ❌
Bên trái là định nghĩa từ điển đầy đủ (`Empty, hollow / Trống rỗng, hụt hẫng
(Tính từ, dùng khi cảm thấy mất mát hoặc thiếu vắng sau chia tay, kết thúc…)`);
bên phải là một từ Hàn. Người chơi phải đọc tới 7 dòng để so với 1 từ, **năm
lần**.
§9 nói trọng lượng thị giác không được lệch bất thường sang một phía. Ở đây nó
lệch, và không phải vì bố cục mà vì **nội dung đưa vào ô sai cấp**: bài ghép cần
một gloss ngắn, không cần trường `back` đầy đủ.
Hướng: ô trái hiển thị phần trước dấu `(` — tức `Empty, hollow / Trống rỗng, hụt
hẫng` — và bỏ hẳn phần giải thích. Vừa cân hai cột, vừa xoá F1, vừa làm bài ghép
thực sự chơi được bằng cách quét mắt.

**F3 — Hai ô cùng hàng luôn bằng chiều cao, các hàng thì không.** ✅ ghi lại là
quyết định đúng.
§7 nói component cùng loại nên cùng chiều cao, nhưng cũng nói không được độn
chiều cao chỉ để lấp trống. Màn này chọn đúng ranh giới: bằng nhau ở chỗ mắt đặt
cạnh nhau để so (trong một hàng), tự do ở chỗ không so (giữa các hàng).
