# Bộ scenario kiểm thử tích hợp theo hành trình người dùng

| | |
|---|---|
| **Status** | active |
| **Purpose** | Định nghĩa phạm vi, điểm bắt đầu và dữ liệu chung cho người hoặc AI agent thực thi IT scenario trên chức năng hiện có |
| **Scope** | Navigation, Deck và Card đã hoàn thành; ngoài phạm vi là Review session, starter deck, reset learning progress, sync và backend |
| **Source of truth for** | Chỉ mục và quy ước thực thi bộ IT scenario hiện tại |
| **Depends on** | `../product.md`, `../business-rules.md`, `../use-cases.md`, `../wbs.md` |
| **Updated by task** | Yêu cầu viết IT scenario ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## 1. Mục tiêu

Bộ tài liệu này kiểm tra MemoX như một người dùng thật: mở app, chạm vào thành
phần nhìn thấy, nhập dữ liệu, điều hướng, đóng/mở lại app và quan sát kết quả.
Scenario MUST NOT gọi trực tiếp controller, repository, DAO hoặc sửa database để
bỏ qua UI trong phần **Các bước thực hiện**.

Một test seed MAY được dùng để chuẩn bị trạng thái mà UI hiện tại chưa thể tự tạo,
ví dụ card đã học hoặc card có ngày đến hạn. Việc seed chỉ thuộc **Tiền điều kiện**;
mọi bước kiểm tra sau đó vẫn MUST đi qua UI.

> **Bốn scenario mô tả định nghĩa "đến hạn" sẽ bị M5 thay.** Chúng **đúng với
> code hiện tại** — 60/60 chạy pass ở M4.11b — nên **không sửa trước** khi M5
> land, vì sửa sớm sẽ làm chúng fail trên bản đang chạy.
>
> | Scenario | Nói gì hôm nay | Phải thành gì sau M5 |
> |---|---|---|
> | `IT-DISC-005` bước 2–3 | tạo/xoá card ⇒ số **đến hạn** đổi 1 | đổi số **chưa học**; số đến hạn không nhúc nhích (BR-142, BR-150) |
> | `IT-LIFE-001` bước 3 | card mới có "badge đến hạn ngay" | card mới thuộc tập **Học mới**, chưa có lịch (BR-90, BR-144) |
> | `IT-ORG-003` bước 2 | "mới/đến hạn ngay trước" | hai tập tách hẳn, không cùng một thứ tự |
> | `IT-ORG-00x` due badge | `C-P-NEW` "đến hạn ngay" | `C-P-NEW` là **chưa học**, không phải đến hạn |
>
> **Và profile fixture `C-P-NEW` sẽ vi phạm invariant 28.** Bảng profile trong
> `00-agent-execution-guide.md` định nghĩa nó là *New, đến hạn ngay,
> `due_at = T0 − 1 giờ`*. Sau M5 đó là một thẻ **chưa học xong nhưng đã có lịch**
> — trạng thái BR-144 cấm. Profile phải thành `learned_at` NULL **và** `due_at`
> NULL, và cần một profile mới cho "đã học, đến hạn" mà các scenario về badge đang
> thực sự cần.
>
> Lý do gốc: `due_at IS NULL` từng nghĩa là *đến hạn ngay*; từ BR-142 nó nghĩa là
> *chưa học xong*. Xem bảng nợ code trong `data-model.md` — cùng một thay đổi,
> cùng thời điểm.

AI agent MUST đọc theo thứ tự:

1. File này — phạm vi và dữ liệu nghiệp vụ chung.
2. [`00-agent-execution-guide.md`](00-agent-execution-guide.md) — cách setup,
   kết luận và báo cáo mà không suy đoán.
3. [`scenario-catalog.md`](scenario-catalog.md) — readiness, profile, setup,
   cleanup và traceability của đúng scenario ID.
4. File capability chứa các bước của scenario.

## 2. Phạm vi hiện tại

| Nhóm | Trạng thái | Tài liệu |
|---|---|---|
| Giao thức thực thi cho AI agent | Bắt buộc đọc | [`00-agent-execution-guide.md`](00-agent-execution-guide.md) |
| Catalog từng scenario ID | Bắt buộc tra cứu | [`scenario-catalog.md`](scenario-catalog.md) |
| Khởi động, navigation, continuity | Có thể kiểm thử | [`01-navigation-and-continuity.md`](01-navigation-and-continuity.md) |
| Vòng đời root deck | Có thể kiểm thử | [`02-root-deck-lifecycle.md`](02-root-deck-lifecycle.md) |
| Cây deck, `content_type`, move | Có thể kiểm thử | [`03-deck-tree-and-content-type.md`](03-deck-tree-and-content-type.md) |
| Tìm kiếm, lọc, sắp xếp, tiến độ deck | Có thể kiểm thử | [`04-deck-discovery-and-progress.md`](04-deck-discovery-and-progress.md) |
| Vòng đời card | Có thể kiểm thử | [`05-card-lifecycle.md`](05-card-lifecycle.md) |
| Tìm kiếm, metadata, lọc, tiến độ card | Có thể kiểm thử | [`06-card-discovery-and-organization.md`](06-card-discovery-and-organization.md) |

Các luồng sau MUST NOT được ghi nhận là pass của sản phẩm hiện tại:

- UC-01 — thư viện starter deck chưa có UI.
- UC-05 — Study mới là màn placeholder; nút Study chỉ thông báo chưa khả dụng.
- UC-07 — Reset learning progress chưa có luồng hoàn chỉnh.
- Đổi scheduler của root deck sau khi tạo chưa có bề mặt UI hoàn chỉnh.
- Import/export, media, authentication, sync và backend nằm ngoài MVP hiện tại.

## 3. Quy ước scenario

| Trường | Ý nghĩa |
|---|---|
| ID | Ổn định theo nhóm: `IT-NAV`, `IT-DECK`, `IT-TREE`, `IT-DISC`, `IT-CARD`, `IT-ORG` |
| Ưu tiên `P0` | Luồng chính hoặc bất biến nghiệp vụ; hỏng thì không thể demo/release slice Deck/Card |
| Ưu tiên `P1` | Chức năng quan trọng nhưng có đường vòng hoặc không chặn luồng chính |
| Ưu tiên `P2` | Trạng thái phụ, usability hoặc dữ liệu lớn |
| Tiền điều kiện | Trạng thái có trước khi người dùng bắt đầu scenario |
| Các bước | Chỉ thao tác qua bề mặt nhìn thấy và kết quả quan sát được |
| Hậu điều kiện | Dữ liệu còn lại để quyết định có thể nối scenario hay phải reset app data |

`Readiness`, execution profile, setup và cleanup không lặp lại trong từng
scenario. Chúng nằm trong một dòng duy nhất theo ID tại `scenario-catalog.md`.
Giá trị cleanup chính là hợp đồng hậu điều kiện để scenario kế tiếp không vô
tình nhận dữ liệu sót lại.

Mỗi scenario SHOULD chạy độc lập. Nếu chạy nối chuỗi, tester MUST dùng đúng hậu
điều kiện của scenario trước làm tiền điều kiện cho scenario sau.

## 4. Môi trường và dữ liệu chuẩn

### 4.1. Môi trường

- Target chính: Android, locale tiếng Việt, kích thước màn hình điện thoại.
- Web MAY dùng làm kênh E2E development nhưng không thay thế vòng xác nhận Android.
- Với scenario offline, bật chế độ máy bay **sau khi app và test data đã sẵn sàng**.
- “Khởi động lại app” nghĩa là đóng hẳn process rồi mở lại, không chỉ chuyển tab.

### 4.2. Dữ liệu tạo qua UI

| Mã | Dữ liệu |
|---|---|
| `D-EB` | Root deck `Giao tiếp hằng ngày`, scheduler Eight Box |
| `D-SM2` | Root deck `IELTS 2026`, scheduler SM-2 |
| `D-BRANCH` | Deck con `Vocabulary`, loại `deck` sau khi có child |
| `D-LEAF` | Deck con `Academic words`, loại `card` sau khi tạo card đầu tiên |
| `C-001` | Front `abandon`, back `từ bỏ`, example `He abandoned the plan.`, pronunciation `/əˈbændən/` |
| `C-002` | Front `benevolent`, back `nhân từ`, hint `starts with bene`, tag `IELTS` |
| `C-003` | Front `concise`, back `ngắn gọn`, tag `Writing`, flagged |

### 4.3. Dữ liệu seed dành riêng cho trạng thái học

Các mã `S-PROGRESS`, `S-DUE` và `S-LARGE` có contract xác định tại
[`00-agent-execution-guide.md`](00-agent-execution-guide.md), và loader hiện
thực chúng nằm ở `integration_test/support/it_fixtures.dart` (v1).

Agent MUST NOT tự tạo SQL hoặc sửa database để vượt blocker. Seed MUST dùng nội
dung giả, không dùng dữ liệu cá nhân thật.

## 5. Traceability nghiệp vụ

| Nguồn | Scenario chính |
|---|---|
| UC-02 — tạo root deck | `IT-DECK-001`, `IT-DECK-002`, `IT-DECK-003`, `IT-DECK-004` |
| UC-03 — sửa/xoá deck | `IT-DECK-005`, `IT-DECK-006`, `IT-DECK-007`, `IT-DECK-008`, `IT-TREE-007`, `IT-TREE-008`, `IT-TREE-014` |
| UC-04 — quản lý card | `IT-CARD-001` tới `IT-CARD-011`; `IT-ORG-001` tới `IT-ORG-012` |
| UC-06 — danh sách deck và tiến độ | `IT-DISC-001` tới `IT-DISC-008`; `IT-ORG-011` |
| UC-08 — tạo phần tử con, xác lập loại | `IT-TREE-001` tới `IT-TREE-008`; `IT-TREE-013` |
| UC-09 — di chuyển deck | `IT-TREE-009` tới `IT-TREE-013` |
| M4.12 — demo Deck/Card E2E | `IT-NAV-006`, `IT-NAV-007`, các scenario `UI-FIXTURE` và `UI-LARGE` |

Bảng trên giúp người đọc định hướng. Traceability machine-readable theo từng ID
nằm tại [`scenario-catalog.md`](scenario-catalog.md) và là nguồn canonical.

## 6. Definition of ready cho AI agent

Một scenario chỉ sẵn sàng để agent chạy khi:

- ID tồn tại đúng một lần trong scenario file và đúng một lần trong catalog.
- Catalog ghi `READY`.
- Setup ID có recipe hoặc artifact được triển khai.
- Agent điều khiển được platform/profile yêu cầu.
- Expected result có thể kết luận theo quy tắc assertion trong execution guide.

Thiếu một điều kiện trên thì agent MUST báo `BLOCKED` hoặc `DOC-DRIFT`; không tự
điền phần còn thiếu bằng phỏng đoán.
