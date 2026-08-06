# Master flow — memox (MVP)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Cho thấy các use case nối vào nhau thành hành trình nào, thứ mà đọc từng UC riêng lẻ không thấy được |
| **Scope** | Đồ thị chuyển tiếp giữa UC-01…UC-09, tách theo đối tượng nghiệp vụ. Ngoài phạm vi: nội dung của từng UC, mọi luật nghiệp vụ, và mọi chi tiết màn hình |
| **Source of truth for** | Đồ thị chuyển tiếp giữa các UC · điểm vào của từng luồng · ánh xạ UC → milestone xây nó |
| **Depends on** | `document-conventions.md`, `product.md`, `business-rules.md`, `use-cases.md` |
| **Updated by task** | M99.1 |
| **Last updated** | 2026-08-07 |

---

## 1. Tài liệu này là gì, và không là gì

`use-cases.md` đặc tả **từng** UC đầy đủ chín mục. Nó cố ý không vẽ đồ thị nối
chúng lại, nên câu "sau khi tạo deck xong thì người dùng đi đâu" không có chỗ nào
trả lời — mỗi UC tự mô tả mình và im lặng về những UC bên cạnh.

Tài liệu này chỉ giữ **các cạnh của đồ thị đó**. Mọi đỉnh đều trỏ về một UC hoặc
một BR bằng ID.

**MUST NOT** đọc sơ đồ ở đây như một đặc tả. Theo `document-conventions.md` §5,
luật nghiệp vụ sống ở `business-rules.md` và luồng sống ở `use-cases.md`; nhãn
trong sơ đồ là **rút gọn để đọc được**, không phải bản gốc. Khi sơ đồ và UC/BR
mâu thuẫn, **UC/BR thắng**, và sơ đồ sai là một defect phải sửa.

**Tách theo đối tượng, không theo hành động.** Mục 3–5 chia theo *deck*, *card*,
*review* — không có mục riêng cho "tạo deck" hay "xoá deck". Một tài liệu cho mỗi
hành động sẽ nhân số file theo số nút bấm, và phần lớn chúng sẽ chỉ có một sơ đồ
ba đỉnh.

---

## 2. Master flow — toàn app

Hành trình từ lúc mở app tới lúc vào được một phiên ôn tập. Nhánh nào đi sâu vào
một đối tượng thì dừng ở đó và tiếp tục ở mục tương ứng.

```mermaid
flowchart TD
    A["Mở app"] --> B["Khởi tạo database"]
    B -->|"Thất bại"| B1["Màn hình lỗi có nút thử lại · UC-01 E1"]
    B --> C{"Đã có deck nào chưa?"}

    C -->|"Chưa"| D["Empty state, hai lối đi · UC-06 A1"]
    D -->|"Thư viện starter"| E["Chọn starter deck và chế độ ôn tập · UC-01"]
    D -->|"Tạo deck mới"| F["Tạo root deck · UC-02"]

    C -->|"Rồi"| G["Danh sách deck kèm tiến độ · UC-06"]
    E --> G
    F --> G

    G --> H["Mở một deck"]
    H --> I{"content_type của deck"}
    I -->|"deck"| J["Danh sách deck con · UC-06 A3"]
    I -->|"card"| K["Danh sách card · UC-04"]
    I -->|"unset"| L["Deck rỗng, tạo được cả hai loại · UC-08"]

    J --> H
    L -->|"Tạo deck con"| J
    L -->|"Tạo card"| K

    H --> M["Quản lý deck: đổi tên, xoá, di chuyển · mục 3"]
    G --> N["Bắt đầu phiên ôn tập · mục 5"]
    K --> N
    N --> G
```

**`J --> H` là vòng lặp cố ý.** Deck lồng tới 10 cấp (BR-55) và một cấp bất kỳ
lại là "mở một deck" của cấp trên nó; màn hình là **một** màn đệ quy chứ không
phải hai màn khác nhau cho root và cho deck con.

---

## 3. Deck

Mọi thao tác trên cây deck. Điểm vào là một deck bất kỳ đang mở.

```mermaid
flowchart TD
    A["Một deck đang mở"] --> B{"Người dùng chọn gì"}

    B -->|"Bấm Create"| C{"Deck này là gì"}
    C -->|"root"| C1["Chỉ Create deck · BR-59"]
    C -->|"con · unset"| C2["Create card và Create deck · BR-61"]
    C -->|"con · card"| C3["Chỉ Create card · BR-66"]
    C -->|"con · deck"| C4["Chỉ Create deck · BR-66"]
    C1 --> D["Tạo phần tử con và xác lập content_type trong một transaction · UC-08"]
    C2 --> D
    C3 --> D
    C4 --> D
    D -->|"Cha đã ở cấp 10"| D1["Chặn trước khi ghi · UC-08 E4, BR-55"]
    D -->|"Huỷ giữa chừng"| D2["Không tạo gì và content_type không đổi · UC-08 A4"]
    D -->|"Thành công"| D3["Cây được vẽ lại"]

    B -->|"Đổi tên"| E["Validate rồi lưu · UC-03, BR-01"]

    B -->|"Xoá"| F["Xác nhận, nêu rõ số deck con và số card sẽ mất · UC-03, BR-04"]
    F -->|"Đồng ý"| F1["Xoá cascade toàn bộ descendant · BR-03"]
    F -->|"Huỷ"| F2["Không xảy ra gì · UC-03 A4"]

    B -->|"Di chuyển"| G{"Bốn phép kiểm, theo thứ tự · UC-09"}
    G -->|"Đích là chính nó hoặc descendant"| G1["Chặn · E1, BR-70"]
    G -->|"Đích có content_type card"| G2["Chặn · E2, BR-64"]
    G -->|"Root đích khác scheduler hoặc generation"| G3["Chặn, đề nghị reset tường minh · E3, BR-74"]
    G -->|"Vượt cấp 10"| G4["Chặn · E5, BR-55"]
    G -->|"Hợp lệ"| G5["Đổi parent và root_deck_id toàn subtree trong một transaction · BR-71"]

    B -->|"Đưa content_type về unset"| H{"Deck có rỗng không"}
    H -->|"Không"| H1["Chặn, phải xoá hết nội dung trước · UC-03 E3, BR-68"]
    H -->|"Rỗng"| H2["Xác nhận rồi đặt unset · UC-03 A3"]

    B -->|"Đổi chế độ ôn tập · chỉ root"| I{"first_review_at"}
    I -->|"NULL"| I1["Mở khoá: cảnh báo rồi khởi tạo lại review state toàn cây · UC-03, BR-14"]
    I -->|"Đã có"| I2["Khoá, hiện kèm lối đi sang Reset learning progress · UC-03 A1, BR-13"]
    I2 --> I3["UC-07 · mục 5"]
```

**Nhánh `I` là chỗ hai đối tượng gặp nhau.** Chế độ ôn tập là thuộc tính của deck
nhưng bị khoá bởi một sự kiện của review, nên đường thoát duy nhất khi đã khoá
nằm ở mục 5. Ẩn nó đi thay vì hiện trạng thái khoá là điều BR-13 cấm.

---

## 4. Card

Điểm vào là một deck đã có `content_type = 'card'` (BR-63). Card **đầu tiên** của
một deck `unset` không đi qua đây — nó được tạo ở UC-08 và chính nó xác lập
`content_type`.

```mermaid
flowchart TD
    A["Deck có content_type = card"] --> B["Danh sách card · UC-04"]
    B -->|"Chưa có card nào"| B1["Empty state kèm hành động Thêm card · UC-04 A3"]

    B --> C{"Người dùng chọn gì"}

    C -->|"Thêm"| D["Nhập mặt trước và mặt sau"]
    D --> E{"Validate · BR-07, BR-08"}
    E -->|"Rỗng hoặc quá dài"| E1["Lỗi inline ở đúng ô · UC-04 E1, E2"]
    E -->|"Hợp lệ"| F["Tạo card và review state trong cùng transaction, theo scheduler của root · BR-09"]
    F -->|"Ghi thất bại"| F1["Hiện lỗi, giữ nội dung, không tạo card thiếu review state · UC-04 E3"]
    F -->|"Thành công"| G["Giữ form mở và xoá trống các ô · UC-04 A4"]
    G --> B

    C -->|"Sửa"| H["Đổi nội dung; review state và history không đổi · UC-04 A1, BR-10"]
    C -->|"Xoá"| I["Xác nhận, xoá kèm review state và history của card đó · UC-04 A2"]
    I --> I1["content_type giữ nguyên kể cả khi đó là card cuối cùng · BR-67"]
```

**`I1` là cạnh dễ vẽ sai nhất trong tài liệu này.** Xoá hết card **không** đưa
deck về `unset`; muốn đổi loại phải qua nhánh `H` ở mục 3, và đó là một hành động
được xác nhận riêng (BR-68).

---

## 5. Review

Hai UC dùng chung một đối tượng: phiên ôn tập (UC-05) và việc đặt lại tiến độ học
(UC-07). Chúng nằm chung mục vì generation là thứ nối chúng — và là thứ khiến một
phiên đang mở có thể bị vô hiệu hoá từ màn khác.

```mermaid
flowchart TD
    A["Bấm ôn tập trên một deck"] --> B{"Còn card đến hạn không · BR-22"}
    B -->|"Không"| B1["Empty state tích cực kèm thời điểm đến hạn gần nhất; KHÔNG tạo session · UC-05 E1, BR-29"]
    B -->|"Còn"| C["Tạo study_session in_progress mang root_deck_id và generation hiện tại · BR-45, BR-79"]
    C --> D["Lấy tối đa 50 card riêng biệt trong cả cây · BR-23, BR-24"]
    D --> E["Render nút đánh giá từ supportedActions: 2 với eight_box, 4 với sm2 · BR-30"]
    E --> F["Hiện mặt trước và tiến độ phiên"]
    F --> G["Người dùng lật rồi chọn một action"]

    G --> H{"session.generation còn khớp root không · BR-46"}
    H -->|"Lệch"| H1["Từ chối ghi; session invalidated, end_reason stale_generation · UC-05 E4, BR-84"]
    H -->|"Khớp"| I{"Lượt đầu tiên của card này trong phiên"}
    I -->|"Đúng"| J["review_kind = scheduled: tính lịch mới rồi ghi history · BR-77"]
    I -->|"Không"| K["review_kind = relearning: chỉ cập nhật last_reviewed_at · BR-78"]

    J --> L{"Action có phải forgotten hoặc again"}
    K --> L
    L -->|"Đúng"| M["Card quay lại trong phiên sau ít nhất 3 card khác · UC-05 A1, BR-26"]
    L -->|"Không"| N["Card rời hàng đợi · BR-28"]
    M --> F
    N --> O{"Hàng đợi còn card không"}
    O -->|"Còn"| F
    O -->|"Hết"| P["session completed, end_reason NULL; hiện tổng kết · BR-81"]

    G -->|"Thoát giữa phiên"| Q["session abandoned, end_reason user_exit; mọi đánh giá đã ghi vẫn giữ · UC-05 A3, BR-82, BR-86"]

    R["Đặt lại tiến độ học trên root · UC-07"] --> S["Xác nhận, nêu rõ giữ gì và mất gì; chọn chế độ mới ngay tại đây"]
    S --> T["Một transaction: generation +1, first_review_at NULL, khởi tạo lại review state toàn cây, mọi session in_progress → invalidated · BR-40, BR-42, BR-44, BR-47, BR-83"]
    T --> U["review_history giữ nguyên, mang generation cũ · BR-43"]
    T -.->|"Phiên đang mở ở màn khác"| H1
```

**Cạnh nét đứt `T -.-> H1` là lý do hai UC này ở chung một mục.** Reset chạy ở màn
hình A làm mọi phiên đang mở ở màn hình B hết hiệu lực; người dùng ở B chỉ biết
điều đó khi bấm đánh giá lần tiếp theo. Đọc riêng UC-05 hoặc riêng UC-07 đều không
thấy được cạnh này.

---

## 6. UC nào được xây ở đâu

Ánh xạ UC → milestone. **Trạng thái của milestone sống ở `wbs.md`**, không lặp
lại ở đây; cột cuối chỉ nói cái gì đã có trong `lib/` hôm nay, vì đó là thứ sơ đồ
ở trên không thể hiện.

| UC | Đối tượng | Xây ở | Có trong `lib/` hôm nay |
|---|---|---|---|
| UC-01 | deck | M4.12a | Template tự cài lúc khởi động qua `app/startup/fixture_seeder_widget.dart`. **Màn thư viện để người dùng duyệt template và chọn chế độ ôn tập cho bản sao thì chưa có** — bước 4–7 của UC-01 |
| UC-02 | deck | M4.10 | Đủ |
| UC-03 | deck | M4.10 | Đổi tên, xoá kèm impact, đưa `content_type` về `unset` đã có. **Đổi chế độ ôn tập chưa có** — không có use case nào cho nó |
| UC-04 | card | M4.11 | Đủ, và **nhiều hơn UC-04 mô tả**: cờ, tag và ba trường phụ (BR-92…BR-95) |
| UC-05 | review | M5 | Chưa xây. `lib/features/review/` mới có một repository chưa có method và một placeholder screen |
| UC-06 | deck | M4.10 | Đủ, cộng tìm kiếm toàn subtree — thứ UC-06 không nhắc tới |
| UC-07 | review | M5 | Chưa xây |
| UC-08 | deck | M4.10 | Đủ |
| UC-09 | deck | M4.10 | Đủ |

### Ba chỗ tài liệu và code đã lệch

Ghi lại chứ **không** sửa ở đây: cả ba đều thuộc `use-cases.md`, đang
`frozen for MVP`, và M99.1 không có quyền sửa nó ngoài dòng trỏ sang tài liệu này.

1. **UC-04 không nhắc cờ và tag.** BR-93 và BR-95 khai `Related: UC-04`, nhưng
   dòng `Business rules` của UC-04 chỉ liệt kê BR-07…BR-10, BR-63, BR-67. Tham
   chiếu một chiều: BR biết UC, UC không biết BR.
2. **UC-06 không nhắc tìm kiếm.** `search_decks_use_case.dart` tồn tại và màn
   danh sách có ô tìm kiếm toàn thư viện; UC-06 xếp tìm kiếm card vào mục "cố ý
   không đặc tả" (S1) và không nói gì về tìm deck.
3. **UC-01 mô tả một màn thư viện chưa tồn tại.** Phần đã xây là seed tự động cho
   demo, không phải luồng người dùng chọn. Hai thứ này khác nhau ở chỗ ai quyết
   định `scheduler_type` của bản sao.
