# Hướng dẫn AI agent thực thi IT scenario

| | |
|---|---|
| **Status** | active |
| **Purpose** | Cung cấp execution contract xác định để AI agent chọn, chuẩn bị, chạy và báo cáo IT scenario mà không tự suy diễn |
| **Scope** | Quy trình agent, readiness, setup, cleanup, fixture, bằng chứng và kết luận; không định nghĩa lại hành vi sản phẩm |
| **Source of truth for** | Giao thức AI agent thực thi bộ IT scenario |
| **Depends on** | `README.md`, `scenario-catalog.md`, `../business-rules.md`, `../use-cases.md`, `../wbs.md` |
| **Updated by task** | Yêu cầu làm tài liệu thân thiện với AI agent ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

## 1. Điểm bắt đầu bắt buộc

AI agent MUST thực hiện theo thứ tự:

1. Đọc [`README.md`](README.md) để xác định phạm vi sản phẩm hiện có.
2. Tìm ID trong [`scenario-catalog.md`](scenario-catalog.md).
3. Kiểm tra `Readiness`, `Profile`, `Setup` và `Cleanup` của ID đó.
4. Đọc scenario gốc và các UC/BR được catalog liên kết.
5. Chuẩn bị dữ liệu bằng setup recipe trong tài liệu này.
6. Thao tác toàn bộ bước scenario qua UI.
7. Ghi bằng chứng và kết luận theo mục 8.
8. Chạy cleanup đã khai báo, kể cả khi scenario fail.

Khi được giao “chạy toàn bộ”, agent MUST chạy `READY` theo thứ tự P0 → P1 → P2.
Các dòng `FIXTURE-BLOCKED` và `KNOWN-GAP` vẫn phải xuất hiện trong báo cáo tổng,
nhưng không được chen vào run queue như một scenario được kỳ vọng pass.

Nếu scenario, catalog và UC/BR không thống nhất, agent MUST dừng scenario với
trạng thái `DOC-DRIFT`; MUST NOT tự chọn một phiên bản rồi tiếp tục.

## 2. Trạng thái readiness

| Giá trị | Agent được làm gì |
|---|---|
| `READY` | Có thể dựng tiền điều kiện bằng UI hoặc khả năng development hiện có và chạy ngay |
| `FIXTURE-BLOCKED` | Scenario hợp lệ nhưng fixture xác định chưa được triển khai; MUST NOT tự sửa database để giả lập |
| `KNOWN-GAP` | Hành vi mong đợi là đúng theo nghiệp vụ nhưng bề mặt UI hiện tại được biết là chưa đủ; chạy để xác nhận gap, MUST NOT ghi product pass |

`FIXTURE-BLOCKED` chỉ được đổi thành `READY` sau khi fixture có đường dẫn artifact,
cách nạp và kiểm tra phiên bản được bổ sung vào mục 6. Việc một agent có thể viết
SQL không làm blocker này biến mất.

## 3. Execution profile

| Profile | Yêu cầu |
|---|---|
| `UI` | Chạm/nhập/scroll qua thành phần nhìn thấy; phù hợp manual và E2E UI |
| `UI-RESTART` | Như `UI`, đồng thời đóng hẳn process và mở lại tại bước được chỉ định |
| `UI-DEVICE` | Cần quyền điều khiển thiết bị ngoài app, ví dụ chế độ máy bay |
| `DEV-LINK` | Cần mở development URL/deep link; không áp dụng cho release navigation thông thường |
| `UI-FIXTURE` | Các bước thuần UI nhưng setup cần fixture được phê duyệt |
| `UI-LARGE` | Như `UI-FIXTURE`, thêm dữ liệu lớn và kiểm đếm đầy đủ |

Automation harness của M4.12 hiện chưa tồn tại. `Profile` mô tả **cách scenario
phải được tự động hoá**, không khẳng định executable test đã có. Agent được giao
viết automation MUST báo dependency M4.12 trước khi tuyên bố scenario đã chạy tự động.

## 4. Môi trường xác định

| Thuộc tính | Giá trị chuẩn |
|---|---|
| Platform xác nhận chính | Android |
| Build | Development, trừ khi task yêu cầu flavor khác |
| Locale | `vi` |
| Timezone | `Asia/Seoul` |
| Dữ liệu ban đầu | Theo setup ID trong catalog, không dùng dữ liệu cá nhân |
| Restart | Đóng hẳn process rồi mở lại; chuyển tab không được tính là restart |
| Offline | Bật chế độ máy bay sau khi setup hoàn tất và giữ tới hết cleanup cần kiểm tra |

Với fixture phụ thuộc thời gian, mốc chuẩn là:

```text
T0 = 2026-08-05T09:00:00+09:00
```

Agent MUST xác nhận clock của fixture là `T0` trước khi assert số lượng Due hoặc
due badge. Nếu môi trường không pin được clock, các scenario dùng `S-DUE` hoặc
`S-PROGRESS` là `BLOCKED`, không phải `FAIL`.

## 5. Setup recipe dựng hoàn toàn qua UI

### SETUP-EMPTY

1. Xác nhận đây là development/test installation, không chứa dữ liệu người dùng thật.
2. Xoá app data của đúng package test hoặc gỡ/cài lại development build.
3. Mở app và xác nhận root deck list ở empty state.

Nếu không chứng minh được package là bản test, agent MUST dừng; không được xoá dữ liệu.

### SETUP-D-EB

1. Chạy `SETUP-EMPTY`.
2. Tạo root `Giao tiếp hằng ngày` và chọn Eight Box.
3. Quay về root list, xác nhận đúng một deck `D-EB`.

### SETUP-D-SM2

1. Chạy `SETUP-EMPTY`.
2. Tạo root `IELTS 2026` và chọn SM-2.
3. Quay về root list, xác nhận đúng một deck `D-SM2`.

### SETUP-ROOTS

1. Chạy `SETUP-EMPTY`.
2. Tạo `D-EB` với Eight Box.
3. Tạo `D-SM2` với SM-2.
4. Xác nhận root list có đúng hai root trên.

### SETUP-TREE-UNSET

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo `Vocabulary` (`D-BRANCH`).
3. Trong `D-BRANCH`, chọn tạo deck và tạo `Academic words` (`D-LEAF`).
4. Dừng khi `D-LEAF` còn rỗng và chưa định loại; không tạo card.

Kết quả: `D-BRANCH` là deck chứa deck; `D-LEAF` là deck con `unset`.

### SETUP-UNSET-CHILD:&lt;name&gt;

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo một deck con có tên đúng bằng tham số `<name>`.
3. Dừng khi deck mới rỗng và chưa định loại.

Ví dụ `SETUP-UNSET-CHILD:Grammar` tạo một child `Grammar` ở trạng thái `unset`.

### SETUP-TREE-CARD

1. Chạy `SETUP-TREE-UNSET`.
2. Trong `D-LEAF`, chọn tạo card và lưu `C-001` theo dữ liệu chuẩn trong README.
3. Xác nhận mở `D-LEAF` đi thẳng vào card list và thấy `C-001`.

### SETUP-CARD-BASIC

1. Chạy `SETUP-CARD-PLAIN`.
2. Mở edit `C-002`, thêm tag `IELTS`.
3. Mở edit `C-003`, thêm tag `Writing` và bật cờ.
4. Xác nhận card list có đúng ba card, tag và cờ như README.

### SETUP-CARD-PLAIN

1. Chạy `SETUP-TREE-CARD`.
2. Tạo thêm `C-002` và `C-003` qua UI nhưng chưa thêm tag hoặc cờ.
3. Xác nhận card list có đúng ba card và cả ba đều chưa flagged.

### SETUP-CARD-TAGS

1. Chạy `SETUP-CARD-PLAIN`.
2. Mở `C-001`, thêm hai tag `IELTS` và `Writing`.
3. Quay về list và xác nhận row `C-001` có đúng hai chip trên.

### SETUP-CARD-EMPTY-TYPED

1. Chạy `SETUP-TREE-CARD`.
2. Xoá `C-001` qua UI và xác nhận.
3. Dừng tại card list rỗng.

Kết quả: `D-LEAF` rỗng nhưng vẫn là deck loại card.

### SETUP-CARD-SINGLE

Chạy `SETUP-TREE-CARD` và không tạo thêm card. `D-LEAF` có đúng `C-001`.

### SETUP-MOVE-TREE

1. Chạy `SETUP-TREE-CARD`.
2. Trong `D-EB`, tạo branch `Grammar`.
3. Trong `Grammar`, tạo child tạm `Tenses`, sau đó xoá `Tenses`.
4. Giữ `Grammar` rỗng nhưng loại deck để làm move target.

### SETUP-DECK-TYPED-WITH-CHILD

1. Chạy `SETUP-D-EB`.
2. Trong `D-EB`, tạo `Grammar`.
3. Trong `Grammar`, chọn tạo deck và tạo `Tenses`.
4. Dừng khi `Grammar` có đúng một child `Tenses`.

### SETUP-DECK-TYPED-EMPTY

1. Chạy `SETUP-DECK-TYPED-WITH-CHILD`.
2. Xoá `Tenses` qua UI và xác nhận.
3. Dừng khi `Grammar` rỗng nhưng vẫn chỉ cho tạo deck.

### SETUP-CYCLE-TREE

1. Chạy `SETUP-D-EB`.
2. Tạo đường `Vocabulary > Academic words > Level 1`, ở mỗi cấp chọn tạo deck.
3. Dừng khi cả ba deck đều là loại deck và `Level 1` rỗng.

### SETUP-CROSS-SCHEDULER-MOVE

1. Chạy `SETUP-ROOTS`.
2. Dưới `D-EB`, tạo `Source branch`, rồi tạo một child để source thành subtree.
3. Dưới `D-SM2`, tạo `Target branch`, tạo rồi xoá một child để target rỗng nhưng loại deck.
4. Xác nhận source và target nằm dưới hai root khác scheduler.

### SETUP-SEARCH-TREES

1. Chạy `SETUP-ROOTS`.
2. Dưới `D-EB`, tạo đường `Vocabulary > Academic words`.
3. Dưới `D-SM2`, tạo đường `Reading > Academic archive`.
4. Quay về level mà scenario yêu cầu trước khi nhập query.

### SETUP-DEEP-10

1. Chạy `SETUP-D-EB`.
2. Tạo tuần tự `Level 02` tới `Level 10`, mỗi deck nằm trong deck trước.
3. Xác nhận breadcrumb có root ở cấp 1 và `Level 10` ở cấp 10.

### SETUP-ROOT-TRIO

1. Chạy `SETUP-EMPTY`.
2. Tạo ba root theo thứ tự `beta`, `Alpha`, `gamma`, cùng scheduler Eight Box.
3. Dừng tại root list.

## 6. Fixture contract

| | |
|---|---|
| **Artifact path** | `integration_test/support/it_fixtures.dart` |
| **Version** | `v1` |
| **Cách nạp** | `ItFixtures.loadDueLibrary(harness)` / `ItFixtures.loadLargeDeck(harness)` — gọi trước `launchApp`, clock đã pin `T0` |
| **Reset** | Mỗi loader tự wipe trước khi seed, nên nạp hai lần cho đúng một kết quả |
| **Đường ghi** | Deck/card qua đúng repository contract với clock tiêm theo từng thẻ; riêng review state ghi trực tiếp bảng `card_review_states`, vì writer sản phẩm duy nhất của state ngoài-initial là scheduler (M5, chưa tồn tại). Khi M5 có, nâng cấp trung thực là thay bước ghi đó bằng review thật. |

Đặc tả dữ liệu giữ nguyên bên dưới; loader ở trên là hiện thực của nó.

### S-PROGRESS và S-DUE

Hai mã cùng trỏ tới fixture tree dùng clock `T0`:

```text
Due library (root, Eight Box)
├── Mixed due (card deck)
└── No due group (deck)
    └── Future only (card deck)
```

`Mixed due` chứa:

| Card | Front | State hiển thị | Due hiển thị tại T0 | Created at | Flagged |
|---|---|---|---|---|---|
| `C-P-NEW` | `new-visible` | New | Đến hạn ngay | T0 − 1 giờ | Không |
| `C-P-BEGIN` | `beginning-visible` | Beginning | Đến hạn ngay | T0 − 2 giờ | Có |
| `C-P-REVIEW` | `reviewing-visible` | Reviewing | Còn 2 ngày | T0 − 3 giờ | Không |
| `C-P-MASTER` | `mastered-visible` | Mastered | Còn 30 ngày | T0 − 4 giờ | Không |

Expected aggregates tại `T0`:

- All = 4.
- Due = 2.
- New = 1.
- Flagged = 1.
- Mastered = 1/4 = 25%.
- Phân bố state = 1 New, 1 Beginning, 1 Reviewing, 1 Mastered.

`Future only` chứa đúng một card `future-only`, state Reviewing, due sau `T0`
hai ngày, không flagged và không có tag. Vì vậy:

- Tile root `Due library`: 5 card toàn cây, 2 due, 2 sub-deck trực tiếp.
- Tại level `Due library`: `Mixed due` có 2 due; `No due group` có 0 due.
- Tại level `No due group`: bộ lọc Due không khớp child nào.

Không được thêm cột/trạng thái nghiệp vụ mới chỉ để phục vụ fixture.

### S-LARGE

| Thuộc tính | Giá trị |
|---|---|
| Deck | `Large deck 65` |
| Số card | 65 |
| Front | `card-001` tới `card-065` |
| Back | `meaning-001` tới `meaning-065` |
| State | Tất cả New |
| Flag/tag | Không |
| Thứ tự tạo | `card-001` trước, `card-065` sau |

Expected: lần đọc đầu hiện 50/65; sau tải thêm hiện 65/65; mọi front xuất hiện
đúng một lần trong tập kết quả cuối.

## 7. Cleanup contract

| Cleanup ID | Hành động |
|---|---|
| `CLEAN-RESET` | Xác nhận package test rồi xoá app data; mở lại và kiểm tra empty state |
| `CLEAN-DELETE-CREATED` | Xoá bằng UI mọi root/card do scenario tạo; nếu không thể hoàn tất thì dùng `CLEAN-RESET` |
| `CLEAN-PRESERVE` | Không xoá; chỉ dùng khi task tường minh muốn scenario sau nhận state này |
| `CLEAN-NONE` | Scenario không làm thay đổi dữ liệu |

Catalog mặc định dùng `CLEAN-RESET` để giữ tính độc lập. Agent MUST ghi cleanup
đã chạy hay bị chặn trong báo cáo.

## 8. Kết luận và bằng chứng

### 8.1. Trạng thái run

| Trạng thái | Khi nào dùng |
|---|---|
| `PASS` | Tất cả bước và kết quả quan sát khớp |
| `FAIL` | Setup hợp lệ, thao tác tới được, nhưng ít nhất một kết quả sai |
| `BLOCKED` | Không dựng được setup/readiness hoặc không điều khiển được môi trường |
| `KNOWN-GAP-CONFIRMED` | Scenario `KNOWN-GAP` tái hiện đúng khoảng trống đã ghi |
| `DOC-DRIFT` | Scenario/catalog/UC/BR mâu thuẫn hoặc expected không đủ xác định |
| `NOT-RUN` | Chưa thực thi |

Agent MUST NOT đổi `BLOCKED` thành `PASS`, và MUST NOT coi
`KNOWN-GAP-CONFIRMED` là product pass.

### 8.2. Bằng chứng tối thiểu

- Một ảnh hoặc artifact ở kết quả cuối của scenario.
- Ảnh tại bước fail đầu tiên nếu status là `FAIL`.
- Ghi nhận build/flavor, platform, locale và setup ID.
- Với restart/offline/deep-link: ghi nhận hành động môi trường đã thực hiện.
- Với count/filter/progress: ghi actual và expected bằng số.
- Không đưa nội dung card cá nhân, SQL, stack trace hoặc secret vào báo cáo.

### 8.3. Mẫu báo cáo

```markdown
Scenario: IT-...
Run status: PASS | FAIL | BLOCKED | KNOWN-GAP-CONFIRMED | DOC-DRIFT | NOT-RUN
Build: development
Platform: Android <version/device>
Locale/timezone: vi / Asia/Seoul
Setup: SETUP-...
Started at: <ISO-8601>

| Step | Result | Evidence | Note |
|---|---|---|---|
| 1 | PASS/FAIL/BLOCKED | <artifact path> | <actual vs expected> |

First divergence: <step or none>
Cleanup: <ID + PASS/BLOCKED>
```

## 9. Quy tắc assertion không mơ hồ

- `A hoặc B` chỉ hợp lệ khi scenario hoặc guide liệt kê cả A và B là hai kết quả
  được chấp nhận. Kết quả khác là `FAIL`.
- “Thông báo dễ hiểu” nghĩa là có user-facing copy mô tả nguyên nhân/hành động;
  copy MUST NOT chứa SQL, stack trace, exception class hoặc ID kỹ thuật.
- Với localized copy, assert ý nghĩa và semantic role; chỉ assert nguyên văn khi
  scenario đặt chuỗi trong dấu ngoặc kép.
- Target disabled có thể không nhận tap. Agent assert target không kích hoạt và
  lý do vẫn quan sát được; không gọi callback trực tiếp để chứng minh.
- Nếu expected vẫn có hai cách hiểu sau khi áp dụng các quy tắc trên, kết luận
  `DOC-DRIFT` và dừng tại bước đó.
