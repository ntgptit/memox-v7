# WBS Study — việc còn lại của chức năng học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ riêng cho chức năng Study — mọi việc còn lại để UC-05 dùng được thật |
| **Scope** | Task còn lại của Study từ M5.7 trở đi · nợ kỹ thuật của Study · việc bị chặn |
| **Source of truth for** | Trạng thái task Study từ M5.7 · nợ kỹ thuật của Study |
| **Depends on** | `document-conventions.md` · `wbs.md` · `business-rules.md` · `use-cases.md` |
| **Updated by task** | suite IT trở lại 66/66 |
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
 ├── M5.13 (cột `action` chỉ nhận canonical)  ✔ done
 └── M5.15 (integration test qua UI)  ✔ done
M5.18 (khung phiên học)  ✔ done
M5.19 (`browse` và `match`)  ✔ done
M5.20 (`guess`, `recall`, `fill`)  ✔ done
M5.14 (đóng cùng UC-07)  ✔ done
M5.16 (thị giác + tiếp cận)  ✔ done
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

- **Status:** done
- **Goal:** Mở app còn phiên dở của **cùng ngày học** thì được chọn, không bị ép.
- **Scope:** màn chọn ba đường — tiếp tục phiên dở, Học mới, Ôn tập; chọn một
  trong hai đường sau thì phiên dở chuyển `abandoned`/`user_exit`.
- **Out of scope:** phiên của ngày khác — đã tự đóng `interrupted` ở M5.5.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget overlay ba đường, nối vào `StudyEntryScreen`
- **Acceptance criteria:**
  - [x] Phiên `in_progress` cùng ngày học → hiện đủ ba đường.
  - [x] Chọn Học mới hoặc Ôn tập → phiên cũ thành `abandoned`/`user_exit`, **không**
        phải `interrupted` (BR-103).
  - [x] Tiếp tục → phiên cũ giữ nguyên `status`, và `recall` tiếp đúng
        `remaining_ms` đã lưu (BR-133).
  - [x] Không có phiên dở → không hiện màn này chút nào.
- **`ResumeStudyDayUseCase` đã có từ M5.2 và chưa ai gọi.** Mốc này là phần UI của
  nó, không phải viết lại logic.
- **Dependencies:** M5.7
- **Tests required:** widget test ba nhánh; test khẳng định `end_reason` đúng ở
  mỗi nhánh
- **Checklist phases:** 14.4, 15.3

- **Kết quả:** `ResumeStudySessionUseCase` mới trả về đúng
  `StudySessionStartModel` như lúc mở phiên, nên màn phiên không cần biết phiên
  cũ hay mới. `StartStudySessionUseCase` tự đóng phiên đang mở — đặt ở use case
  chứ không ở màn hình, vì một luật mà caller có thể quên thì sẽ bị quên.
- **Recursive review tìm thêm hai lỗi, cả hai đã sửa trong mốc này:**
  - `StartStudySessionUseCase` đóng *mọi* phiên đang mở thành `user_exit`, kể cả
    phiên của ngày hôm trước — nhãn đúng của nó là `interrupted`. Nay quét
    `abandonStaleSessions` trước, nên thứ tự quyết định nhãn chứ không phải màn
    hình nào chạy trước.
  - Sau khi chọn Học mới, `studyResumeProvider` vẫn giữ phiên vừa bị đóng trong
    cache; lần vào sau sẽ mời học tiếp một phiên không còn tồn tại và
    `ResumeStudySessionUseCase` ném `NotFoundFailure`. Nay `_open` invalidate cả
    hai read trước khi đẩy màn.
- **Tests:** `test/features/study/domain/study_resume_paths_test.dart` (6),
  `study_entry_widget_test.dart` nhóm *the three paths* (5)

### M5.10 · Màn tổng kết phiên

- **Status:** done
- **Goal:** Kết thúc phiên nói được vừa rồi đã xảy ra chuyện gì.
- **Scope:** màn tổng kết tối thiểu sau khi phiên `completed`: số thẻ đã học
  xong, số thẻ đã ôn, số lượt sai; đường quay lại deck.
- **Out of scope:** thống kê dài hạn, biểu đồ, chuỗi ngày học — ngoài MVP.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget tổng kết + chuỗi ARB
- **Acceptance criteria:**
  - [x] Phiên `learning` xong hiện số thẻ vừa hoàn tất chuỗi (BR-144).
  - [x] Phiên `reviewing` xong hiện số thẻ đã ôn và số lượt sai.
  - [x] Phiên kết thúc bất thường (`abandoned`/`failed`) **không** hiện tổng kết
        như một thành tựu — nó nói phiên đã dừng và vì sao, không tô hồng.
  - [x] Số liệu đến từ **một** lượt đọc, không phải bốn (AD-13).
- **M5.5 có "màn tổng kết phiên tối thiểu" trong Scope nhưng không dựng.** Ghi ở
  đây thay vì sửa entry cũ: mốc đó đã `done` với phần vòng đời, và việc còn thiếu
  là một mốc riêng chứ không phải một dòng chưa tick.
- **Dependencies:** M5.7
- **Tests required:** widget test cho ba loại kết thúc; test một-lượt-đọc
- **Checklist phases:** 14.4, 15.3

- **Kết quả:** `StudySessionSummaryModel` mang cả `status`/`end_reason` lẫn bốn
  con số, đọc bằng **một** câu SQL — bốn câu là bốn thời điểm, và cái dễ đổi
  nhất giữa chúng chính là `status`. `StudySummarySectionWidget` đổi tiêu đề
  theo `hasCompleted`, nên phiên dừng vì lỗi ghi không đội lốt thành tựu.
- **Recursive review tìm thêm ba lỗi, cả ba đã sửa trong mốc này:**
  - Bản đầu hỏi `binaryAction` để biết hành động nào là sai. `sm2` trả `null`
    cho câu hỏi đó **có chủ đích** (BR-106), nên mọi deck `sm2` sẽ báo 0 lượt
    sai — con số vẫn trông hợp lý. Câu hỏi đúng là `StudyAction.isLapse`
    (BR-20), lọc trên `supportedActions` của chính thuật toán.
  - Cột là `session_kind`, không phải `kind`. Fake repository không thể bắt
    được; test chạy trên SQLite thật bắt ngay ở lần chạy đầu.
  - Về lại màn entry sau khi học xong vẫn thấy số đếm cũ. `_open` nay refresh cả
    hai đầu — trước khi đẩy màn và sau khi quay lại — vì phiên học chính là thứ
    làm số đếm đổi.
- **Chuỗi đếm dùng ICU plural** như phần còn lại của app: "1 cards reviewed" là
  dạng người dùng gặp nhiều nhất ở phiên ôn ngắn.
- **Tests:** `study_summary_widget_test.dart` (6), `study_session_controller_test.dart`
  nhóm *the summary of a finished session* (4), `study_flow_test.dart` nhóm cùng
  tên trên SQLite thật (2)

### M5.11 · Tùy chọn học hai tầng (BR-147, BR-148)

- **Status:** done
- **Goal:** Người dùng đặt được số thẻ mỗi phiên và thứ tự thẻ mới.
- **Scope:** đọc/ghi `app_settings`; parse và ghi `decks.study_config` trên root;
  màn cài đặt tối thiểu; giá trị hiệu lực = root nếu có, ngược lại mặc định.
- **Out of scope:** cài đặt ngoài Study.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** use case + màn cài đặt + widget
- **Acceptance criteria:**
  - [x] `card_limit` và `new_card_order` sửa được và có hiệu lực ở phiên **kế
        tiếp**, không phải phiên đang chạy (BR-139).
  - [x] Deck root đặt được giá trị riêng; deck con **không** có tùy chọn riêng và
        tra qua `root_deck_id` (BR-147) — bất biến **27** vẫn xanh.
  - [x] `new_card_order = random` cho **tập thẻ** khác `created` (BR-148) —
        đọc lại thành *chọn thẻ nào*, không phải *thứ tự trình bày*; lý do ở
        mục xung đột bên dưới.
  - [x] `study_config` hỏng hoặc không đọc được → dùng mặc định, **không** chặn
        việc học.
- **`effectiveOptions` hiện đọc `app_settings` và bỏ qua `study_config`**, có ghi
  chú trong code là "chưa có ai ghi". Mốc này là lúc ghi, nên cũng là lúc parse.
- **Dependencies:** M5.7
- **Tests required:** test hai nhánh giá trị hiệu lực; test JSON hỏng; test
  `random` khác `created`
- **Checklist phases:** 14.4, 15.1

- **Kết quả:** `StudyCardLimit` là value object có `parse` (kiểu chính là phép
  kiểm, như `DeckName`); `study_config` được parse ở `data/mappers/`;
  `effectiveOptions` gộp hai tầng và luôn tra qua root; `saveStudyOptions` nhận
  deck bất kỳ rồi **ghi lên root**, nên bất biến 27 không thể bị phá bởi màn hình
  mở ở cấp con. Màn `StudyOptionsScreen` + audit thị giác đi kèm.
- **Xung đột quy tắc đã phát hiện, và cách xử lý:** tiêu chí ban đầu đòi `random`
  cho **thứ tự** khác `created` *trên cùng tập thẻ*. Không thể đúng: BR-113 và
  BR-117 bắt **mỗi stage/round xáo lại**, nên thứ tự của danh sách thẻ phiên
  không bao giờ tới tay người dùng. Code cũ shuffle **sau** `LIMIT` trong SQL —
  tức là xáo lại đúng tập đã chọn theo `created_at`, rồi bị `_roundOne` xáo lần
  nữa: **`random` không có tác dụng nào quan sát được.** Cách đọc làm cả hai quy
  tắc cùng đúng là `new_card_order` quyết định *thẻ mới nào vào phiên* khi deck
  có nhiều hơn trần. Nay `random` đọc toàn bộ thẻ chưa học, xáo, rồi mới cắt theo
  trần. Test cũ (10 thẻ, trần 20) sẽ **xanh trên một implementation bỏ qua hoàn
  toàn tùy chọn** — đó chính là bản test đầu tiên tôi viết.
- **Quyết định của agent, không có trong docs:** trần trên của `card_limit` là
  **200** (`kMaxCardLimit`). BR-24 chỉ chốt mặc định 20 và không nói giới hạn
  trên; một ô text không chặn có thể tạo phiên trăm nghìn thẻ và lỗi sẽ trông
  giống app treo. Ghi ở đây để người sau biết đây là chặn an toàn UI, không phải
  luật nghiệp vụ.
- **Tests:** `study_options_test.dart` (13 — bounds, JSON hỏng, refuse-before-write),
  `study_flow_test.dart` nhóm *the two tiers of study options* trên SQLite thật (6)

### M5.12 · Các ca stage bị chặn hoặc bỏ qua, ở UI (BR-99, BR-124, BR-153)

- **Status:** done
- **Goal:** Stage không dựng được nội dung thì hành xử đúng, không render hỏng.
- **Scope:** `guess` không dựng được một question cụ thể → **chặn**: không render,
  không ghi lượt, không bỏ qua thẻ, không tiến checkpoint (BR-124); stage không
  còn thẻ nào trong phiên học → bỏ qua chứ không hiện rỗng (BR-99); `match` dưới
  hai cặp (BR-153).
- **Out of scope:** phần chọn mode — đã xong ở M5.4a.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** nhánh xử lý trong `StudySessionScreen` và các widget mode
- **Acceptance criteria:**
  - [x] `GuessModeHandler.buildQuestion` trả null → màn hình **không** render câu
        hỏi rỗng và **không** ghi lượt nào.
  - [x] Phiên học có stage không thẻ nào → stage đó bị bỏ qua, phiên vẫn chạy tiếp.
  - [x] `match` dưới hai cặp trong phiên học → bỏ qua; trong phiên ôn → đã bị vô
        hiệu hoá từ màn chọn.
  - [x] Không ca nào ở trên làm phiên kẹt hoặc kết thúc sớm.
- **Handler đã trả `null` đúng chỗ từ M5.4b; chưa ai xử lý `null` đó.** Đây là
  phần còn thiếu ở phía gọi, không phải ở phía luật.
- **Dependencies:** M5.7
- **Tests required:** widget test cho từng ca; test khẳng định không lượt nào
  được ghi ở ca chặn
- **Checklist phases:** 14.4, 15.3

- **Ghi chú của mốc này sai một nửa.** "Handler đã trả `null` đúng chỗ, chưa ai
  xử lý" — thực ra `studyModeView` **có** xử lý, bằng `SizedBox.shrink()`. Tức là
  màn hình trắng: không chữ để đọc, không nút để bấm, và cách duy nhất thoát là
  tắt app. Luật được thi hành, nhưng thi hành trong im lặng thì nhìn hệt như crash.
- **Hai luật bị gộp làm một, và đó là gốc của lỗi:** `canTake` hỏi về **một thẻ**,
  còn "hai cặp" (BR-153) và "năm nghĩa khác nhau" (BR-121) là tính chất của **tập
  thẻ**. Kiểm theo từng thẻ thì thẻ nào cũng đạt, nên stage vẫn được dựng hàng đợi
  đầy đủ rồi render ra rỗng. Nay có `StudyModeHandler.canRunOn(cards)`: stage
  không chạy được thì **không có dòng nào** trong hàng đợi, nên nó exhausted từ
  đầu và bị bỏ qua đúng như stage `fill` mà không thẻ nào có `example` (BR-114).
- **`AdvanceStudyStageUseCase` phải đi tiếp, không chỉ đi một bước.** Advance một
  lần rồi trả về stage vẫn rỗng thì caller nhận `turn == null` — mà null không
  phân biệt được với "phiên đã hết". Phiên dừng khi vẫn còn thẻ chưa trả lời. Nay
  nó lặp qua mọi stage exhausted, chặn trên là dãy 5 stage của thuật toán.
- **Ca chặn BR-124 giờ là một trạng thái có nội dung:** `StudyBlockedSectionWidget`
  nói rõ *không lượt nào được ghi và thẻ vẫn giữ nguyên vị trí*, và chỉ có một
  hành động là rời phiên — BR-124 cấm bỏ qua thẻ, nên không có đường nào "đi tiếp"
  để mời mà không phá luật.
- **Tests:** `study_blocked_stage_test.dart` (9), `study_blocked_widget_test.dart` (3),
  `study_skipped_stage_flow_test.dart` trên SQLite thật (2), và
  `study_session_flow_test.dart` đổi sang `exhaustedAnswers` — một cờ boolean chỉ
  nói được "mọi stage đều xong", tức là một kịch bản khác hẳn.

### M5.13 · Mức phản hồi của `match`, và cột `action` chỉ nhận canonical (BR-120)

- **Status:** **done** — analyze sạch, 1576 test xanh, visual audit xanh, guard sạch
- **Goal:** `study_answers.action` chỉ nhận action canonical của thuật toán, và
  mọi kết cục không phải "đúng" vào tập không đạt của round.
- **Scope:** phép chặn action ngoại lai ở đúng chỗ ghi; test khẳng định hai điều
  của BR-120 cùng lúc.
- **Out of scope:** mức phản hồi cho mode khác.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `study_queue_repository_impl.dart`, `study_mode.dart`,
  `study_mode_view_widget.dart`, `study_canonical_action_test.dart`
- **Acceptance criteria:**
  - [x] Kết cục không phải "đúng" vào tập không đạt của round (BR-116, BR-120),
        và ở lại đó kể cả khi sau đó thẻ được làm đúng.
  - [x] `study_answers.action` **chỉ** nhận action canonical của thuật toán
        (BR-120, BR-132) — action của thuật toán kia bị **từ chối trước khi
        ghi**, không phải rollback sau khi ghi một phần.
  - [x] Có test khẳng định đúng hai điều trên, cùng lúc.
- **Quyết định nghiệp vụ của chủ dự án (2026-08-08), thay thế phạm vi cũ của mốc
  này:** *"ở thuật toán SRS 8 box, chỉ có đúng và sai, không có bất kỳ trạng thái
  nào khác trong từng study stage."* Nên **`almost` không được dựng ở MVP**.
  BR-120 dùng **MAY** cho mức phản hồi thứ ba, nên phán quyết này không sửa luật
  nào và không tài liệu frozen nào phải đổi — nó chỉ nói cái MAY ấy không được
  dùng. `docs/wbs.md:6603` vốn đã ghi "khi nào `match` trả `almost`" là **ngoài
  phạm vi** M5.0e, tức câu hỏi này chưa từng có câu trả lời trong docs.
- **Nửa còn lại của BR-120 thì có thật, và nó đang không được thi hành ở đâu cả.**
  Bỏ `almost` không làm mốc này rỗng: câu "cột đó chỉ nhận action canonical"
  trước nay không phép kiểm nào bảo đảm. `submitAnswer` ghi bất kỳ `StudyAction`
  nào được đưa vào, nên một thẻ `eight_box` nhận được `easy` và một thẻ `sm2`
  nhận được `remembered`. Cả hai lưu sạch sẽ rồi **không đọc lại được**:
  `isLapse` bảo `easy` không phải lượt sai, và `EightBoxScheduler` không có nhánh
  nào cho nó — dòng lịch sử ấy vĩnh viễn được chấm là "đúng".
- **Luật ở `domain/`, câu hỏi đặt ở chỗ ghi.** `isCanonicalAction` sống cạnh
  `schedulerFor` trong `study_scheduler.dart` vì luật là của thuật toán; nó được
  *gọi* bên trong `runInTransaction`, nơi `scheduler_type` của chính thẻ đang có
  sẵn. Đây đúng là hai nửa `CLAUDE.md` tách ra có chủ đích. Guard 400 dòng của CI
  bắt bản đầu (414 dòng) và đó là thứ đẩy luật về đúng chỗ của nó.
- **Chặn đặt trong transaction, hỏi chính thẻ.** `card_study_states.scheduler_type`
  đang được đọc sẵn để ghi vào dòng lịch sử vài dòng bên dưới, nên phép kiểm tốn
  **không** thêm truy vấn nào. Hỏi thẻ thay vì hỏi caller là thứ làm luật không
  thể bị vòng qua: một use case quên kiểm, hoặc kiểm theo deck đã đổi thuật toán,
  vẫn không đi qua được. `SchedulerType.unknown` cũng bị từ chối — thẻ do bản
  build mới hơn ghi thì **đọc** được, nhưng không có gì bản này ghi lên đó là
  canonical cho một thuật toán nó chưa từng nghe tên.
- **Phép kiểm được chứng minh bằng cách tái tạo vi phạm.** Gỡ đúng một dòng chặn
  ra, hai test đỏ đúng chỗ, rồi khôi phục. Xanh trên code sạch không chứng minh gì.
- **Recursive review tìm ra hai lỗi, cả hai đã sửa trong mốc này:**
  - **`_send` nuốt action null trong im lặng.** `binaryAction` trả `null` khi
    `schedulerFor` không nhận ra thuật toán của deck; `studyModeView` vẫn dựng
    bàn ghép, người dùng chạm ô, và **không gì xảy ra** — không ghi, không báo,
    không đường ra ngoài force-quit. Đúng loại lỗi M5.12 vừa sửa ở một tầng khác.
    Nay `studyModeView` từ chối dựng khi `mode.isBinaryGraded` mà không có ánh xạ,
    và màn hình rơi vào `StudyBlockedSectionWidget` — nói rõ và mời rời phiên.
  - **Test BR-124 cũ sẽ vẫn xanh trên một implementation bỏ qua hoàn toàn BR-124.**
    Nó dựng `StudySessionState` không đặt `schedulerType`, mà mặc định là
    `unknown` — nên sau sửa trên, view trả null vì *lý do khác*. Nay test đặt
    `eightBox` tường minh, và có test đối chứng khẳng định cùng stage ấy **dựng
    được** khi thuật toán đã biết.
- **Quyết định của agent, không có trong docs:** `StudyMode.isBinaryGraded` viết
  là `producesAnswer && this != selfAssess` — đúng như BR-106 phát biểu — chứ
  không phải một danh sách bốn mode. Danh sách là chỗ thứ hai tập mode được lưu,
  và nó lệch vào ngày có mode thứ bảy. Nó trùng tập với `usesRounds` một cách
  tình cờ; gộp hai getter sẽ làm một mode chấm điểm mà không dùng round trở nên
  không diễn đạt được.
- **Dependencies:** M5.7
- **Tests required:** test tập không đạt; test `action` canonical
- **Checklist phases:** 14.4, 15.1
- **Tests:** `study_canonical_action_test.dart` (4, trên SQLite thật),
  `study_blocked_widget_test.dart` (+2)

### M5.14 · Reset learning progress đóng phiên đang mở (BR-83)

- **Status:** **done** — đóng cùng UC-07 (M5.21 ở `wbs.md`)
- **Goal:** Reset một cây deck thì mọi phiên đang mở của nó đóng `invalidated`.
- **Scope:** nối `invalidateSessionsForRoot` vào luồng Reset của Deck.
- **Out of scope:** bản thân Reset — đó là UC-07.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** một lời gọi trong use case Reset của Deck
- **Acceptance criteria:**
  - [x] Reset khi phiên đang mở → phiên thành `invalidated`/`scheduler_reset`
        (BR-83), **không** phải `stale_generation`.
  - [x] Lượt đã ghi vẫn còn trong `study_answers` (BR-86, BR-43).
- **Thao tác đã có và có test từ M5.5; thiếu đúng một caller.** Chặn thật:
  `lib/features/deck/` chưa có use case Reset nào. Nối dây là **quyết định
  cross-feature**: Deck sẽ phải phụ thuộc contract của Study, và đó là hướng phụ
  thuộc mới trong repo này — cần quyết định tường minh chứ không lặng lẽ thêm.
- **Chốt và đóng.** Chủ dự án chọn *"Deck sở hữu, gọi contract Study"*, và UC-07
  được dựng trọn ở M5.21 (`wbs.md`). Caller nằm **trong transaction của Deck**,
  không ở use case — đặt ở use case là hai lượt ghi, mà BR-47 nói một.
- **Dependencies:** UC-07 (chưa có mốc)
- **Tests required:** test luồng Reset đóng phiên
- **Checklist phases:** 14.4, 15.1

### M5.15 · Integration test qua UI và kênh E2E

- **Status:** **done** — 4 IT xanh trên emulator Android, `flutter build web` exit 0,
  analyze sạch, 1610 test xanh, guard sạch
- **Goal:** Chứng minh UC-05 chạy thật trên thiết bị, qua màn hình.
- **Scope:** `integration_test/study_flow_test.dart` đi qua UI; giữ kênh Web sống.
- **Out of scope:** Playwright nối CI — M7.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** `integration_test/`
- **Acceptance criteria:**
  - [x] Cold start → mở deck → học mới → **đi hết chuỗi stage** → thẻ nhận
        `learned_at` và hạn sau đó. Nửa sau đóng ở lượt riêng — xem mục dưới.
  - [x] Thẻ chưa học xong **không** mở được phiên ôn (BR-145) — màn entry của
        deck mới hiện `New 3 · Due 0` và **không có** nút ôn tập.
  - [x] Thẻ thiếu `example` vẫn mở và chạy được phiên (BR-114) — qua UI lần này.
  - [x] `flutter test integration_test/it_study_test.dart` exit 0 trên emulator
        Android (`sdk gphone64 x86 64`, API 36, flavor `development`).
  - [x] `flutter build web` vẫn exit 0 (AD-04).
- **M5.6 đã kiểm những điều này ở mức use case và ghi rõ phần qua UI còn nợ.** Mốc
  này đóng nợ đó; không viết lại phần đã có.
- **Mốc này phải dựng một mắt xích trước khi test được gì.** Nút Study trên thẻ
  deck và nút Learn trên bảng tiến độ đều còn hiện snackbar *"đang xây dựng"* —
  tức **không có đường nào từ một deck tới một phiên học**. Nay có route
  `/decks/:deckId/study` (`RouteNames.deckStudy`), lồng dưới deck nên Back quay
  về đúng deck đã mở chứ không về thứ tab Study đang giữ. Đường vào cho deck toàn
  thẻ mới là nút trên **bảng tiến độ của card list**: nút Study trên thẻ deck chỉ
  hiện khi có thẻ **đến hạn** (BR-150).
- **IT bắt ngay một lỗi mà không test nào khác bắt được.** `studyEntryCounts` lọc
  theo `root_deck_id`, còn màn hình đưa cho nó **deck đang mở**. Mọi caller trước
  M5.15 tình cờ đều đưa root, nên câu SQL trông đúng — mà mở study entry trên một
  **sub-deck** thì nó khớp *không dòng nào* và báo "Every card here has been
  learned". Màn 0/0 ấy không phải trạng thái lỗi: **nó là câu trả lời sai trông
  như câu trả lời đúng**. Nay câu truy vấn tự tra root qua `root_deck_id`
  (BR-06, BR-57) nên nhận deck nào cũng đúng.
- **Và có test đơn vị cho chính chỗ ấy**, vì CI **không** chạy integration suite:
  `study_entry_counts_test.dart` đọc counts từ một deck con trên SQLite thật, kèm
  test đối chứng (root và branch phải ra cùng số; deck của cây khác ra 0).
- **Phần đi hết chuỗi đóng ở lượt riêng sau M5.16** — xem mục dưới bảng nợ.
- **Dependencies:** M5.7, M5.9, M5.10, M5.12
- **Tests required:** đây **là** task test
- **Checklist phases:** 15.5
- **Tests:** `integration_test/it_study_test.dart` (4, trên emulator),
  `study_entry_counts_test.dart` (3)

### M5.16 · Kiểm thị giác và tiếp cận cho màn Study

- **Status:** **done** — analyze sạch, 1617 test xanh, visual audit xanh,
  catalog smoke xanh, guard sạch
- **Goal:** Màn Study đạt cùng chuẩn thị giác như Deck và Card.
- **Scope:** đăng ký Widgetbook đủ màn mới; visual audit theo MX-VIS-001; tương
  phản, vùng chạm, thứ tự đọc màn hình.
- **Out of scope:** đổi token — nếu thiếu token thì đó là mốc riêng.
- **Editable documents:** `docs/wbs-study.md`
- **Output:** entry Widgetbook, báo cáo audit
- **Acceptance criteria:**
  - [x] Mọi màn Study mới có entry Widgetbook — cả ba: `StudyEntryScreen`,
        `StudySessionScreen`, `StudyOptionsScreen`.
  - [x] Tương phản chữ đạt ngưỡng ở cả light và dark.
  - [x] Nút action của phiên đạt vùng chạm tối thiểu, kể cả khi có bốn nút `sm2`
        (`androidTapTargetGuideline` **và** `iOSTapTargetGuideline`, hai theme).
  - [x] Đồng hồ `recall` đọc được bằng screen reader, không chỉ bằng màu — chuỗi
        là "Còn N giây", không phải một con số trần.
- **Nợ Widgetbook đóng bằng một fake riêng của catalog.** Test double của app nằm
  dưới `test/`, mà một package khác **không import được** — đó chính là lý do màn
  Deck có mặt trong catalog còn ba màn Study thì không. Nay có
  `widgetbook/lib/screens/study_catalog_repository.dart`, và nó cố tình *ngu*:
  đọc thì tất định theo scenario, ghi thì no-op. Catalog trưng trạng thái, không
  mô phỏng phiên học. Không luật nào được cài lại trong đó — chuỗi stage, tập
  action, hậu quả của một câu sai vẫn do use case và scheduler thật quyết định.
- **Tương phản đo từ token, không đo bằng `textContrastGuideline`.** Guideline ấy
  lấy mẫu **pixel đã render** của một semantics node; với một dòng 14px nét
  mảnh thì phần lớn pixel của glyph là khử răng cưa, nên nó báo **1.92:1** ở
  light cho cặp màu đo được **6.3:1**, và **3.90:1** ở dark cho cặp đo được
  **7.3:1**. Một con số không ai nhìn thấy thì không phải con số để gate — chính
  `audit_rules.dart` của repo cũng đã nói vậy ở chỗ nó bảo caller đi đọc raster.
  Nay test đo `contrast()` trên đúng ba cặp khung tự viết chữ:
  `onSurfaceVariant`/`surface`, `onSurface`/`surface`, và
  `primaryAccent`/`surfaceMuted` — cặp thứ ba là chính lập luận của §7.8.
- **Recursive review — đúng hơn là chính mốc này — tìm ra một lỗi thật:** thanh
  trên **tràn 19px** ở 320×568 với `textScaler` 2.0. Nút ✕ có bề rộng cố định,
  nên khi chỉ thanh tiến trình được co, hết đường co là tràn. Nay **mọi** con của
  hàng ấy đều `Flexible`, và bộ đếm cắt bằng ellipsis.
- **Và test cũ đã bỏ lọt nó vì một lý do đáng ghi:** ca 320×568 trong
  `study_session_frame_test.dart` dựng khung **không có gutter của màn hình**,
  tức đo 320px chỗ dùng được trong khi màn thật chỉ cho 272px. Nay test ấy bọc
  đúng `Padding(lg)` mà `MxContentShell` áp trong production.
- **Ghi nhận trung thực về `flutter test integration_test/` (tiêu chí của M5.15):**
  chạy cả thư mục trên emulator cho **49 xanh / 15 đỏ**. Cả 15 đều là kịch bản
  Deck/Card/Disc/Tree có sẵn — dạng "không tìm thấy `No decks yet`" sau khi xoá
  — **không** kịch bản nào chạm Study, và `it_study_test.dart` xanh cả 4. Đây là
  nợ có trước, ghi vào bảng nợ chứ không gộp vào mốc Study (cùng lý do golden
  `deck_screens_demo_test` được để riêng).
- **Dependencies:** M5.7, M5.9, M5.10
- **Tests required:** golden/visual audit; test text scale 2.0
- **Checklist phases:** 12.x, 15.3
- **Tests:** `study_accessibility_test.dart` (7),
  `study_session_frame_test.dart` ca 320×568 nay đo đúng bề rộng,
  `widgetbook/test/catalog_smoke_test.dart` phủ ba màn mới

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

- **Status:** **done** — analyze sạch, 1599 test xanh, visual audit xanh, guard sạch
- **Goal:** Năm màn dùng chung một khung, dựng một lần.
- **Scope:** thanh trên (✕, pill mode, thanh tiến trình, bộ đếm `n / m`), dòng
  ngữ cảnh, dòng gợi ý dưới cùng.
- **Out of scope:** thân của từng mode — M5.19, M5.20.
- **Đã chốt ở M5.17:** bộ đếm chỉ đếm tập của phiên đang chạy (§7.2); mode
  `recall` thay bộ đếm bằng thời gian còn lại (§7.3).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** widget khung trong `presentation/widgets/sections/`, chuỗi ARB
- **Acceptance criteria:**
  - [x] ✕ đóng phiên qua `leave()` và ghi `abandoned`/`user_exit` (BR-82) —
        **không** phải pop route suông.
  - [x] Bộ đếm và thanh tiến trình đọc từ state, không tự đếm.
  - [x] Pill và thanh tiến trình dùng token **đang có** — `primaryAccent`,
        `progressTrack`, `progressFill`. **Không** thêm token màu nào, và
        **không** dùng `success` làm màu nhận dạng mode (§7.8).
  - [x] Dòng gợi ý đổi theo mode và đến từ ARB.
  - [x] Bộ đếm **không** trộn hai tập thẻ (BR-142, §7.2).
  - [x] Ở `recall`, thanh trên hiện thời gian còn lại (BR-128, §7.3), và nó đọc
        được bằng screen reader chứ không chỉ bằng màu.
  - [x] Render ở 320×568 và `textScaler` 2.0 không tràn.
- **Kết quả:** `StudySessionFrameSectionWidget` là khung dùng chung; màn phiên
  học bọc thân của mode vào nó. Bộ đếm và thanh tiến trình đọc
  `StudyTurnModel.progress`, đến từ **cùng một lượt đọc** với thẻ và dòng hàng
  đợi (AD-13) — câu `stageRoundProgress` đếm **round đang chạy**, không đếm cả
  stage, vì stage ghi danh thẻ trượt vào round sau ngay lúc trượt (BR-116) nên
  tổng của stage sẽ **tăng trong lúc người dùng trả lời** và thanh đi lùi.
- **Không có app bar nữa.** Khung *chính là* thanh trên. Một `AppBar` phía trên
  nó là hai thanh cùng đặt tên một màn, kèm mũi tên back pop route và **để phiên
  mở** — đúng thứ BR-82 cấm.
- **Pill mode không phải `MxPillButton(onPressed: null)`.** Component ấy render
  callback null thành *disabled* (alpha 38%, ngoài palette); đây là một cái tên,
  không phải nút bị tắt. Đúng lỗi đã bắt được ở M5.7. Pill dùng `surfaceMuted`
  làm nền và `primaryAccent` làm chữ — `primaryAccent` vốn là "brand hue as
  text", biến thể đủ sáng để đạt AA trên nền tối, khác `primary`.
- **Đồng hồ `recall` đi qua `ValueNotifier`, không qua `setState`.** Nó tick
  10Hz; đưa vào state màn hình là rebuild luôn cả thân mode. Chuỗi hiển thị là
  "Còn N giây" chứ không phải một con số trần, vì đó cũng là thứ screen reader
  đọc — một đồng hồ chỉ đọc được bằng màu thì không đọc được.
- **Recursive review tìm ra bốn lỗi, cả bốn đã sửa trong mốc này:**
  - **Bàn ghép được chia lại mỗi lần rebuild.** `studyModeView` nhận một
    `Random` do màn hình giữ và **tiêu thụ nó mỗi lượt build** — khoá nút trong
    lúc ghi là đủ để xáo lại — nên đáp án dịch chuyển dưới ngón tay người dùng.
    Chú thích trong code lại khẳng định điều ngược lại: giữ `Random` ở state chỉ
    làm mỗi lần chia *khác nhau*, không làm nó ngừng chia lại. BR-127 còn đòi cả
    hai thứ tự **ổn định khi Resume**, điều một generator sống không bao giờ làm
    được. Nay seed dựng từ (phiên, stage, round) cho bàn ghép và thêm `cardId`
    cho năm lựa chọn — hai hoán vị độc lập đúng như BR-127.
  - **`deckName` được nối vào model nhưng không nối vào state.** Dòng ngữ cảnh
    render " · Review" — thiếu tên deck, im lặng, vì `@Default('')`. Test ở mức
    màn hình bắt được; ba test widget của khung thì không, vì chúng tự dựng dữ
    liệu.
  - **Màn phiên học pad hai lần.** `MxContentShell` đã áp gutter, màn hình bọc
    thêm một `Padding(lg)` nữa. Ở 320px chỗ chật thêm ấy là thứ đẩy các con của
    hàng trên ra ngoài trước tiên.
  - **Không test nào chạm câu SQL của bộ đếm.** Mọi widget đều được *đưa* một
    `StudyStageProgressModel` do test dựng, nên một câu đếm sai round vẫn để tất
    cả xanh. Nay `study_canonical_action_test.dart` kiểm nó trên SQLite thật.
- **`onRemainingChanged` từng không ai gọi.** Nó chỉ bắn lúc đồng hồ dừng, và
  không caller nào trong `lib/`. Nay bắn mỗi tick và màn hình nghe — nên khung
  có số để vẽ.
- **Đính chính, phát hiện ở lượt recursive review của M5.20:** bản đầu của mục
  trên viết rằng việc này *"cũng là nửa ghi của BR-133"*. **Sai.** Tick được nối
  vào `ValueNotifier` của khung, không nối vào `pause()`. Nửa ghi đã đóng ở một
  lượt riêng sau M5.16 — xem mục dưới bảng nợ.
- **Quyết định của agent, không có trong docs:** dòng ngữ cảnh là
  `<tên deck> · <loại phiên>`. Ảnh ghi `VOCAB — CHAPTER 1 · ÔN TẬP`, tức có
  đường dẫn deck; dựng đường dẫn cần thêm một lượt đọc cây deck, và §7.2 chỉ đòi
  không trộn hai tập. Tên deck lấy được **miễn phí** vì `deckContext` vốn đã đọc
  dòng deck ấy.
- **Dependencies:** M5.7, M5.17
- **Tests required:** widget test cho ✕, cho bộ đếm, cho năm dòng gợi ý
- **Checklist phases:** 14.4, 15.3
- **Tests:** `study_session_frame_test.dart` (12),
  `study_session_screen_widget_test.dart` (3, đường đi từ màn hình thật),
  `study_blocked_widget_test.dart` nhóm *the deal is seeded* (2),
  `study_canonical_action_test.dart` nhóm *the counter a turn carries* (2)

### M5.19 · `browse` và `match` theo design

- **Status:** **done** — analyze sạch, 1601 test xanh, visual audit xanh, guard sạch
- **Goal:** Hai màn khớp ảnh 12 và 13.
- **Scope:** thẻ hai nửa có nhãn `KOREAN`/`MEANING` và đường kẻ giữa; bàn ghép
  hai cột với ba trạng thái ô.
- **Out of scope:** vuốt để lùi — **đã chốt là bỏ** (§7.7).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** cập nhật `study_card_face_section_widget.dart` và
  `match_board_section_widget.dart`
- **Acceptance criteria:**
  - [x] `browse` hiện hai nhãn và hai mặt, không nút chấm điểm nào (BR-111).
  - [x] Ô `match` đã ghép **ở lại bàn** với dấu ✓ và trạng thái mờ — bản hiện tại
        xoá ô khỏi bàn, và đó là điểm khác design.
  - [x] Ô đang chọn dùng nền primary đặc, chữ đảo màu, đạt tương phản ở cả hai
        theme — màu từ `ColorScheme`, không đặt thẳng trong widget.
  - [x] Ô đã ghép dùng `success` đúng nghĩa "đúng", không phải để trang trí.
  - [x] Ô đã ghép không bấm lại được.
  - [x] Pill của `browse` dùng nhãn `browse`, không phải `REVIEW` (§7.1) — vốn đã
        đúng từ M5.18: pill đọc `studyMode(mode)`, và `browse` là `Browse`.
  - [x] Dòng ngữ cảnh của `match` ghi **round**, không phải board (§7.6).
- **Kết quả:** thẻ của `browse`/`self_assess` chia hai nửa có nhãn và một đường
  kẻ mảnh — hai nửa là thứ làm người đọc hiểu đây là *hai mặt của một thứ*, còn
  hai đoạn xếp chồng đọc thành hai sự kiện về nó. Bàn ghép có `MatchTileWidget`
  với ba trạng thái; `StudyStageProgressModel` thêm `round`, nên khung tự dựng
  được dòng `Round 2 · 5 pairs left` mà không cần lượt đọc nào thêm.
- **Vì sao ô đã ghép ở lại bàn.** Xoá nó làm mọi hàng bên dưới dồn lên, nên ô
  người dùng sắp bấm **dịch chỗ ngay lúc họ bấm một ô khác** — và cái bàn mà họ
  vừa thuộc hình dạng thì biến mất.
- **Quyết định của agent, không có trong docs — hai cái:**
  - **Nhãn nửa trên là `Term`, không phải `KOREAN`.** Không deck và không card
    nào mang ngôn ngữ; in `KOREAN` lên màn là đặt một trường không tồn tại trong
    dữ liệu (quy tắc 2 của §7).
  - **Ô đã ghép không có nền xanh nhạt.** Ảnh tô nền xanh rất nhạt;
    `AppSemanticColors` có `success` và không có container đi kèm, mà thêm token
    là quyết định token — M5.19 ghi rõ đó là **ngoài phạm vi**. Dấu ✓, chữ
    `success` và độ mờ mang đủ trạng thái mà không phải bịa một màu.
- **Recursive review tìm ra một lỗi, đã sửa trong mốc này:** `didUpdateWidget`
  so bàn bằng `identical`. Bàn được **dựng lại mỗi lượt build** từ shuffle có
  seed (BR-127, M5.18), nên `identical` luôn sai — khoá nút trong lúc ghi là đủ
  — và **mọi dấu ✓ người dùng vừa kiếm được sẽ biến mất ngay khi họ trả lời**.
  Nay so bằng *nội dung* bàn: chính cái seed làm ván bài tái lập được là thứ làm
  nội dung dùng được như định danh. Test cũ "round mới xoá dấu ✓" vẫn xanh trên
  bản hỏng ấy, nên có thêm test đối chứng: dựng lại **cùng một ván** thì dấu ✓
  phải còn.
- **Dependencies:** M5.18
- **Tests required:** widget test ba trạng thái ô; test `browse` không có action
- **Checklist phases:** 14.4, 15.3
- **Tests:** `match_guess_widget_test.dart` nhóm *the match board* (7),
  `study_session_frame_test.dart` (+2 dòng ngữ cảnh của match)

### M5.20 · `guess`, `recall` và `fill` theo design

- **Status:** **done** — analyze sạch, 1607 test xanh, visual audit xanh, guard sạch
- **Goal:** Ba màn khớp ảnh 14, 15, 16 — gồm cả state thứ hai chưa có ảnh.
- **Scope:** hàng lựa chọn có huy hiệu chữ cái và trạng thái sau trả lời; bố cục
  đề trên / đáp án dưới / nút dưới cùng cho `recall` và `fill`.
- **Out of scope:** icon bút chì và loa — **đã chốt là không dựng** (§7.4);
  dòng mô tả phụ của `guess` — **đã chốt là không dựng** (§7.5).
- **Editable documents:** `docs/wbs-study.md`
- **Output:** cập nhật ba widget mode
- **Acceptance criteria:**
  - [x] `guess` sau trả lời: đáp án đúng xanh + ✓, lựa chọn sai đã chọn đỏ + ✕,
        ba lựa chọn còn lại mờ — và **không** nhận thêm lượt nào (BR-126).
  - [x] Huy hiệu A–E là thứ tự hiển thị, **không** phải định danh; lượt vẫn ghi
        theo `cardId` (BR-125).
  - [x] Mỗi lựa chọn chỉ hiện nghĩa, không có dòng mô tả phụ (§7.5).
  - [x] `recall` không có icon loa và icon bút chì (§7.4).
  - [x] `recall` có state đã lật, và nó khoá kết cục (BR-130).
  - [x] `fill` có state đã chấm, hiện đúng/sai và không nhận nhập tiếp.
  - [x] Hai state thiếu ảnh được vẽ theo BR chứ không theo phỏng đoán, và ghi rõ
        trong wireframe là do agent đề xuất — `m5-study-modes.md` §6.1.
- **Kết quả:** `GuessOptionItemWidget` (bucket `items/`) có bốn state;
  `recall` và `fill` đổi sang cùng một bố cục *đề trên · vùng đáp án · hành động
  dưới cùng*, vì hai lượt học ấy hỏi cùng một thứ theo hai cách.
- **Đáp án đúng luôn được đánh dấu đúng, kể cả khi người dùng không chọn nó.**
  Một màn chỉ đánh dấu lựa chọn của bạn để bạn lại **biết mình sai mà không biết
  cái gì đúng** — mà đó chính là thứ lượt học này tồn tại để dạy.
- **Huy hiệu A–E dựng từ vị trí hàng, không lưu trên `GuessOption`.** Lưu nó lên
  option làm nó *trông như* thứ một lượt có thể ghi theo (BR-125), và ghế thì đổi
  mỗi lần xáo (BR-127). Nó cũng bị `ExcludeSemantics` — screen reader đọc "A,
  apple" thì nghĩa bị chôn sau một số ghế sắp đổi.
- **Quyết định của agent, ghi vào wireframe §6.1 — hai state không có ảnh:**
  - **`recall` sau khi lật không còn nút nào**, vì BR-129 cho đúng một kết cục và
    BR-130 khoá nó. Nhưng màn có đáp án và không nút trông **hệt như màn treo**,
    nên chỗ nút cũ là một câu nói rõ lượt đã chốt. Trước khi lật, vùng đáp án
    mang nhãn — một ô rỗng là *không có gì* với screen reader.
  - **`fill` sau khi chấm** đóng ô nhập và hiện mặt sau **của thẻ** khi sai, chưa
    bao giờ hiện lại thứ người dùng gõ (BR-138). Đúng thì không hiện dòng đáp án:
    dòng ấy nói cho người trượt biết họ thiếu gì, đưa cho người làm đúng thì nó
    đọc thành lời đính chính.
- **Recursive review tìm ra một chỗ, và nó nằm ở mốc trước:** mục
  `onRemainingChanged` của M5.18 khẳng định việc nối tick "cũng là nửa ghi của
  BR-133". Không phải — tick được nối vào `ValueNotifier` của khung, còn
  `StudySessionController.pause()` vẫn không có caller nào trong `lib/`. Đã đính
  chính trong entry M5.18 và ghi vào bảng nợ, vì một dòng WBS nói xong một việc
  chưa xong là đúng thứ tệ hơn không có WBS.
- **Dependencies:** M5.18
- **Tests required:** widget test cho từng state; test huy hiệu không phải định danh
- **Checklist phases:** 14.4, 15.3
- **Tests:** `guess_question_widget_test.dart` (7, tách khỏi
  `match_board_widget_test.dart` ở guard 400 dòng),
  `recall_fill_widget_test.dart` nhóm *the second states* (3)

## Nợ kỹ thuật của Study

| Nợ | Vì sao còn | Đóng ở |
|---|---|---|
| Controller đọc thẳng repository ở 4 chỗ | không phép kiểm nào bắt được; guard kiểm import, không kiểm lời gọi | M5.8 |
| ~~`study_config` chưa được parse~~ | `study_config_mapper.dart` parse và ghi; hỏng thì về mặc định | xong ở M5.11 |
| ~~BR-120 chưa có test~~ | chủ dự án chốt `eight_box` chỉ có đúng/sai nên `almost` không dựng; nửa "chỉ nhận action canonical" nay bị chặn trong transaction và có test | xong ở M5.13 |
| ~~BR-83 chưa có caller~~ | UC-07 dựng ở M5.21; Deck gọi `invalidateSessionsForRoot` trong chính transaction của reset | xong ở M5.14 |
| ~~`remaining_ms` chưa được nối vào UI resume~~ | `RecallTimerSectionWidget` nhận `initialRemaining` từ queue item; test BR-133 ở `recall_fill_widget_test.dart` | xong ở M5.9 |
| Widget mode chưa ai dựng trong `lib/` | chưa có màn ghép | M5.7 |
| ~~Ảnh wireframe chưa có trong repo~~ | chủ dự án đã thả vào `wireframes/assets/m5-study-modes/` | xong |
| ~~`match` xoá ô đã ghép khỏi bàn~~ | ô đã ghép nay ở lại bàn với ✓ và độ mờ | xong ở M5.19 |
| ~~Hai state thứ hai của `recall`/`fill` chưa có ảnh~~ | vẽ theo BR và ghi vào wireframe §6.1 là agent đề xuất | xong ở M5.20 |
| ~~IT chưa đi hết chuỗi 5 stage tới `learned_at`~~ | robot đọc bàn ghép và câu hỏi từ chính widget app vừa dựng; 20 lượt, 15 câu trả lời, 5 thẻ nhận `learned_at` | xong |
| ~~`pause()` không có caller — nửa **ghi** của BR-133~~ | `RecallTimerSectionWidget.onSuspended` bắn khi app rời foreground với lượt còn mở; màn hình gọi `pause()`. Round-trip có test trên SQLite thật | xong |
| ~~Màn Study chưa có mặt trong Widgetbook~~ | `StudyCatalogRepository` là fake riêng của catalog; ba màn Study đã đăng ký | xong ở M5.16 |
| ~~Kịch bản IT đỏ~~ | Bảy nguyên nhân, tất cả đã vá; suite trở lại **66/66** | xong |

### Nửa **ghi** của BR-133, đóng sau M5.16

- **Status:** **done** — analyze sạch, 1622 test xanh, guard sạch
- **Vấn đề:** `RecallTimerSectionWidget` đọc `initialRemaining` từ dòng hàng đợi
  từ M5.9, còn **không caller nào trong `lib/`** từng ghi giá trị vào đó. Tức là
  một cột luôn NULL và một widget luôn bắt đầu lại ở hai mươi giây — luật được
  viết, cột được tạo, và đường nối thì không có.
- **Tín hiệu là "app rời foreground", không phải "đồng hồ dừng".** Tick bắn 10
  lần mỗi giây; ghi theo nó là mười lượt ghi mỗi giây cho một con số không ai đọc
  cho tới khi app quay lại. Nay `onSuspended` bắn **một** lần, đúng lúc BR-128
  dừng đồng hồ.
- **Lượt đã có kết cục thì không báo gì.** Lật đáp án *chính là* kết cục
  (BR-129), nên dòng hàng đợi của nó không còn `pending` — repository vốn đã từ
  chối, và việc không hỏi là nửa không phụ thuộc vào việc ai đó nhớ.
- **`isRevealed` được báo theo đúng thứ widget đang giữ**, dù `true` hôm nay
  không tới được: nếu sau này thiết kế tách "lật" khỏi "trả lời" thì đường dây
  đã đúng sẵn, không phải nối lần hai.
- **Tests:** `recall_widget_test.dart` nhóm *what the clock writes down* (2),
  `study_turn_progress_test.dart` (3, round-trip trên SQLite thật) —
  `recall_fill_widget_test.dart` tách đôi ở guard 400 dòng thành
  `recall_widget_test.dart` và `fill_widget_test.dart`.

### Fixture seed ghi đè `CLEAN-RESET` của suite IT, đóng sau M5.16

- **Status:** **done** — 49 xanh/15 đỏ → **54 xanh/10 đỏ** trên emulator;
  analyze sạch, 1623 test xanh, guard sạch
- **Nguyên nhân, đo được chứ không đoán:** `ItHarness.launchApp` dựng app với
  `EnvConfig.development`, và `FixtureSeederWidget` chỉ chạy ở development — nên
  ngay sau `wipeAllData()`, một frame sau, deck starter **"Everyday English"**
  được chép lại vào đúng cơ sở dữ liệu mà kịch bản vừa dọn. Kịch bản nào khẳng
  định thư viện rỗng thì thấy nó; kịch bản nào đếm deck thì đếm nhầm. Và vì đó
  là cuộc đua giữa hai việc bất đồng bộ, **có lần đỏ có lần không** — đúng cái
  làm nó trông như flake.
- **Cách sửa: suite sở hữu dữ liệu của nó.** `buildRootWidget` nhận
  `shouldSeedFixtures`, mặc định **bật** — một app khởi động mà không nói gì thì
  vẫn là app, và bản development demo được ngay là lý do seeder tồn tại (BR-87).
  Suite IT tắt nó; kịch bản nào cần nội dung thì nạp tường minh qua `ItFixtures`,
  như `loadDueLibrary` vẫn làm.
- **Chẩn đoán bằng cách in đúng thứ trên màn hình.** Ba lượt: `trace` (6 chuỗi
  đầu, không đủ), rồi `visibleText` đầy đủ — và tên deck starter hiện ra ở chuỗi
  thứ bảy. Trước đó mọi giả thuyết đều sai.
- **Còn 10 ca đỏ, nguyên nhân khác.** Reporter nêu bốn: `IT-CARD-005`,
  `IT-CARD-009`, `IT-DISC-001`, `IT-DISC-003`. `IT-CARD-005` đã soi tới nơi: ở
  bước 4 màn hình vẫn là editor **tạo mới** với ô Front rỗng, tức bước trước đó
  không lưu — một lỗi khác hẳn, thuộc Card. Ghi vào bảng nợ.
- **Tests:** `bootstrap_test.dart` — *the fixture seed can be switched off, and
  defaults on*. Cả hai chiều, vì chỉ kiểm chiều tắt thì một
  `buildRootWidget` bỏ seeder hẳn cũng xanh.

### IT đi hết chuỗi 5 stage, đóng sau M5.16

- **Status:** **done** — 6 IT xanh trên emulator; analyze sạch, 1625 test xanh,
  visual audit xanh, guard sạch
- **Robot đọc màn hình, không chép luật.** Cặp đúng, lựa chọn đúng và cách viết
  đúng đều lấy ra từ chính widget app vừa dựng — đúng như người dùng đọc màn
  hình — nên nó không thể lệch khỏi scheduler theo kiểu một robot giữ bản sao
  đáp án.
- **Con số cuối khớp đúng luật:** **20 lượt**, **15 câu trả lời**, 5 thẻ nhận
  `learned_at`. `browse` không ghi lượt nào (BR-111), `fill` không nhận thẻ nào
  vì không thẻ nào có `example` (BR-114) — nên chuỗi là
  browse → match → guess → recall.
- **Và nó bắt hai lỗi thật, cả hai chỉ lộ ra khi đi hết chuỗi:**
  - **Lượt `match` bị ghi cho thẻ của hàng đợi, không phải thẻ của term đã
    chọn** — vi phạm BR-118. Bàn ghép bày cả round, nên cặp người dùng với tay
    tới hiếm khi là thẻ đang ở đầu hàng đợi. `MatchBoardSectionWidget` **vẫn
    luôn** báo term nào được chọn; `_matchView` vứt nó đi và `answer()` mặc định
    lấy `turn.cardId`. Nay `answer()` nhận `cardId`, và chỉ `match` truyền.
  - **Bàn ghép mất dấu ✓ giữa hai lượt.** Màn hình đổi sang trạng thái loading
    khi chuyển thẻ, tức **gỡ bàn khỏi cây widget** và mang theo bộ nhớ `_matched`
    của nó — nên mọi ô đã ghép quay lại bấm được ở thẻ kế tiếp, và **cùng một
    thẻ bị ghi nhiều lượt**. IT đo được: `match` ghi **9 lượt cho 5 thẻ**. Nay
    tập đã ghép đọc từ hàng đợi (`completedCardsInRound`) và đi cùng lượt đọc
    của turn (AD-13) — dấu ✓ là **dữ liệu**, không phải trí nhớ của widget.
- **Vì sao không test nào khác bắt được:** cả hai chỉ xuất hiện khi bàn sống qua
  nhiều lượt liên tiếp trên một phiên thật. Widget test dựng bàn rồi bấm hai
  lần; test tầng dữ liệu không có bàn.
- **Tests:** `it_study_test.dart` (+2, gồm khẳng định **một lượt mỗi thẻ mỗi
  stage chấm điểm**), `match_board_widget_test.dart` (+2),
  `it_robot_study.dart` — nửa lái phiên học của robot.

### Suite IT đỏ vì hồi quy, không vì nợ có sẵn

- **Status:** hai nguyên nhân đã tìm ra và vá; phần còn lại chưa quy được trách nhiệm
- **Câu hỏi của chủ dự án:** *"việc này do degrade do phát triển chức năng mới à?"*
  Trả lời: **đúng**, và em đã kết luận sai một lần trước đó — lần chạy 49/15 đầu
  tiên diễn ra **trên nhánh đã có thay đổi của em**, nên "có sẵn trên main" là
  suy luận chứ không phải phép đo. Đúng thứ mục golden bên dưới cảnh báo.
- **Bằng chứng từ lịch sử git, không phải từ cảm nhận:** `it_*_test.dart` lần cuối
  được sửa ở #145 (2026-08-05) với ghi chú **60/60 PASS**.
  `FixtureSeederWidget` ra đời ở #155 (**2026-08-06**) — một ngày sau. Bảy mươi PR
  chạy giữa mốc đó và mốc bắt đầu phiên này, và không PR nào chạy lại suite: IT
  **không nằm trong CI**.
- **Hồi quy thứ hai là của em, ở PR #229 (UC-07).** `deckRepositoryBinding` mọc
  thêm phụ thuộc vào `studyRepositoryProvider`; `ItHarness` tự viết danh sách
  binding gồm **hai** dòng, nên provider thứ ba là contract-only và đọc nó ném
  ngay trong `wipeAllData()` — tức trong `ItHarness.open()`, trước bước đầu tiên
  của **mọi** kịch bản. Đo được: **0 xanh / 66 đỏ**. Unit gate vẫn xanh suốt, vì
  CI không chạy IT.
- **Vá bằng cách xoá cả lớp lỗi, không chỉ ca này.** `repositoryBindingOverrides()`
  là **một** danh sách, dùng bởi composition root và bởi cả hai container của
  harness. Một binding mọc thêm phụ thuộc nay không thể phá một container được
  viết từ danh sách ấy.
- **Và có test đơn vị cho chính lớp lỗi đó**, vì CI không chạy IT:
  `bootstrap_test.dart` dựng container từ chính danh sách rồi **đọc từng
  contract** — declaration nào chỉ được khai báo mà chưa bind thì ném. **Đã chứng
  minh** bằng cách bỏ `studyRepositoryProvider` khỏi danh sách: test đỏ, rồi khôi
  phục.
- **Hồi quy thứ ba, cùng một câu chuyện lần thứ ba.** `ItFixtures._promote` "thăng
  hạng" một thẻ bằng cách ghi `due_at`, `current_box`, `answer_count` — và
  **không bao giờ ghi `learned_at`**. Từ schema v5, BR-90 định nghĩa *New* là
  `learned_at IS NULL` và BR-151 định nghĩa *Due* là `learned_at` có **và**
  `due_at` đã tới. Nên mọi thẻ fixture đọc ra là New vĩnh viễn, mang một lịch mà
  nó không được phép có (BR-149) — đúng thứ invariant 28 tồn tại để bắt. Sáu
  kịch bản khẳng định badge, filter và pill đếm số đang đo đúng cái đó.
- **Con số đo được, từng bước:** `0/66` (binding) → `56/10` → `59/7` (fixture)
  → **`66/66`**.
- **Bảy ca còn lại, bảy nguyên nhân, tất cả đã vá — suite trở lại `66/66`.**
  Bốn trong số đó là **test xanh vì lý do sai**, tức tệ hơn test đỏ:
  - **Fixture mâu thuẫn spec của chính nó.** `00-agent-execution-guide.md` §S-DUE
    ghi `C-P-REVIEW` đến hạn `T0 − 1 ngày`; code ghi `T0 + 2 ngày` — vốn là ngày
    của thẻ *Future only*. Nên `Due` là 1 chứ không phải 2. Nó ẩn suốt thời gian
    BR-22 còn tính thẻ `due_at IS NULL` là đến hạn: thẻ chưa học làm con số thành
    2 một cách tình cờ. BR-142 bỏ mệnh đề ấy, và lỗi của fixture mới lộ ra.
    Sửa fixture xong thì `IT-ORG-003`, `IT-ORG-005`, `IT-ORG-010` đỏ — vì chúng
    được viết theo fixture **sai**. Nay cả ba theo spec.
  - **Pill bỏ số đếm khỏi nhãn** (khi mỗi pill có icon thì hàng không còn vừa
    390) — số chuyển sang `cardFilterSemantics`. Test đọc nhãn cũ; nay đọc
    accessible name, tức đọc đúng con số mà tên kịch bản nói tới.
  - **`find.byIcon(Icons.flag)` luôn khớp**, vì pill *Flagged* dùng **cùng** icon
    ấy — có chủ đích. Nên ba bước đầu của `IT-ORG-004` xanh **mà không thẻ nào
    từng được gắn cờ**, và bước cuối là bước duy nhất trung thực. Nay có
    `robot.rowFlags()` chỉ tìm trong `CardTileWidget`.
  - **`find.text('abandon')` khớp chữ trong ô tìm kiếm**, nên bước 1 của
    `IT-ORG-001` xanh dù không hàng nào sống sót qua filter. Nay có
    `robot.cardRow()`.
  - **Tab đổi tên Review → Study** ở #186 — cùng thủ phạm với bốn golden cũ.
  - **"Tìm thấy" khác "chạm được", và ba kịch bản chết ở đúng khoảng cách đó.**
    Widget dưới màn hình vẫn được dựng và vẫn tìm thấy; `tester.tap` bấm vào tâm
    nó và hit-test **thứ đang ở đó** — kể cả thanh điều hướng dưới.
    `IT-ORG-012` bấm "Load 50 more" và **mở tab Study**; `IT-CARD-005` bấm "Save
    card" trên form đã cuộn qua nút, rồi đọc màn hình không đổi thành "lưu thất
    bại". Nay mọi cú chạm của robot đi qua `_tapVisible`, và `scrollToText` kết
    thúc bằng `ensureVisible`.
- **Bài học chung của cả ba, và nó không phải về Study:** IT **không nằm trong
  CI**. Bảy mươi PR chạy giữa lần ghi `60/60 PASS` và mốc bắt đầu phiên này, mỗi
  PR gate xanh, và không PR nào biết mình vừa làm đỏ suite. Ba nguyên nhân đều là
  *một luật hoặc một dây nối đổi, còn thứ mô phỏng nó thì không đổi theo*.

## Việc không thuộc Study nhưng chặn Definition of Done

**~~Golden `deck_screens_demo_test` lệch 0.06% trên Windows~~ — không phải drift,
là golden cũ.** Lượt điều tra riêng đã chạy, và chẩn đoán trong tài liệu này sai
một nửa: đúng là hỏng sẵn trên `main` từ trước M5, nhưng **không** phải do cách
Windows dựng chữ.

Đọc `isolatedDiff.png` thì chỉ đúng **một từ** khác nhau, ở hai chỗ: nhãn tab
dưới cùng và nút trên thẻ deck. Golden ghi **"Review"**, màn hình dựng
**"Study"**. `git log -S` chỉ thẳng: PR #186 đổi tên Review → Study trong `lib/`,
còn bốn ảnh golden lần cuối được cập nhật ở #160 — **trước** #186. Bốn ảnh chỉ
đơn giản là chưa được dựng lại.

Con số 0.06% / 1946px **giống hệt nhau ở cả bốn** đáng ra đã là manh mối: một
khác biệt do renderer sẽ rải khắp ảnh và không thể trùng số pixel ở bốn khung
hình khác nội dung.

Đã dựng lại bằng `--update-goldens` **trên Windows**, đúng nền mà CI job
`goldens (windows)` chạy. Toàn bộ 115 golden xanh.

**~~Config chết trong guard~~ — đã xoá.** Rule
`memox.architecture.single_study_mode_dispatch` loại trừ `study_mode_resolver.dart`,
nhưng `memox.naming.domain_file_role_suffix` cấm suffix `_resolver` dưới
`domain/` — không file nào tên đó tồn tại được, nên dòng exclude ấy che một thứ
không có thật. Đã xoá khỏi `scopes.yaml`, và thông điệp của rule sửa từ *"in the
resolver"* thành *"beside the enum in `study_mode.dart`"*, tức nói đúng chỗ luật
thật sự sống. **Đã chứng minh rule vẫn bắt** bằng cách tạo một switch thứ hai
trên `StudyMode` dưới `domain/usecases/`: guard đỏ đúng dòng đó, rồi xoá đi.
