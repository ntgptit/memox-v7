# WBS Study — việc còn lại của chức năng học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ riêng cho chức năng Study — mọi việc còn lại để UC-05 dùng được thật |
| **Scope** | Task còn lại của Study từ M5.7 trở đi · nợ kỹ thuật của Study · việc bị chặn |
| **Source of truth for** | Trạng thái task Study từ M5.7 · nợ kỹ thuật của Study |
| **Depends on** | `document-conventions.md` · `wbs.md` · `business-rules.md` · `use-cases.md` |
| **Updated by task** | M5.8 (controller gọi use case) |
| **Last updated** | 2026-08-08 |

`docs/wbs.md` giữ M5.0…M5.6 đã hoàn thành và không nhắc lại ở đây. File này giữ
**những gì còn lại**, đánh số tiếp từ M5.7 để không ID nào trùng và mọi tham chiếu
cũ vẫn đúng.

## Vì sao cần một file riêng

M5.0…M5.6 đều `done` trong ledger chính, nhưng **người dùng chưa mở được phiên học
nào**. Đó không phải mâu thuẫn — nó là hệ quả của việc chia mốc theo *tầng* thay vì
theo *đường đi của người dùng*: mỗi tầng xong và có test, còn thứ nối chúng lại thì
không thuộc mốc nào.

Đo được bằng lệnh, không phải cảm nhận:

| Câu hỏi | Trả lời hôm nay |
|---|---|
| `lib/features/study/presentation/screens/` có gì | chỉ `study_placeholder_screen.dart` |
| route `/study` trỏ vào đâu | placeholder |
| Ai đọc `studySessionControllerProvider` trong `lib/` | không ai |
| Ai dựng sáu widget mode trong `lib/` | không ai |

Nghĩa là controller và toàn bộ widget mode hiện là **code chết** từ góc nhìn app —
chỉ test chạm tới. Bài học ghi lại ở đây để mốc sau không lặp: một mốc UI chỉ được
tính `done` khi có **đường đi từ màn hình người dùng thật sự mở được**, không phải
khi widget của nó có test.

## Thứ tự thi hành

M5.7 chặn mọi thứ còn lại: chưa có màn phiên học thì không kiểm được luồng, không
đo được thị giác, không viết được integration test qua UI. M5.17 đã chốt xong nên
không còn quyết định nào treo trước nó.

```
M5.17 (chốt 8 điểm lệch design ↔ BR)  ✔ done
M5.7 (màn hình + route)
 ├── M5.8  (sửa AD-12)          ── độc lập, làm song song được
 ├── M5.9  (ba đường BR-103)
 ├── M5.10 (tổng kết phiên)
 ├── M5.11 (tùy chọn hai tầng)
 ├── M5.12 (ca chặn/bỏ qua stage)
 ├── M5.13 (mức `almost` của match)
 └── M5.15 (integration test qua UI) ← cần M5.9, M5.10, M5.12
M5.18…M5.20 (dựng năm màn theo design) ← cần M5.7
M5.14 blocked bởi UC-07
M5.16 sau khi mọi màn đã ổn định
```

### M5.7 · Màn hình phiên học và lối vào

- **Status:** **done** — analyze sạch, 1512 test xanh, visual audit xanh, guard sạch
- **Goal:** Người dùng mở app, thấy số thẻ, bấm học, và đi hết một phiên.
- **Scope:** `StudyEntryScreen` thay `StudyPlaceholderScreen`;
  `StudySessionScreen` đọc `StudySessionController` và render đúng widget mode;
  route phiên học mang `deckId`, `kind` và mode đã chọn; xoá placeholder.
- **Out of scope:** tổng kết phiên (M5.10); ba đường lúc mở app (M5.9).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `lib/features/study/presentation/screens/`, route mới trong
  `app/router/`, đăng ký Widgetbook
- **Acceptance criteria:**
  - [x] Ánh xạ mode → widget là **`Map`**, không phải `switch`. Guard AD-18 chỉ
        cho một switch trên `StudyMode` và nó ở `study_mode.dart`; handler không
        được trả widget vì `domain/` không biết Flutter.
  - [x] Deck `eight_box` đi được trọn chuỗi `browse → match → guess → recall →
        fill`; deck `sm2` đi `browse → self_assess`.
  - [x] Bốn trạng thái loading, empty, error, loaded đều có widget test.
  - [x] Không đường nào mở phiên ôn khi tập đến hạn rỗng (BR-29, BR-145).
  - [x] `grep -rn "Text('" lib/features/study/presentation` không có kết quả.
  - [x] Render ở 320×568 và `textScaler` 2.0 → `takeException()` là null.
  - [x] Light và dark đều có widget test.
  - [x] `study_placeholder_screen.dart` bị xoá, không còn tham chiếu.
**Visual audit bắt một lỗi thật, và đó là lý do nó tồn tại.** Hai ô đếm dùng
`MxPillButton(onPressed: null)` cho có hình pill; component render chúng thành
**disabled** — chữ ở alpha 38%, không thuộc palette. Mà chúng không phải nút bị
vô hiệu hoá, chúng là số liệu đọc. Giờ là `Text` với token thật.

**Guard bắt hai vi phạm, một cái em vừa tạo thêm.** `StudyEntryScreen` đọc thẳng
`studyRepositoryProvider` để biết mode nào khả dụng — đúng loại vi phạm M5.8
sinh ra để dọn, và em thêm một cái mới. Sửa ngay bằng `GetReviewModesUseCase` và
`StudyReviewModes` controller. Cái thứ hai: `ref.read` trong `build()` lấy giá
trị mà không đăng ký, nên màn hình có thể hiện state không bao giờ được báo là
đã đổi; notifier giờ đọc trong callback.

**Lượt recursive review sau khi gate xanh tìm ra chỗ thứ ba.** `_actionFor` suy
đúng/sai từ **vị trí** trong danh sách action — "sai là cái đầu, đúng là cái
cuối". Đúng với `eight_box` và là trùng hợp: với `sm2` nó chấm `easy` cho mọi câu
đúng. BR-107 vốn đã nằm trên scheduler dưới dạng `binaryAction`, và hàm ấy trả
`null` cho thuật toán không có stage chấm điểm — đúng để chỗ sai lộ ra. Giờ
`presentation` hỏi scheduler thay vì chép lại luật.

- **Vì sao ánh xạ bằng `Map`.** `study_labels_widget.dart` đã dùng đúng cách này
  và vì đúng lý do: một `switch` thứ hai trên `StudyMode` là chỗ chính sách của
  một mode rò ra khỏi handler. `Map` đọc y hệt và giữ luật.
- **Dependencies:** M5.4c, M5.5
- **Tests required:** widget test 4 trạng thái × 2 thuật toán; test chuyển stage;
  test deck `sm2` không hiện màn chọn mode
- **Checklist phases:** 14.4, 15.3

### M5.8 · Controller gọi use case, không gọi repository

- **Status:** **done** — analyze sạch, 1513 test xanh, guard sạch
- **Goal:** Không tầng `presentation/` nào đọc thẳng repository.
- **Scope:** bốn lời gọi trong `study_session_controller.dart` —
  `deckContext`, `markBrowsed`, `nextTurn`, `saveTurnProgress` — chuyển thành use
  case; thêm phép kiểm chặn tái phát.
- **Out of scope:** đổi contract của repository.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `lib/features/study/domain/usecases/`, controller đã sửa, test kiến trúc
- **Acceptance criteria:**
  - [x] `grep -n "repository\." study_session_controller.dart` chỉ còn lời gọi
        qua use case.
  - [x] Mỗi use case mới là **một** tương tác, không phải một lớp bọc mỏng gom
        nhiều thứ.
  - [x] Có test kiến trúc (hoặc rule guard) chặn `presentation/` gọi thẳng
        phương thức repository — hiện không phép kiểm nào bắt được điều này.
**Phép kiểm mới so hình dạng AST, không so chuỗi.** Bản đầu hỏi "nguồn có chứa
`.read(` và `RepositoryProvider` không" — và bắt luôn mọi
`SomeUseCase(ref.read(repoProvider)).call()`, tức đúng cái pattern cần giữ. Điều
quan trọng là thứ **được gọi lên** có *chính là* lượt đọc hay chỉ chứa một lượt
đọc bên trong. Nó bắt cả hai dạng: gọi chuỗi, và gọi qua biến cục bộ — dạng thứ
hai chính là dạng đã trốn qua bốn PR.

**Phép kiểm đã được chứng minh bằng cách tái tạo vi phạm.** Xanh trên code sạch
không chứng minh gì; em đổi một lời gọi về dạng cũ, test đỏ đúng dòng đó, rồi
khôi phục.

**`start()` gộp ba lượt đọc thành một.** Trước đây mở phiên là ba lời gọi — mở
phiên, hỏi deck chạy thuật toán nào, rồi lấy tập thẻ. Ba lượt đọc là ba ảnh chụp:
một Reset rơi vào giữa để lại màn hình cầm phiên của trước đó và tập thẻ của sau
đó. `StudySessionStartModel` trả cả bốn thứ trong một lượt (AD-13).

- **Đây là lỗi do M5.3 và M5.5 để lại.** `CLAUDE.md` viết rõ *"A controller calls
  a use case; it does **not** read a repository"*, và cả `check_architecture.sh`
  lẫn `architecture_boundary_test` đều không bắt được — chúng kiểm **import**,
  mà `presentation/` được phép import `domain/repositories/`. Thiếu phép kiểm là
  lý do lỗi sống sót qua bốn PR, nên tiêu chí thứ ba quan trọng ngang hai cái đầu.
- **Dependencies:** không
- **Tests required:** test kiến trúc mới; test controller hiện có vẫn xanh
- **Checklist phases:** 5.2, 15.2

### M5.9 · Ba đường lúc mở app (BR-103)

- **Status:** todo
- **Goal:** Mở app còn phiên dở của **cùng ngày học** thì được chọn, không bị ép.
- **Scope:** màn chọn ba đường — tiếp tục phiên dở, Học mới, Ôn tập; chọn một
  trong hai đường sau thì phiên dở chuyển `abandoned`/`user_exit`.
- **Out of scope:** phiên của ngày khác — đã tự đóng `interrupted` ở M5.5.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget overlay ba đường, nối vào `StudyEntryScreen`
- **Acceptance criteria:**
  - [ ] Phiên `in_progress` cùng ngày học → hiện đủ ba đường.
  - [ ] Chọn Học mới hoặc Ôn tập → phiên cũ thành `abandoned`/`user_exit`, **không**
        phải `interrupted` (BR-103).
  - [ ] Tiếp tục → phiên cũ giữ nguyên `status`, và `recall` tiếp đúng
        `remaining_ms` đã lưu (BR-133).
  - [ ] Không có phiên dở → không hiện màn này chút nào.
- **`ResumeStudyDayUseCase` đã có từ M5.2 và chưa ai gọi.** Mốc này là phần UI của
  nó, không phải viết lại logic.
- **Dependencies:** M5.7
- **Tests required:** widget test ba nhánh; test khẳng định `end_reason` đúng ở
  mỗi nhánh
- **Checklist phases:** 14.4, 15.3

### M5.10 · Màn tổng kết phiên

- **Status:** todo
- **Goal:** Kết thúc phiên nói được vừa rồi đã xảy ra chuyện gì.
- **Scope:** màn tổng kết tối thiểu sau khi phiên `completed`: số thẻ đã học
  xong, số thẻ đã ôn, số lượt sai; đường quay lại deck.
- **Out of scope:** thống kê dài hạn, biểu đồ, chuỗi ngày học — ngoài MVP.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget tổng kết + chuỗi ARB
- **Acceptance criteria:**
  - [ ] Phiên `learning` xong hiện số thẻ vừa hoàn tất chuỗi (BR-144).
  - [ ] Phiên `reviewing` xong hiện số thẻ đã ôn và số lượt sai.
  - [ ] Phiên kết thúc bất thường (`abandoned`/`failed`) **không** hiện tổng kết
        như một thành tựu — nó nói phiên đã dừng và vì sao, không tô hồng.
  - [ ] Số liệu đến từ **một** lượt đọc, không phải bốn (AD-13).
- **M5.5 có "màn tổng kết phiên tối thiểu" trong Scope nhưng không dựng.** Ghi ở
  đây thay vì sửa entry cũ: mốc đó đã `done` với phần vòng đời, và việc còn thiếu
  là một mốc riêng chứ không phải một dòng chưa tick.
- **Dependencies:** M5.7
- **Tests required:** widget test cho ba loại kết thúc; test một-lượt-đọc
- **Checklist phases:** 14.4, 15.3

### M5.11 · Tùy chọn học hai tầng (BR-147, BR-148)

- **Status:** todo
- **Goal:** Người dùng đặt được số thẻ mỗi phiên và thứ tự thẻ mới.
- **Scope:** đọc/ghi `app_settings`; parse và ghi `decks.study_config` trên root;
  màn cài đặt tối thiểu; giá trị hiệu lực = root nếu có, ngược lại mặc định.
- **Out of scope:** cài đặt ngoài Study.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** use case + màn cài đặt + widget
- **Acceptance criteria:**
  - [ ] `card_limit` và `new_card_order` sửa được và có hiệu lực ở phiên **kế
        tiếp**, không phải phiên đang chạy (BR-139).
  - [ ] Deck root đặt được giá trị riêng; deck con **không** có tùy chọn riêng và
        tra qua `root_deck_id` (BR-147) — bất biến 20 vẫn xanh.
  - [ ] `new_card_order = random` cho thứ tự khác `created` trên cùng tập thẻ
        (BR-148).
  - [ ] `study_config` hỏng hoặc không đọc được → dùng mặc định, **không** chặn
        việc học.
- **`effectiveOptions` hiện đọc `app_settings` và bỏ qua `study_config`**, có ghi
  chú trong code là "chưa có ai ghi". Mốc này là lúc ghi, nên cũng là lúc parse.
- **Dependencies:** M5.7
- **Tests required:** test hai nhánh giá trị hiệu lực; test JSON hỏng; test
  `random` khác `created`
- **Checklist phases:** 14.4, 15.1

### M5.12 · Các ca stage bị chặn hoặc bỏ qua, ở UI (BR-99, BR-124, BR-153)

- **Status:** todo
- **Goal:** Stage không dựng được nội dung thì hành xử đúng, không render hỏng.
- **Scope:** `guess` không dựng được một question cụ thể → **chặn**: không render,
  không ghi lượt, không bỏ qua thẻ, không tiến checkpoint (BR-124); stage không
  còn thẻ nào trong phiên học → bỏ qua chứ không hiện rỗng (BR-99); `match` dưới
  hai cặp (BR-153).
- **Out of scope:** phần chọn mode — đã xong ở M5.4a.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** nhánh xử lý trong `StudySessionScreen` và các widget mode
- **Acceptance criteria:**
  - [ ] `GuessModeHandler.buildQuestion` trả null → màn hình **không** render câu
        hỏi rỗng và **không** ghi lượt nào.
  - [ ] Phiên học có stage không thẻ nào → stage đó bị bỏ qua, phiên vẫn chạy tiếp.
  - [ ] `match` dưới hai cặp trong phiên học → bỏ qua; trong phiên ôn → đã bị vô
        hiệu hoá từ màn chọn.
  - [ ] Không ca nào ở trên làm phiên kẹt hoặc kết thúc sớm.
- **Handler đã trả `null` đúng chỗ từ M5.4b; chưa ai xử lý `null` đó.** Đây là
  phần còn thiếu ở phía gọi, không phải ở phía luật.
- **Dependencies:** M5.7
- **Tests required:** widget test cho từng ca; test khẳng định không lượt nào
  được ghi ở ca chặn
- **Checklist phases:** 14.4, 15.3

### M5.13 · Mức phản hồi `almost` của `match` (BR-120)

- **Status:** todo
- **Goal:** `match` có mức phản hồi giữa, và nó không rò vào lịch sử.
- **Scope:** mức `almost` khi chọn gần đúng; ánh xạ như **sai** theo BR-107; vào
  tập không đạt của round.
- **Out of scope:** mức phản hồi cho mode khác.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `match_mode.dart` + widget bàn ghép
- **Acceptance criteria:**
  - [ ] `almost` vào tập không đạt của round (BR-116, BR-120).
  - [ ] `almost` **không** xuất hiện trong `study_answers.action` — cột đó chỉ
        nhận action canonical của thuật toán (BR-120, BR-132).
  - [ ] Có test khẳng định đúng hai điều trên, cùng lúc.
- **M5.4b đóng mốc với tiêu chí BR-120 **chưa có test**, vì widget khi đó chỉ sinh
  đúng/sai nhị phân nên không có gì để kiểm.** Mốc này thêm mức phản hồi và test
  cùng lúc — thêm mức trước rồi test sau là cách tiêu chí ấy bị bỏ quên lần nữa.
- **Dependencies:** M5.7
- **Tests required:** test tập không đạt; test `action` canonical
- **Checklist phases:** 14.4, 15.1

### M5.14 · Reset learning progress đóng phiên đang mở (BR-83)

- **Status:** blocked — chờ UC-07
- **Goal:** Reset một cây deck thì mọi phiên đang mở của nó đóng `invalidated`.
- **Scope:** nối `invalidateSessionsForRoot` vào luồng Reset của Deck.
- **Out of scope:** bản thân Reset — đó là UC-07.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** một lời gọi trong use case Reset của Deck
- **Acceptance criteria:**
  - [ ] Reset khi phiên đang mở → phiên thành `invalidated`/`scheduler_reset`
        (BR-83), **không** phải `stale_generation`.
  - [ ] Lượt đã ghi vẫn còn trong `study_answers` (BR-86).
- **Thao tác đã có và có test từ M5.5; thiếu đúng một caller.** Chặn thật:
  `lib/features/deck/` chưa có use case Reset nào. Nối dây là **quyết định
  cross-feature**: Deck sẽ phải phụ thuộc contract của Study, và đó là hướng phụ
  thuộc mới trong repo này — cần quyết định tường minh chứ không lặng lẽ thêm.
- **Dependencies:** UC-07 (chưa có mốc)
- **Tests required:** test luồng Reset đóng phiên
- **Checklist phases:** 14.4, 15.1

### M5.15 · Integration test qua UI và kênh E2E

- **Status:** todo
- **Goal:** Chứng minh UC-05 chạy thật trên thiết bị, qua màn hình.
- **Scope:** `integration_test/study_flow_test.dart` đi qua UI; giữ kênh Web sống.
- **Out of scope:** Playwright nối CI — M7.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `integration_test/`
- **Acceptance criteria:**
  - [ ] Cold start → mở deck → học mới → đi hết chuỗi stage → thẻ nhận
        `learned_at` và hạn đầu ngày kế tiếp.
  - [ ] Thẻ vừa học xong **không** mở được phiên ôn trong ngày (BR-145).
  - [ ] Thẻ thiếu `example` vẫn hoàn tất chuỗi (BR-114, BR-144) — qua UI lần này.
  - [ ] `flutter test integration_test/` exit 0 trên emulator Android.
  - [ ] `flutter build web` vẫn exit 0 (AD-04).
- **M5.6 đã kiểm những điều này ở mức use case và ghi rõ phần qua UI còn nợ.** Mốc
  này đóng nợ đó; không viết lại phần đã có.
- **Dependencies:** M5.7, M5.9, M5.10, M5.12
- **Tests required:** đây **là** task test
- **Checklist phases:** 15.5

### M5.16 · Kiểm thị giác và tiếp cận cho màn Study

- **Status:** todo
- **Goal:** Màn Study đạt cùng chuẩn thị giác như Deck và Card.
- **Scope:** đăng ký Widgetbook đủ màn mới; visual audit theo MX-VIS-001; tương
  phản, vùng chạm, thứ tự đọc màn hình.
- **Out of scope:** đổi token — nếu thiếu token thì đó là mốc riêng.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** entry Widgetbook, báo cáo audit
- **Acceptance criteria:**
  - [ ] Mọi màn Study mới có entry Widgetbook.
  - [ ] Tương phản chữ đạt ngưỡng ở cả light và dark.
  - [ ] Nút action của phiên đạt vùng chạm tối thiểu, kể cả khi có bốn nút `sm2`.
  - [ ] Đồng hồ `recall` đọc được bằng screen reader, không chỉ bằng màu.
- **Dependencies:** M5.7, M5.9, M5.10
- **Tests required:** golden/visual audit; test text scale 2.0
- **Checklist phases:** 12.x, 15.3

### M5.17 · Chốt tám điểm lệch giữa design và BR

- **Status:** **done** — chủ dự án chốt 2026-08-08: ảnh là UI concept, nghiệp
  vụ đã chốt thắng ở mọi điểm lệch
- **Goal:** Không viết một dòng UI nào dựa trên phỏng đoán về nghiệp vụ.
- **Scope:** tám mục ở `wireframes/m5-study-modes.md` §7; ghi quyết định vào đúng
  tài liệu sở hữu luật đó.
- **Out of scope:** dựng màn — M5.7, M5.18…M5.20.
- **Editable documents:** `docs/wbs-study.md`, `docs/wireframes/m5-study-modes.md`,
  và tài liệu frozen **chỉ khi** quyết định thật sự đổi luật
- **Output:** §7 chuyển từ "chưa chốt" sang quyết định, mỗi mục kèm lý do
- **Acceptance criteria:**
  - [x] Tám mục đều có quyết định, không mục nào để ngỏ.
  - [x] Không BR nào phải sửa: phán quyết là nghiệp vụ thắng, nên tài liệu
        frozen giữ nguyên và design là bên nhường.
  - [x] §7.5 cần trường mới → **không dựng ở MVP**, nên không có mốc migration
        nào bị nhét vào mốc UI.
  - [x] `check_docs.py` xanh sau khi sửa.
**Phán quyết rút thành ba quy tắc**, và chúng áp cho mọi design về sau: design
mâu thuẫn BR `active` → theo BR; design đề xuất thứ chưa luật nào nói → không
tự đặt luật, để ngoài MVP; design khác ở chỗ thuần thị giác → giữ design.

Kết quả cụ thể: bỏ icon loa và icon bút chì, bỏ dòng mô tả phụ của `guess`, bỏ
vuốt-lùi, bỏ hai họ màu, đổi `BOARD` thành `ROUND`, đổi pill `REVIEW` thành
nhãn `browse`, bỏ phần trộn NEW+REVIEW; **thêm** đồng hồ cho `recall` mà ảnh
không có.

**Chỉ lấy UI concept từ ảnh.** Màu, kiểu chữ, khoảng cách và component đều lấy
của dự án; không dựng bảng màu hay theme mới. Hai họ màu của ảnh bị bỏ vì bộ
token không có màu nghĩa là "mode nào", và màu xanh lá gần nhất là `success` —
nghĩa là **đúng**. Dùng nó làm màu nhận dạng `recall` thì pill trông như một
phán quyết trước khi người dùng trả lời.

- **Ba mục có giá cao hơn hẳn năm mục còn lại.** §7.2 (một phiên trộn thẻ mới và
  thẻ ôn) đụng thẳng BR-142 — chính luật chủ dự án yêu cầu bắt buộc ở đợt
  brainstorm; đảo nó là làm lại `session_kind`, cách lấy thẻ và luồng hoàn tất
  chuỗi học mới. §7.3 (bỏ đồng hồ `recall`) xoá bốn BR và hai cột đã có trong
  schema v5. §7.4 (icon loa) mở lại quyết định hoãn media của AD-03. Năm mục còn
  lại là chuỗi hiển thị hoặc token.
- **Dependencies:** không
- **Tests required:** không — đây là task quyết định; test đi cùng mốc thi hành
- **Checklist phases:** 2.x, 14.4

### M5.18 · Khung phiên học theo design

- **Status:** todo
- **Goal:** Năm màn dùng chung một khung, dựng một lần.
- **Scope:** thanh trên (✕, pill mode, thanh tiến trình, bộ đếm `n / m`), dòng
  ngữ cảnh, dòng gợi ý dưới cùng.
- **Out of scope:** thân của từng mode — M5.19, M5.20.
- **Đã chốt ở M5.17:** bộ đếm chỉ đếm tập của phiên đang chạy (§7.2); mode
  `recall` thay bộ đếm bằng thời gian còn lại (§7.3).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget khung trong `presentation/widgets/sections/`, chuỗi ARB
- **Acceptance criteria:**
  - [ ] ✕ đóng phiên qua `leave()` và ghi `abandoned`/`user_exit` (BR-82) —
        **không** phải pop route suông.
  - [ ] Bộ đếm và thanh tiến trình đọc từ state, không tự đếm.
  - [ ] Pill và thanh tiến trình dùng token **đang có** — `primaryAccent`,
        `progressTrack`, `progressFill`. **Không** thêm token màu nào, và
        **không** dùng `success` làm màu nhận dạng mode (§7.8).
  - [ ] Dòng gợi ý đổi theo mode và đến từ ARB.
  - [ ] Bộ đếm **không** trộn hai tập thẻ (BR-142, §7.2).
  - [ ] Ở `recall`, thanh trên hiện thời gian còn lại (BR-128, §7.3), và nó đọc
        được bằng screen reader chứ không chỉ bằng màu.
  - [ ] Render ở 320×568 và `textScaler` 2.0 không tràn.
- **Dependencies:** M5.7, M5.17
- **Tests required:** widget test cho ✕, cho bộ đếm, cho năm dòng gợi ý
- **Checklist phases:** 14.4, 15.3

### M5.19 · `browse` và `match` theo design

- **Status:** todo
- **Goal:** Hai màn khớp ảnh 12 và 13.
- **Scope:** thẻ hai nửa có nhãn `KOREAN`/`MEANING` và đường kẻ giữa; bàn ghép
  hai cột với ba trạng thái ô.
- **Out of scope:** vuốt để lùi — **đã chốt là bỏ** (§7.7).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** cập nhật `study_card_face_section_widget.dart` và
  `match_board_section_widget.dart`
- **Acceptance criteria:**
  - [ ] `browse` hiện hai nhãn và hai mặt, không nút chấm điểm nào (BR-111).
  - [ ] Ô `match` đã ghép **ở lại bàn** với dấu ✓ và trạng thái mờ — bản hiện tại
        xoá ô khỏi bàn, và đó là điểm khác design.
  - [ ] Ô đang chọn dùng nền primary đặc, chữ đảo màu, đạt tương phản ở cả hai
        theme — màu từ `ColorScheme`, không đặt thẳng trong widget.
  - [ ] Ô đã ghép dùng `success` đúng nghĩa "đúng", không phải để trang trí.
  - [ ] Ô đã ghép không bấm lại được.
  - [ ] Pill của `browse` dùng nhãn `browse`, không phải `REVIEW` (§7.1).
  - [ ] Dòng ngữ cảnh của `match` ghi **round**, không phải board (§7.6).
- **Dependencies:** M5.18
- **Tests required:** widget test ba trạng thái ô; test `browse` không có action
- **Checklist phases:** 14.4, 15.3

### M5.20 · `guess`, `recall` và `fill` theo design

- **Status:** todo
- **Goal:** Ba màn khớp ảnh 14, 15, 16 — gồm cả state thứ hai chưa có ảnh.
- **Scope:** hàng lựa chọn có huy hiệu chữ cái và trạng thái sau trả lời; bố cục
  đề trên / đáp án dưới / nút dưới cùng cho `recall` và `fill`.
- **Out of scope:** icon bút chì và loa — **đã chốt là không dựng** (§7.4);
  dòng mô tả phụ của `guess` — **đã chốt là không dựng** (§7.5).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** cập nhật ba widget mode
- **Acceptance criteria:**
  - [ ] `guess` sau trả lời: đáp án đúng xanh + ✓, lựa chọn sai đã chọn đỏ + ✕,
        ba lựa chọn còn lại mờ — và **không** nhận thêm lượt nào (BR-126).
  - [ ] Huy hiệu A–E là thứ tự hiển thị, **không** phải định danh; lượt vẫn ghi
        theo `cardId` (BR-125).
  - [ ] Mỗi lựa chọn chỉ hiện nghĩa, không có dòng mô tả phụ (§7.5).
  - [ ] `recall` không có icon loa và icon bút chì (§7.4).
  - [ ] `recall` có state đã lật, và nó khoá kết cục (BR-130).
  - [ ] `fill` có state đã chấm, hiện đúng/sai và không nhận nhập tiếp.
  - [ ] Hai state thiếu ảnh được vẽ theo BR chứ không theo phỏng đoán, và ghi rõ
        trong wireframe là do agent đề xuất.
- **Dependencies:** M5.18
- **Tests required:** widget test cho từng state; test huy hiệu không phải định danh
- **Checklist phases:** 14.4, 15.3

## Nợ kỹ thuật của Study

| Nợ | Vì sao còn | Đóng ở |
|---|---|---|
| Controller đọc thẳng repository ở 4 chỗ | không phép kiểm nào bắt được; guard kiểm import, không kiểm lời gọi | M5.8 |
| `study_config` chưa được parse | chưa có ai ghi nó | M5.11 |
| BR-120 chưa có test | `match` chưa có mức `almost` để kiểm | M5.13 |
| BR-83 chưa có caller | UC-07 chưa tồn tại | M5.14 |
| `remaining_ms` chưa được nối vào UI resume | cần màn phiên học trước | M5.7 + M5.9 |
| Widget mode chưa ai dựng trong `lib/` | chưa có màn ghép | M5.7 |
| ~~Ảnh wireframe chưa có trong repo~~ | chủ dự án đã thả vào `wireframes/assets/m5-study-modes/` | xong |
| `match` xoá ô đã ghép khỏi bàn | dựng trước khi có design | M5.19 |
| Hai state thứ hai của `recall`/`fill` chưa có ảnh | design mới cung cấp state đầu | M5.20 — vẽ theo BR, ghi rõ là agent đề xuất |

## Việc không thuộc Study nhưng chặn Definition of Done

**Golden `deck_screens_demo_test` lệch 0.06% trên Windows.** Hỏng sẵn trên `main`
từ trước M5 — kiểm bằng cách stash toàn bộ thay đổi rồi chạy lại trên cây sạch.
Chúng là golden bound theo Windows, chạy ở CI job riêng, nên gate CI vẫn xanh và
số test báo trong M5 đều chạy với `--exclude-tags golden`. Cần một lượt điều tra
riêng, **không gộp vào mốc Study** — gộp vào sẽ làm một mốc Study đỏ vì lý do
không thuộc Study.

**Config chết trong guard.** Rule `memox.architecture.single_study_mode_dispatch`
loại trừ `study_mode_resolver.dart`, nhưng rule naming cấm suffix `_resolver`
dưới `domain/` — không file nào tên đó tồn tại được. Phần exclude ấy nên bị xoá.
