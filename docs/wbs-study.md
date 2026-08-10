# WBS Study — việc còn lại của chức năng học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Sổ tiến độ riêng cho chức năng Study — mọi việc còn lại để UC-05 dùng được thật |
| **Scope** | Task còn lại của Study từ M5.7 trở đi · nợ kỹ thuật của Study · việc bị chặn |
| **Source of truth for** | Trạng thái task Study từ M5.7 · nợ kỹ thuật của Study |
| **Depends on** | `document-conventions.md` · `wbs.md` · `business-rules.md` · `use-cases.md` |
| **Updated by task** | `guess`, `recall`, `fill` theo handout layout |
| **Last updated** | 2026-08-09 |

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

### BR-155 · Xem lại thẻ đã qua trong `browse`, sau M5.20

- **Status:** **done** — analyze sạch, 1658 unit + 30 visual audit + 115 golden
  xanh, cả bốn guard sạch
- **Nguồn:** chủ dự án đưa spec layout của một design kit khác cho màn
  Study · Review, trong đó có cử chỉ vuốt. Vuốt để lùi trước đây đã bị **loại**
  ở §7.7 với lý do `cursor` chỉ tiến; chủ dự án lật lại quyết định đó và chốt
  **dựng cả hai chiều, và lùi chỉ để xem**.
- **Luật mới:** BR-155 trong `docs/business-rules.md`. §7.7 của
  `docs/wireframes/m5-study-modes.md` viết lại từ "bỏ" thành "đã dựng".

Lý do cũ vẫn đúng và chính nó là hình dạng của luật mới: `cursor` **không** lùi.
Lùi chỉ đổi *thẻ nào đang được vẽ* — thẻ giữ nguyên `completed`, không ghi gì, và
tiến lại qua thẻ đó không gọi `markBrowsed` lần thứ hai. Nếu lùi có đụng vào
queue thì tiến lại sẽ ghi thẻ hai lần và bộ đếm nhảy gấp đôi; đó là ca hỏng mà
luật này tồn tại để chặn, và nó có test riêng.

Chỉ `browse`. Năm stage còn lại đều lấy câu trả lời từ thẻ đang hiện, nên đặt một
thẻ đã chấm lên đó là mời chấm lại (BR-126) — có test cho việc `match` không lùi
được.

**Recursive review tìm ra bốn thứ:**

1. **Vết thẻ đã xem được đọc bằng câu truy vấn không có `ORDER BY`.** `browse` đi
   ngược danh sách ấy nên thứ tự quyết định "thẻ trước là thẻ nào";
   `match` — người đọc duy nhất trước đây — dùng nó như một tập nên không thể
   thấy. Đã thêm `ORDER BY position`.

   **Nhưng test viết ra để bắt lỗi này đã không bắt được, và điều đó được ghi
   đúng như vậy trong chính test.** Dựng lại ba hàng theo thứ tự rowid **ngược**
   với `position`, câu truy vấn cũ vẫn trả về đúng thứ tự `position`: planner
   chọn index trên `(session_id, mode, round)` và index đó đi theo `position`.
   `ORDER BY` vẫn được thêm — một thứ tự chỉ đúng nhờ query plan hiện tại là thứ
   tự sẽ không ai được báo khi plan đổi — nhưng test đứng **cho** hợp đồng chứ
   không **chống** lại câu truy vấn cũ.

2. **Bản nháp đầu của test thứ tự tự viết `ORDER BY` của nó**, nên assert đúng
   câu SQL do chính test viết ra và không chạm gì tới app. Đã sửa để đọc qua
   `nextTurn` → `progress.completedCardIds`.

3. **Offset lùi sống sót qua thẻ kế tiếp.** Nó đếm ngược từ lượt đang mở, nên một
   offset còn sót lại sẽ vẽ đè một thẻ người dùng đã đi qua lên thẻ vừa tới — và
   không có gì trên màn nói điều đó. `_pullTurn` nay đặt lại về 0; có test.

4. **`isLookingBack` vẫn đúng khi không còn lượt nào.** `leave()` xoá `turn`
   nhưng để nguyên offset, nên state tự nhận là đang hiện một thẻ cũ trong khi
   không giữ thẻ nào. Nay `isLookingBack` đòi có `turn`.

**Quyết định của agent, không có trong docs:**

- **Vuốt phải có control tương đương, không chỉ có cử chỉ.** Kéo ngang 70dp là
  thao tác không tồn tại với người dùng screen reader, nên một vết chỉ tới được
  bằng vuốt là tính năng có mà không ai chạm tới. Nút `Thẻ trước` hiện cạnh nút
  tiếp khi có vết, và **vắng mặt** khi không — nút disabled quảng cáo một chỗ
  không có đường tới.
- **Thẻ không bị ném ra khỏi màn rồi mới đổi** như design kit mô tả. Ném thì phải
  giữ thẻ cũ ở đâu đó trong lúc bay, và nếu bước đi bị từ chối thì thẻ nằm ngoài
  màn không có gì kéo về. Trôi về chỗ cũ rồi để nội dung mới hiện tại chỗ thì
  không bao giờ kẹt. Animation đi qua `AppMotionPolicy`, nên nó tắt khi hệ điều
  hành bật reduce-motion.
- **`browseStep` là **một** tên, không phải hai.** `lookBack` + `browseForward`
  làm guard `command_query_separation_test` đỏ, và guard đúng: tập tên của
  session controller được cố ý đóng. Hai chiều của cùng một cú vuốt là một trách
  nhiệm, nên chúng gộp lại; allowlist của guard được nới đúng một tên, kèm lý do
  vì sao offset không thể ở trong một notifier riêng (nó phải bị xoá khi lượt
  đổi, nên tách ra là đặt một giá trị dưới hai chủ).

### Khung phiên học theo phản hồi ảnh chụp, sau BR-155

- **Status:** **done** — analyze sạch, 1660 unit + 30 visual audit + 115 golden
  xanh, cả bốn guard sạch
- **Nguồn:** chủ dự án chạy app thật, chụp màn hình và nêu năm điểm.

| Điểm | Đã làm |
|---|---|
| Nhãn *"Swipe left for next, right to go back"* không có | `studyHintBrowse` nay nói đúng câu đó; mô tả ARB cũ vẫn ghi *"there is no swipe back"* — đã sửa theo BR-155 |
| `Living room · Learning` không có ý nghĩa | dòng context nay nói **cỡ phiên**: `12 THẺ MỚI` / `12 THẺ ĐẾN HẠN` |
| Nút Next vẫn còn dù đã có vuốt | bỏ hẳn; đường cho screen reader là hai custom semantics action trên vùng vuốt |
| Thanh tiến trình quá ngắn | 108px → **226px** ở khung 393 |
| Vào phiên vẫn bọc nav bottom | phiên push trên **root navigator** |

**Thanh tiến trình: nguyên nhân không phải cỡ icon.** Đo mới thấy: `Flexible`
mặc định `flex: 1`, nên pill và bộ đếm mỗi cái được *cấp* một phần ba khoảng
trống, dùng đúng phần cần, và phần thừa dồn thành **118px chết** ở cuối hàng.
`flex: 0` cho cả hai thì `Expanded` của thanh lấy hết. Có test đo, vì không phép
kiểm nào về chữ nhìn thấy được lỗi này.

**Nút ✕ hẹp còn 36 theo spec, nhường chiều ngang thôi** — giữ nguyên 48 chiều
cao. `MxIconButton` có `isCompact`, `MxCard` có `radius`; `AppRadius.xl = 20` và
`AppIconSize.mdCompact = 20` thêm vào **cả hai kit**, kèm modifier CSS và test
parity. Đây là ba thứ đã bị em từ chối ở §8.2 của wireframe; chủ dự án yêu cầu
lại nên đã dựng.

### Bug `recall` vẽ "lượt đã chốt" đè lên câu hỏi đang mở

Suite IT chạy trên emulator sau BR-155: **64/66**, hai kịch bản đỏ, cả hai ở
`it_study_test.dart`. Chẩn đoán ban đầu của em là hồi quy do vuốt thẻ — **sai**.

Log nói rõ: robot tìm nút *Show answer* ở stage `recall` mà màn đang hiện *"This
turn is settled. The next round starts a fresh twenty seconds."*

`didUpdateWidget` của ba widget mode chỉ so `cardId`. Một lượt `recall` **hết
giờ** được ghi danh vào round sau (BR-116), và round sau phục vụ **cùng
`cardId`** — nên guard đọc lượt mới thành lượt cũ, giữ nguyên `_outcome`, và vẽ
màn "đã chốt" lên một câu hỏi đang mở, không còn nút nào để đi tiếp.

Nó **không** do việc gì mới: chỉ hiện ra khi có lượt thật sự hết giờ, tức là trên
máy chậm. Suite trước đó xanh vì chưa lượt nào timeout.

`fill` và `self_assess` cùng lỗi ấy — một ô nhập còn giữ lần gõ trước, một thẻ
còn lật sẵn. Khái niệm "cùng một lượt" nay ở `StudyTurnModel.isSameTurnAs`, so cả
`cardId` **và** `round`, để cái thứ tư không lặp lại. Có test, và đã **chứng minh
test bắt được** bằng cách đổi tạm về so id thôi rồi xem nó đỏ.

### `MxSessionTopBar` và dòng gợi ý, sau vòng review ảnh chụp thứ hai

Chủ dự án review thanh trên của phiên học năm vòng liên tiếp. Kết quả không phải
năm lần chỉnh số mà là **một component chung** và **hai quy tắc đặt mép**; số đo
đầy đủ ở `wireframes/m5-study-modes.md` §8.4 và §8.5.

**Ba lỗi có thật, cả ba đều không phép kiểm nào thấy được:**

- `MxIconButton.isCompact` ràng buộc hộp còn 36 và **ràng buộc ấy chưa bao giờ có
  tác dụng** — `MaterialTapTargetSize.padded` bơm lại về 48 rồi căn giữa cái 36
  bên trong. Hàng vẫn tiêu 48 *và* glyph lùi 14 so với chỗ nút bắt đầu, trong khi
  bộ đếm đầu kia dừng đúng gutter. Hai đầu lùi khác nhau chính là cái đọc ra
  thành "thanh header lệch tâm".
- Test `320×568 @ textScale 2.0` dựng khung ở **nguyên 320** vì harness không có
  shell, còn production chỉ có 296 — nó chưa bao giờ đo đúng thứ đang chạy. Khi
  khung tự đặt gutter thì test khớp production và hàng **tràn 5.9px** với tên mode
  dài. Mức chặn chip nay đo theo *phần còn lại sau nút và hai khoảng*, không theo
  cả hàng.
- Tách hai đầu thành hai giá trị làm `start` tính ra **−2** ở gutter compact 12
  (glyph nằm sau hộp nó 14). `Padding` assert với inset âm và hạ **năm** test ở
  320 cùng lúc. Đã clamp ở 0.

**Không thu vùng chạm của nút ✕.** 48 là `AppSpacing.minimumTouchTarget` và
`androidTapTargetGuideline` khẳng định nó ở hai chỗ. Các mẹo "vẽ tràn ra ngoài ô"
— `Transform`, `OverflowBox` — cắt **vùng hit** theo ô cha trong khi `Semantics`
vẫn khai 48×48: gate xanh, chỉ ngón tay người dùng biết là hỏng. Khoảng cách ✕ →
chip khép lại bằng cách **bỏ spacer**, vì 14px còn lại là vùng chạm chứ không
phải không khí.

**Dòng gợi ý** hạ xuống `bodySmall`, căn giữa, và icon theo mode: `»` cho
`browse` (đi giữa các thẻ), `✓` cho bốn mode còn lại (thao tác trên thẻ đang
hiện) — đúng như năm ảnh wireframe vẽ. Câu của `browse` rút theo ảnh.

`MxSessionTopBar` nằm ở `lib/shared/widgets/`, **không biết `StudyMode` là gì**:
nhận một chữ cho chip, một `0…1` cho thanh, một widget cho ô cuối. Có golden
light/dark, stress specimen với tên dài, và mục Widgetbook.

### Bàn ghép `match` theo handout layout 390×780

Handout thứ hai của chủ dự án, lần này cho `match`. Bố cục dựng đúng: `Column`
gồm N hàng `Expanded`, mỗi hàng hai `Expanded`, `gap 8` hai chiều. Đo ở 390×780:
bàn **358 × 628**, ô **175 × 119.2**, bước hàng 127.2 — không còn dải trống dưới
ô cuối. Số đo đầy đủ và bảng dịch token ở `wireframes/m5-study-modes.md` §8.6.

**Điều handout không nói và code phải trả lời:** năm hàng là nội dung của mock,
không phải luật. Bàn giữ cả round (BR-115), BR-153 chỉ đặt sàn hai cặp — mười
thẻ là mười hàng. Flex vì thế có **sàn** `minimumTouchTarget` nhân theo
textScaler, và bàn không đạt sàn thì cuộn. Đã kiểm 320 @ textScale 2.0.

**Nền ô đã ghép giờ dựng được**, sau khi M5.19 từng từ chối vì "không có token":
`Color.alphaBlend(success @12%, surfaceContainerLowest)`. Không phải thiếu token
mà là không được vẽ **trong suốt** — `color_source_rules_test` R7 cấm fill và
border translucent vì chúng composite lúc paint, nên một token ra hai giá trị
trên hai mặt nền. `mastery` của handout chính là `success` của dự án;
`card_state_widget.dart` đã sơn `CardState.mastered` bằng nó.

**Ba giá trị của handout không làm theo** — gutter 14, nút ✕ 36×36, thanh tiến
trình cao 4 — cùng lý do và cùng chỗ ghi: §8.7. Hai giá trị **có** làm theo: chip
viết HOA kèm letter-spacing, và icon dòng gợi ý lên `AppIconSize.sm`.

Nhân đó sửa một lỗi thật: dòng ngữ cảnh ghép hai chuỗi mà chỉ một chuỗi viết
hoa, nên `match` in `5 CARDS DUE · Round 1 · 4 pairs left`. Nay viết hoa ở chỗ
ghép, ARB giữ chữ chứ không giữ kiểu.

### BR-156 · `match` chia round thành bàn năm cặp

Ảnh chụp máy thật: mười thẻ ra một bàn hai mươi ô, ô cao 106 và người học phải
quét cả màn cho mỗi lần chạm. Chủ dự án chốt: **dù tổng thẻ là 10 hay 20 thì mỗi
lúc chỉ bày năm cặp.** Ba quyết định kèm theo, hỏi và chốt bằng popup:

| | chốt |
|---|---|
| round 11 thẻ chia sao | **đúng 5, bàn cuối lấy phần dư** → 5, 5, 1 |
| bộ đếm thanh header đo gì | **cả round** (`0 / 10`), không reset mỗi bàn |
| dòng ngữ cảnh | thêm bàn: `10 NEW CARDS · ROUND 1 · BOARD 1/2 · 5 PAIRS LEFT` |

Bàn một cặp **vi phạm BR-153 như đã viết**. Đã nêu trước khi hỏi và chủ dự án
chọn phương án đó, nên BR-156 phát biểu luôn phạm vi: sàn hai cặp của BR-153 áp
cho **stage**, không cho từng bàn — nó quyết định stage có chạy hay bị bỏ qua
theo BR-99, khác với cái đuôi của một round người học đã làm gần hết.

**Lỗi có sẵn phải sửa cùng lúc.** Bàn đang dựng từ `state.sessionCards` — *toàn
bộ* thẻ của phiên. BR-115 nói round 2 chỉ gồm thẻ trượt round 1, nên ở round 2
bộ đếm ghi `0 / 3` trong khi bàn vẫn bày đủ mười cặp. Không chia bàn thì không
lộ; chia bàn thì sai ngay từ chỉ số bàn. Nay có query `cardsInRound` và
`StudyStageProgressModel.roundCardIds`, đọc trong **cùng một** `nextTurn` với
counter (AD-13).

`roundCardIds` để `@Default([])` chứ không `required`: mọi lượt đọc từ repository
đều điền, còn mười lăm test dựng progress bằng tay thì quan tâm bộ đếm và sẽ phải
mọc thêm một danh sách thẻ chẳng nói lên gì. Rỗng thì caller lùi về tập thẻ nó
đang có — đúng hành vi cũ.

Chia chunk **trước** khi xoáo, nên thẻ nào ở bàn nào là do thứ tự `position` của
round quyết định (BR-117), và chỉ hai vế bị xoáo (BR-127). Đổi seed không đẩy
được một thẻ sang bàn khác — có test.

Nhân đó đo được một thứ nữa: `BOARD 1 OF 2` vừa khít một dòng ở 390 với đúng hai
pixel dư, rồi tràn xuống hai dòng khi số đổi từ `1` sang `2` — một dòng mà hình
dạng phụ thuộc vào việc đang ở bàn nào. Rút thành `BOARD 1/2`.

### Phản hồi đúng/sai của bàn ghép

Chủ dự án nêu hai ý; cả hai đúng chỗ đau. Sai **không có phản hồi nào** — chọn
sai chỉ xoá lựa chọn, nhìn hệt như bấm hụt. Và ô đã ghép giữ xanh tới hết round
là rác thị giác. Thiết kế và số đo ở `wireframes/m5-study-modes.md` §8.8.

§4 chốt "ô ở nguyên chỗ" vì **reflow**, không vì màu. Đề xuất *biến mất nhưng
không dồn* bỏ đúng cái đó ra, nên §4 giữ tinh thần và chỉ đổi cách làm: nội dung
tan, ô ở lại rỗng. Ô rỗng còn là bằng chứng tiến độ — nhìn bàn biết còn mấy cặp,
không tốn màu nào.

800ms của đề xuất ban đầu không dựng: `AppDurations.slow = 320` là **trần** đã
ghi của app, và bàn năm cặp sai bốn lần ở 800ms là 3.2 giây chết chồng lên thời
gian khoá lúc ghi DB. Chốt 320, bù độ rõ bằng việc tô **cả hai** ô thay vì bằng
thời gian, và **không khoá thao tác** — chạm term kế tiếp cắt đỏ ngay.

**Hai lỗi chỉ render mới thấy:**

- ô rỗng vẽ bằng `scheme.surface` ra *sáng hơn* nền trang (dark: trang
  `(10,8,45)`, `surface` `(26,24,56)`, nền ô `(10,3,38)`) — lỗ sáng hơn xung
  quanh đọc thành ô mới. Nay không vẽ nền, viền pha trên `scaffoldBackgroundColor`.
- nhịp xanh đặt bằng `AppDurations.normal`, **đúng bằng** thời gian chuyển màu
  của ô, nên suốt nhịp ô chỉ đang đi tới xanh rồi quay đầu: một vệt tím, xanh
  không hiện lần nào. Nhịp phải dài hơn chuyển màu.

Cả hai đều qua `flutter analyze`, guard và toàn bộ unit suite. Đây là lý do quy
trình review bằng ảnh render tồn tại.

Tách file theo guard: ô sang `widgets/items/match_tile_widget.dart` (AD-15 —
`items/` là hàng lặp lại và các phần của nó), test tách thành
`match_board_feedback_test.dart` theo đúng đường nối: file cũ nói về cái gì được
**ghi lại**, file mới nói về cái gì được **nói ra**.


### `guess`, `recall`, `fill` theo handout layout 390×780

Ba handout cùng lúc. `guess` **không đụng phán quyết nào** nên dựng nguyên
(§8.9). `recall` và `fill` đâm vào bốn thứ đã chốt, chủ dự án quyết từng điểm
bằng popup, chi tiết ở §8.10.

**Thứ đáng giá nhất lấy từ handout là cái tỉ lệ**: hai thẻ `Expanded` ngang
nhau, cùng sàn 160. Trước đó thẻ đề co theo chữ của nó còn vùng đáp án lấy
phần thừa — mỗi thẻ một hình dạng. `guess` cùng bệnh theo chiều ngược: thẻ đề
cố định làm lựa chọn thứ năm tràn ra ngoài màn — handout gọi đích danh.

`MxCard` thêm tham số `color` (nhận một **vai** của `ColorScheme`), để thẻ đáp án
lùi một bậc so với thẻ đề. Hai thẻ cùng nổi đọc ra thành hai câu hỏi.

Chỗ ẩn đáp án của `recall` đổi từ một câu sang một thanh mờ: câu "đáp án đang
ẩn" đặt đúng chỗ đáp án sẽ hiện là một dòng chữ người học đọc thay vì nhớ
lại. Câu đó ở lại trong `Semantics`, nơi nó vốn làm việc.

Ba file test phải pump **không cuộn** (`isScrollable: false`): ba section giờ lấp
đầy chiều cao được giao, còn scroll view giao cho chúng chiều cao vô hạn.

**Còn nợ, có chủ đích:** `Try again` / `Mark correct` của `fill` — cả hai quyết
định một lượt **ghi gì**, không phải hai cái nút. Đề xuất "hoãn việc ghi" đang
chờ duyệt ở §8.10. Và dòng gợi ý hai trạng thái cho cả ba màn — cùng một cơ
chế, nối một lần.

### Refactor IT theo Testing Pyramid — bước 1–3 và bước 8

Audit đầy đủ 127 kịch bản ở `it-scenarios/12-testing-pyramid-audit.md`. Phân bố
đề xuất: **88 HOST-FLOW · 67 HOST-WIDGET · 8 DEVICE-E2E** (5%, dưới ngưỡng 25%).
Hành động: 89 reclassify · 35 split · 3 keep. Không kịch bản nào bị xoá.

**Hai phát hiện về cổng CI, và cái thứ hai nghiêm trọng hơn cái thứ nhất:**

1. `integration_test/` **chưa bao giờ chạy trong CI**. 127 kịch bản không chặn
   một pull request nào — đó là lý do cơ học khiến suite đỏ 0/66 suốt bảy mươi
   PR mà không ai biết.
2. Bước test của `ci.yml` chỉ chạy `test/app` và `test/features/deck`. **Bộ lập
   lịch, mọi repository, toàn bộ truy vấn database và các migration cũng không
   được kiểm bởi PR nào** — chúng chờ `ci-full.yml`, vốn chạy thủ công. Cộng
   lại: trước lần này, dự án không có cổng tự động nào cho tính đúng nghiệp vụ.

Đã làm trong lượt này:

- `00-agent-execution-guide.md` §2–3 viết lại còn **ba** profile. Chín hồ sơ cũ
  (`UI`, `UI-FIXTURE`, `UI-RESTART`, …) mô tả *cách tay người chạm*, không mô tả
  *ranh giới thực thi* — nên mọi kịch bản rơi vào emulator theo mặc định.
- `scenario-catalog.md`: 133 dòng (127 + 6 `IT-PLAT`), cột `Hồ sơ` → `Profile`,
  thêm cột `Dẫn xuất`. `check_docs.py` học schema mới: profile phải thuộc ba giá
  trị (cho phép modifier và cặp khi tách), và ID dẫn xuất phải có thật — hoặc là
  một tiêu đề kịch bản, hoặc một dòng trong ma trận migration.
- `13-platform-boundaries.md`: sáu kịch bản `IT-PLAT` gom lại thứ mà **hai mươi**
  kịch bản `UI-RESTART` đang lặp. Restart là **một** ranh giới nền tảng, không
  phải một luật nghiệp vụ.
- 35 kịch bản bị tách đã có dòng "Tách thành" ngay dưới tiêu đề.
- `ci.yml` chạy **toàn bộ** host suite (`flutter test --exclude-tags golden`) —
  1678 test, ~51 giây cục bộ, không cần emulator.
- `ci-device.yml` mới: `DEVICE-E2E` trên emulator, chạy theo tag phát hành và
  workflow_dispatch. Nightly để sẵn dạng comment.

**Còn lại (§18 bước 4–7):** fixture builder, app harness cho HOST-WIDGET, dời và
viết test HOST-FLOW/HOST-WIDGET, rồi mới thu `integration_test/`. Không xoá test
cũ trước khi coverage tương đương đã xanh.

### Refactor IT — bước 4 và mở màn bước 5

**Fixture builder** ở `test/helpers/fixtures/study_fixtures.dart`, đặt tên đúng
theo mã `Chuẩn bị` của catalog: dòng kịch bản ghi `S-DUE` thì test gọi `sDue`.
Một cái tên, hai chỗ, không có bước phiên dịch nào ở giữa.

Phủ được: DB rỗng · root deck · cây deck · card · card đã học · card đến hạn ·
card hạn tương lai · trạng thái Eight Box (`current_box`) · trạng thái SM-2
(`ease_factor`, `interval_days`, `repetitions`) · session đang dở · study queue ·
`scheduler_generation`. Mọi mốc thời gian dẫn xuất từ `testNow`, mọi id cố định.

`insertCard` được mở rộng để nhận `front`/`back` và **ghi `back_folded`**. Mặc
định cũ để cột ấy rỗng, mà BR-123 đo hai nghĩa khác nhau bằng chính dạng đã
fold — nên một fixture cũ làm mọi câu hỏi `guess` không dựng được, vì một lý do
chẳng liên quan gì tới kịch bản đang kiểm.

**Năm kịch bản `FIXTURE-BLOCKED` đầu tiên đã chạy được**, ở
`test/integration/flows/discovery_and_progress_flow_test.dart`: IT-DISC-001F,
IT-DISC-003F, IT-ORG-003, IT-ORG-005, IT-ORG-010. Chúng **chưa từng chạy lần
nào** — không phải "chưa được kiểm" mà là "không chạy được". Điểm chung: cả năm
đều xoay quanh một *predicate trên hàng tại một mốc thời gian biết trước*, thứ rẻ
nhất để chứng minh ở tầng này và đắt nhất khi chứng minh qua màn hình.

Fixture `S-DUE` đặt một thẻ đến hạn **đúng bằng** `now` có chủ đích: một predicate
sai ở biên vẫn qua được mọi test chỉ dựng từ "hôm qua" và "ngày mai".

Còn lại của bước 5–7: 83 HOST-FLOW và 67 HOST-WIDGET nữa, app harness cho
HOST-WIDGET, rồi mới thu `integration_test/`.

### Refactor IT — bản đồ coverage, và khối lượng còn lại nhỏ hơn tưởng nhiều

Trước khi viết nhóm tiếp theo, dựng `14-host-coverage-map.md` bằng dữ liệu: nối
từng kịch bản với test host **nhắc tới cùng ID luật**. Kết quả đổi hẳn kế hoạch:

| Trạng thái | Số kịch bản |
|---|---|
| đã có test host nhắc tới **mọi** luật | **107** |
| một phần | 23 |
| chưa có | 3 |

Nghĩa là "83 HOST-FLOW còn phải viết" là con số sai. Việc thật sự là **16 luật**
chưa test nào chạm: BR-02, BR-21, BR-23, BR-24, BR-27, BR-28, BR-46, BR-75,
BR-80, BR-98, BR-100, BR-102, BR-122, BR-131, BR-140, BR-143.

Cả nhóm TREE (14 kịch bản) **đã được chứng minh sẵn** ở
`deck_repository_tree_test.dart` và các file cạnh nó, trên SQLite thật. Viết lại
chúng là vi phạm §5 chứ không phải hoàn thành §18.

**Bản đồ là danh sách việc, không phải giấy chứng nhận.** Một test nhắc BR-62 gần
như chắc chắn đang kiểm BR-62, nhưng chưa chắc khẳng định **đúng cái** kịch bản
cần. Bước còn lại với 107 kịch bản kia là *đọc và xác nhận*, không phải viết lại.

Đã viết `test/integration/flows/session_freeze_flow_test.dart` cho bốn luật đầu
tiên trong danh sách: BR-23, BR-24, BR-102 — sáu test, phủ IT-STUDY-010,
IT-STUDY-011, IT-REVIEW-004, IT-LEARN-011, IT-CONT-006 và nửa host của
IT-CONT-001.

**Một chỗ suýt ghi sai luật vào test.** Bản đầu khẳng định hàng đợi ôn tập xếp
theo `due_at` tăng dần và nó đỏ. Đọc lại thì BR-23 chi phối **thẻ nào được lấy**,
còn BR-117 bắt mỗi round có **thứ tự xoáo riêng** — khẳng định position theo
`due_at` là khẳng định ngược lại BR-117. Test nay kiểm thứ BR-23 thật sự đáng
giá: khi trần cắt, nó lấy đúng những thẻ **quá hạn lâu nhất**. Một trần lấy nhầm
phía sẽ để món nợ cũ nhất lớn mãi, và không phép kiểm thứ tự nào trong hàng đợi
nhìn thấy điều đó.

### Refactor IT — nhóm learning/review

`test/integration/flows/answer_kind_flow_test.dart`, sáu test cho sáu luật chưa
test nào chạm: **BR-21, BR-27, BR-28, BR-75, BR-140, BR-143**. Phủ IT-REVIEW-005,
IT-LEARN-005, IT-LEARN-006, IT-LEARN-009, IT-LEARN-010, IT-STUDY-006.

Cả sáu xoay quanh một câu: **một lượt ghi xuống cái gì, và nó được gọi là gì.**

- Phiên `learning` ghi `kind = 'learning'`, **không bao giờ** `scheduled`; phiên
  `reviewing` ngược lại (BR-143). Đây là luật một dòng mà hậu quả không sửa được:
  lịch sử ghi sai nhãn thì **không tính lại được**.
- Lượt `learning` có `next_due_at` NULL và không đụng `due_at` của thẻ (BR-27,
  BR-144). Lịch được ghi khi **chuỗi kết thúc**, không phải bởi từng câu trả lời
  trong chuỗi.
- Lượt đã chấm ghi **cặp trạng thái trước/sau** chứ không chỉ kết cục (BR-21).
  Một dòng chỉ lưu action thì không bao giờ trả lời được câu "hộp 3 có giúp
  không?".
- `forgotten` **giữ** thẻ trong round; chỉ action khác mới thả nó ra (BR-28).
- CHECK của cột `kind` được **thử phá** trực tiếp: một ràng buộc không ai chạm
  vào là một ràng buộc không ai biết là đã mất.

Vì sao đọc từ SQLite ra chứ không tin lời gọi vừa ghi: suy `kind` ra sau bằng
cách so lịch trước/sau **sai** với một lượt `scheduled` của thẻ hộp 8 — hộp không
nhúc nhích, nên phép so nói "chẳng có gì xảy ra".

Còn lại 10 luật: BR-02, BR-46, BR-80, BR-98, BR-100, BR-122, BR-131 và ba luật
của nhóm entry/options.

### Refactor IT — hết luật cho HOST-FLOW

Hai file cuối của bước 5:

- `stored_not_inferred_flow_test.dart` — **BR-46, BR-80, BR-98, BR-122, BR-131**
  (IT-CONT-003, IT-CONT-010, IT-MODE-001, IT-MODE-009, IT-MODE-015).
- `deck_naming_flow_test.dart` — **BR-02** (IT-DECK-002).

Bốn trong năm luật của file đầu nói **cùng một điều về những cột khác nhau: nó
được lưu, không được suy ra.** Mode của một lượt, lý do một lượt kết thúc, lý do
một phiên kết thúc, thế hệ dữ liệu một phiên thuộc về — mỗi thứ đều là một sự
thật mà app *gần như* dựng lại được từ hình dạng dữ liệu, và "gần như" chính là
vấn đề: tự nhận quên và hết giờ cho ra **cùng một `action`**; một lượt
`scheduled` của thẻ hộp 8 không làm hộp nhúc nhích. Một cột được suy lại là một
cột sai đúng ở chỗ nó quan trọng, và lịch sử thì không tính lại được.

BR-46 là bug "reset tự huỷ reset": một phiên mở trước khi Đặt lại thuộc thế hệ 1,
reset đẩy deck sang 2, và nếu câu trả lời đang bay vẫn hạ cánh thì reset âm thầm
tự huỷ chính nó. Test khẳng định nó bị từ chối **nguyên tử** — không để lại nửa
nào.

BR-02 đáng một test **chính vì nó trông như một sự sơ suất.** Luật nói tên deck
được phép trùng, còn mọi bản năng của người sắp thêm unique index thì nói ngược
lại. Hai deck cùng tên dưới hai gốc khác nhau là cách một cái cây được tổ chức
bình thường; một ràng buộc thêm vào "cho chắc" sẽ từ chối đúng hình dạng mà sản
phẩm cố ý cho phép — và nó sẽ không nổ ở đâu cả, chỉ đến vài tuần sau dưới dạng
"tôi không tạo được deck".

**Bản đồ coverage: 129 đã có · 1 một phần · 3 không có luật nào.**

Còn lại đều là `HOST-WIDGET` và đều **chờ bước 6**: BR-100 (`UI` scope — mode bị
chặn phải trình bày là không khả dụng, và MUST NOT gợi ý Reset), cùng IT-NAV-005,
IT-ORG-012, IT-MODE-013 vốn không truy vết tới BR nào. Không luật nghiệp vụ nào
còn chờ ở HOST-FLOW.

### Refactor IT — bước 6: app harness cho `HOST-WIDGET`

`test/helpers/app_harness/host_widget_app.dart` mount **ứng dụng thật** trên
host: `ProviderScope` thật, bindings thật, GoRouter thật, localization và theme
thật, trên SQLite in-memory và một đồng hồ được tiêm.

**Nó gọi `buildRootWidget`, không tự dựng `ProviderScope`.** Đây là toàn bộ
thiết kế: một harness tự liệt kê bindings bằng tay chính là cách dự án này mất
bộ integration một lần rồi — `deckRepositoryBinding` mọc thêm một phụ thuộc,
danh sách chép tay trong harness thì không, và mọi kịch bản ném lỗi ở `setUp`.
Dùng lại composition root nghĩa là binding thêm vào app là binding test có
ngay, và là binding test **không thể** bỏ sót trong im lặng.

`buildRootWidget` được thêm một seam thứ ba — `GoRouter? router` — vì `GoRouter`
mang lịch sử điều hướng: một instance dùng chung sẽ để route của test này quyết
định test sau bắt đầu ở đâu.

**Hai thứ chỉ lộ ra khi chạy thật, và cả hai đều không phải lỗi của test.**

`pumpAndSettle` treo 10 phút rồi chết bằng timeout không nói màn hình nào. Màn
đang chờ một stream chưa emit thì không bao giờ ngừng xếp frame. Thay bằng
`settleHostApp` — pump có trần — nên một màn kẹt hỏng ở đúng câu khẳng định của
kịch bản, thay vì treo cả lượt chạy.

Nghiêm trọng hơn: `A Timer is still pending even after the widget tree was
disposed`. Deck list hẹn một one-shot cho biên `due` kế tiếp; flutter_test kết
thúc test bằng cách unmount cây rồi assert không còn timer, còn Riverpod dispose
scope trễ một microtask — nên assert nổ trước, trên một test không làm gì sai,
với thông điệp nói về một timer nó không hề nhắc. Tệ hơn nữa, lỗi này **đầu độc
cả file**: test kế tiếp thừa hưởng timer treo và *hang* thay vì fail — đúng 7
phút trong lần chạy đầu.

Vì vậy mount và unmount là **một lời gọi**: `runHostApp(tester, body)`. Một test
không thể lấy vế đầu mà bỏ vế sau.

**Bốn kịch bản cuối cùng của bản đồ coverage đã có test.**

| Kịch bản | Ở đâu | Khẳng định gì |
|---|---|---|
| IT-NAV-001 · IT-NAV-003 · IT-NAV-005 | `test/integration/widgets/navigation_widget_test.dart` | Cold start rơi vào deck list; mở deck rồi `pop` quay về đúng chỗ; route không tồn tại hiện `RouteNotFoundScreen` **và không** âm thầm chuyển hướng về deck list |
| IT-STUDY-006 (BR-100) | `test/integration/widgets/blocked_mode_widget_test.dart` | Mode bị chặn nói **dữ liệu nó cần** và không gì khác — không câu nào trên màn chọn chứa "reset" hay "learning progress" |
| IT-ORG-012 | `test/integration/flows/card_window_flow_test.dart` | 65 card, cửa sổ 50 → 65: không trùng row, không mất row, thứ tự của lần đọc trước giữ nguyên |
| IT-MODE-013 (bước 2) | `test/integration/widgets/study_mode_accessibility_widget_test.dart` | Option của `Guess` đọc ra **nghĩa** và **kết quả bằng chữ**; chữ cái A–E bị `ExcludeSemantics` giữ ngoài |

**IT-NAV-005 tự nó là một phát hiện.** Ở route không khớp, `RouteMatchList` rỗng
và đọc `router.state` ném `Bad state: No element`. Nghĩa là 404 là **địa điểm
duy nhất router không mô tả được** — nên bất kỳ đoạn code nào với tay vào
`router.state` để quyết định vẽ gì sẽ vỡ đúng ở đây. Test khẳng định trên cái
đang hiển thị, không trên `router.state`.

Ba kịch bản còn lại đã có sẵn coverage và **không viết lại** (§5 cấm lặp): bước
1, 3, 4 của IT-MODE-013 nằm ở `study_accessibility_test.dart`,
`recall_widget_test.dart` và hai file match; nửa màn hình của IT-ORG-012 nằm ở
`card_list_screen_test.dart`. Cái viết mới là đúng nửa mà lớp kia không với tới
— và với IT-ORG-012 đó là nửa SQL, vì fake repository đồng ý với một `LIMIT` có
`ORDER BY` không ổn định hệt như với một cái ổn định.

**Bản đồ coverage: 133 đã có · 0 một phần · 0 không có.** `test/integration/`
36 test, xanh. Còn lại là bước 7 — thu `integration_test/` xuống 8 kịch bản
`DEVICE-E2E` thật.

### Refactor IT — bước 7: bộ device thu về đúng ranh giới nền tảng

`integration_test/` từ **9 file / 67 kịch bản** xuống **1 file / 8 kịch bản**.
Tổng dòng của thư mục từ 4149 xuống 1193.

Việc xoá an toàn vì đúng một lý do: **mọi luật nghiệp vụ mà 67 kịch bản kia đi
qua nay đã được `flutter test` chứng minh** — 133/133 dòng của
`14-host-coverage-map.md`, trên SQLite thật, chạy ở mọi PR. Cái còn lại là cái
host không với tới:

| Kịch bản | Ranh giới nó tồn tại vì |
|---|---|
| IT-PLAT-001 | Bootstrap của engine, đường database do nền tảng cấp, asset bundle của bản đã cài |
| IT-PLAT-002 | File thật trên bộ nhớ thiết bị, ghi bởi executor này đọc bởi executor khác |
| IT-PLAT-003 | `study_sessions.cursor` nằm trên đĩa chứ không trong RAM |
| IT-PLAT-004 | URL đến từ ngoài app, trên kênh của hệ điều hành |
| IT-PLAT-005 | Cử chỉ back của Android và đường nó tới `PopScope` |
| IT-PLAT-006 | Một bản dựng **không chạy được**: thiếu asset, sai flavor, R8, migration |
| IT-NAV-007 | Quản lý nội dung khi tắt sóng |
| IT-CONT-008 | Cả một phiên học khi tắt sóng |

**Luật nghiệp vụ cố ý không khẳng định lại ở đây.** Một kịch bản device đi lại
một luật là bản sao chậm hơn và dễ vỡ hơn của một test host — và bản sao mới là
cái mục ruỗng, vì nó vẫn xanh trong lúc luật đổi bên dưới, do không ai nhìn vào
bộ device cho tới khi nó đã đỏ.

**Một seam mới, và một seam bị xoá.** `ItHarness.deliverDeepLink` gửi
`pushRouteInformation` trên kênh `flutter/navigation` — đúng đường một deep link
đi vào, qua `RouteInformationProvider` rồi mới tới `GoRouter`. `openLocation`
(`appRouter.go`) bị xoá cùng lúc: để cả hai thì kịch bản sau sẽ chọn cái yếu
hơn, vì nó ngắn hơn và luôn chạy được.

**Hai giới hạn, ghi ra chứ không che.**

`restartApp` bỏ cây widget, đóng executor rồi mở lại đúng file đó. Nó **không**
phải cái chết của tiến trình: `flutter test` không giết được tiến trình nó đang
chạy trong đó rồi đi tiếp. Nên IT-PLAT-002 và IT-PLAT-003 chứng minh byte đã
chạm file và sống lâu hơn các đối tượng đã ghi nó — đúng cái khẳng định đáng
giá — còn nửa "OS kill" thì vẫn nợ. Tương tự, `deliverDeepLink` không chứng minh
được intent filter của Android; phần đó là `adb shell am start -a
android.intent.action.VIEW`.

**Airplane mode là tiền điều kiện của lượt chạy, không phải một bước.** Không
widget nào tắt được sóng, nên `ci-device.yml` làm việc đó:
`adb shell cmd connectivity airplane-mode enable` trước, `disable` sau, cả hai
đều `|| true` — thiết bị từ chối lệnh là lượt chạy yếu hơn, không phải lượt chạy
hỏng.

**Support chết đã xoá, không để lại.** `it_fixtures.dart` (248 dòng) không còn ai
gọi — 8 kịch bản device tự dựng trạng thái tối thiểu qua UI. `it_robot_lists.dart`
(258 dòng) cùng 6 helper trong `it_robot.dart` (`enterSearch`, `backToDeckLevel`,
`dismissSheet`, `revealOptionalFields`, `deleteOpenCard`, `tapBySemantics`,
`addTag`) chỉ phục vụ các kịch bản đã chuyển sang host.

**Bộ device tìm ra một lỗi thật ngay lần chạy đầu, và đó là toàn bộ lý do nó tồn
tại.** IT-PLAT-005 đỏ: cử chỉ back của Android pop route và để
`study_sessions.status` ở `in_progress` — đúng thứ BR-82 cấm. Trong `lib/` không
có `PopScope` nào. Trớ trêu là comment ở `study_session_screen.dart` đã nêu đúng
nguy cơ này khi giải thích vì sao bỏ app bar: *"a back arrow that pops the route
and leaves the session open, which is the one thing BR-82 forbids"* — cửa của
AppBar đã bịt, cửa của hệ điều hành thì không. Host không thấy được, vì host
không có cử chỉ.

Sửa ở app chứ không hạ chuẩn test: `PopScope` từ chối pop khi phiên còn sống rồi
gọi đúng `_controller.leave()` mà nút ✕ gọi — vì ✕ cũng không pop, nó kết thúc
phiên và trao màn tổng kết. Một cử chỉ back nhảy qua tổng kết sẽ là hợp đồng thứ
hai, im lặng hơn, cho cùng một hành động.

**Ba thứ khác chỉ lộ trên thiết bị, và không cái nào là lỗi nghiệp vụ:** chip
mode đã viết hoa từ #239 nên `find.text('Browse')` khớp rỗng; `browse` bỏ nút
Next từ BR-155 nên phải vuốt; và một lượt `recall` đã chốt **không có control
nào** (BR-129/BR-130) nên robot tap bừa rồi báo sai chỗ. Cả ba đều là "luật đổi,
thứ mô phỏng nó không theo" — đúng loại lỗi unit test không thấy.

`waitForText` được thêm vì `settle()` trả về ngay khi không còn frame nào được
xếp, mà một màn đang chờ một truy vấn thì không xếp frame nào — nên "còn một câu
query nữa" trông y hệt "sẽ không bao giờ tới".

**Kết quả: 8/8 xanh trên emulator-5554**, `flutter test integration_test/`.

### Browse — chỉnh sau vòng review (ưu tiên `eight_box`)

Ba thứ vòng trước làm sai hoặc làm quá tay, sửa lại trong phạm vi `browse`.
Không đụng `Sm2Scheduler`, không đụng `self_assess`, không thêm action nào vào
luồng eight-box. BR-106/107/110/111/112/146/155 **không đổi** — đây là UI và
thứ tự guard, không phải nghiệp vụ.

**1. Typography.** Vòng trước map cả hai mặt vào `headlineSmall` 24/w600 và gọi
là "peers". Nó chữa được việc front nuốt thẻ nhưng xoá mất hierarchy: hai khối
bằng nhau không nói gì về chỗ cần nhìn. Nay front `bodyLarge` (regular, là một
câu để đọc), back `titleLarge` hạ w500 qua `AppTypography.withWeight`. Variant
đổi tên `peers` → `frontSupportingBack` vì cái tên cũ đã mô tả sai quan hệ.

**2. Giữ card khi advancing bị áp toàn màn hình.** `_body` bỏ spinner cho *mọi*
mode, tức biến advancing thành khoá tương tác toàn cục — sai với `match`, vốn
trả lời nhiều cặp liên tiếp trên cùng một bàn. Nay chỉ `browse` có turn mới giữ
card; mọi mode khác giữ nguyên hành vi cũ. Phân biệt theo **mode**, không theo
scheduler.

**3. Guard `browseStep()` nằm sau nhánh forward.** Nhánh forward-từ-live-turn là
câu lệnh đầu tiên và `return` trước mọi guard, nên `isAdvancing` chỉ bảo vệ
nhánh xem lại — đúng nhánh *không* ghi gì. `answer()` xoá `isSubmitting` trước
khi `_pullTurn` bật `isAdvancing`, nên vuốt thứ hai rơi đúng vào khe đó và
`markBrowsed` chạy hai lần. Guard nay đứng trước cả hai nhánh.

**Một cái bẫy trong test đáng ghi.** Gate của fake ban đầu đặt ở `advanceStage`,
mà `AdvanceStudyStageUseCase` chỉ gọi hàm đó khi stage đã cạn — nên gate không
bao giờ đóng và test "giữ card" xanh mà chưa từng vào cửa sổ nó khai là đang
kiểm. Chuyển sang `nextTurn`, điểm mà mọi lần advance đều đi qua.

### Browse — chiều typography bị ngược, và vì sao

Chủ dự án chỉ ra nghiệp vụ: **front giữ từ vựng tiếng Hàn, back giữ nghĩa tiếng
mẹ đẻ.** `BR-08` đã nói đúng điều đó từ lâu — front trần 60 ký tự vì nó là
prompt vẽ trên một dòng, back trần 240 vì một nghĩa chứa hai ngôn ngữ — và tôi
đã suy ngược nó hai lần liên tiếp.

**Nguyên nhân gốc là một fixture bất hợp lệ.** Render Browse dùng front dài 67
ký tự; `CardText.parse` từ chối chuỗi đó, nên bức ảnh mọi quyết định typography
rút ra là ảnh của một thẻ **không người dùng nào tạo được**. Từ đó tôi kết luận
"front không đảm bảo là term" và đổi nhãn `TERM`/`MEANING` thành `FRONT`/`BACK`,
rồi hạ front xuống vai phụ. Cả hai đều là suy luận từ dữ liệu không hợp lệ.

Sửa: front `titleLarge` w500 (tiêu điểm), back `bodyLarge` (giải thích), variant
đổi tên `frontSupportingBack` → `backSupportingFront`. Fixture về đúng hình:
`부끄러워하다` ở front, nghĩa dài ở back.

**Guard để không tái diễn:** render test khẳng định mọi thẻ trong fixture thoả
BR-08 trước khi chụp. Một bức ảnh xanh của dữ liệu bất khả thi là thứ đã dạy sai
hai vòng liền.

**Còn mở:** nhãn `FRONT`/`BACK` được đổi từ `TERM`/`MEANING` dựa trên tiền đề
vừa bị bác. Nhãn hiện tại không sai — nó gọi tên cột — nhưng `TERM`/`MEANING`
nay lại đúng nghiệp vụ và nói được nhiều hơn. Chưa đổi lại vì chủ dự án chưa yêu
cầu, và đổi nhãn lần thứ ba mà không có yêu cầu là churn.

### Match — hai cột, hai giọng (ưu tiên `eight_box`)

Cùng thứ bậc `browse` vừa chốt, áp cho ô trên bàn ghép. Ô front giữ vai quét —
`titleLarge` @ `w500`, tối đa 2 dòng; ô back giữ vai đọc — `bodyMedium` (14/w400),
tối đa 4 dòng rồi ellipsis. Padding dọc xuống `AppSpacing.sm` để bốn dòng ấy có
chỗ. Lưới, năm cặp một bàn, thứ tự chọn term-trước-meaning, chấm điểm nhị phân,
năm trạng thái ô, thanh tiến trình và `Semantics` **không đụng tới**; SM-2,
scheduler, domain model và API công khai cũng vậy.

**Vì sao trước đó không ai thấy.** Cả hai cột dùng chung `titleMedium`/`titleSmall`
in đậm, và fixture cho mọi thẻ một nghĩa hai chữ — ca không bao giờ xuống dòng,
nên bàn trông cân. Nó chỉ lộ khi fixture mang đúng nghĩa BR-08 cho phép: một câu
giải thích in cùng giọng với từ nó giải thích, rồi cụt ở dòng thứ hai.

**Fixture sai lần thứ hai, theo một kiểu khác.** `turnFor` hardcode
`roundCardIds` là id của deck mặc định (`c1`…`c5`), nên bàn của deck Match
(`m1`…`m5`) không phân giải được thẻ nào và render ra lưới rỗng. Ba assertion
thêm ở vòng Browse — frame, chip, một mẩu nội dung — là thứ duy nhất bắt được;
golden vẫn xanh vì ảnh của bàn rỗng cũng là một ảnh. `roundCardIds` nay lấy từ
chính deck truyền vào.

**Bằng chứng:** `match_tile_widget_test.dart` (4 test — vai chữ của từng cột, quan
hệ term > meaning, ellipsis không tràn), `match_board_widget_test.dart` và
`match_board_feedback_test.dart` giữ nguyên xanh, `study_match_light.png` /
`study_match_dark.png` chụp lại ở 390×780.

### Match — ba ảnh trạng thái đè lên quyết định cột (ưu tiên `eight_box`)

Vòng #266 ở ngay trên vẫn đứng như một bản ghi: nó là vòng tách hai giọng cho hai
cột. Vòng này đè lên hai điểm của nó bằng ba ảnh trạng thái thật.

**Thứ tự cột đảo: meaning trái, Korean phải.** Mắt đọc khối dài trước rồi quét
cột ngắn để đối chiếu, nên khối sáu dòng thuộc về bên trái. Chỉ vị trí trình bày
đổi — hai danh sách trong domain không bị đảo, không bị dựng lại — và **thao tác
giữ nguyên: term tiếng Hàn vẫn phải chọn trước** (BR-118). Đây là chỗ dễ hỏng
nhất của thay đổi này: hoán vị hai `Expanded` rất dễ mang theo cả handler, và kết
quả trông không có gì sai.

**Typography #266 vẫn lớn hơn ảnh, và bốn dòng vẫn cụt.** Term xuống
`titleMedium` @ `w500`; meaning xuống `bodySmall` với sáu dòng. Chữ nhỏ hơn không
hạ vai trò của nghĩa — chiều cao ô thuộc về lưới, nên cỡ chữ đổi lấy **sức
chứa**: một nghĩa thật (hai ngôn ngữ, từ loại, ghi chú cách dùng) vừa sáu dòng
trong đúng cái ô từng chứa bốn.

**`minRowHeight` không còn là `minimumTouchTarget`.** Nó là 112, và mọi phần của
nó do typography phía trên quyết định: `bodySmall` 12/16, sáu dòng, padding `sm`
trên dưới — `6 × 16 + 2 × 8`. Ô vẫn là control và 112 vượt 48 rất xa; thứ đổi là
ràng buộc quyết định.

**Không đổi:** `MatchModeHandler`, shuffle, cách chia bàn, kết quả nhị phân của
eight-box, BR-118, BR-156, `successFlash`/`wrongHold`/motion policy, năm trạng
thái ô, cách giữ slot sau khi nội dung tan, Semantics và dấu ✓/✕, chrome của
phiên, token màu. SM-2, scheduler, database, domain model và API công khai không
nằm trong phạm vi.

**Ba trạng thái trong ảnh trước đây không có ảnh nào trong repo.** `wrong` và
`paired` chỉ tồn tại trong một nhịp rồi tự huỷ, nên **không** render nào settle
được có thể chứa chúng, và bàn giữa round có khoảng trống là trạng thái thứ ba.
`study_match_states_demo_test.dart` chụp cả ba, sáng và tối.

Hai bẫy phải trả giá mới thấy, cả hai đều cho ra một bức ảnh trông có chủ đích:

1. **Ô đã cleared vẫn giữ `Text` trong cây ở opacity 0.** Assert bằng
   `findsNothing` là sai câu hỏi — slot ở lại chính là điều đang được kiểm.
2. **Một `pump()` sau khi tap chụp đúng frame đầu của crossfade.** Nền là
   `AnimatedContainer` chạy `AppDurations.normal` còn màu chữ đổi ngay trong
   frame của tap, nên ảnh đầu tiên là chữ `onError` trắng trên nền còn gần như
   trắng — đọc thành "ô mất chữ", không phải "ô báo sai". Phải pump hai lần: một
   frame để animation khởi động, rồi `normal` để nó tới đích, và cả hai vẫn nằm
   trong `wrongHold`/`successFlash` (320ms) nên nhịp chưa hết.

**Bằng chứng:** `match_tile_widget_test.dart` (6 test — vai chữ và `fontVariations`
của term, vai chữ của meaning, quan hệ term > meaning, ellipsis ở đúng sàn 112,
padding đều, và ba component constant), `match_board_layout_test.dart` (7 test —
thứ tự cột, meaning-first không tạo lượt, sai vẫn thuộc term, cleared không
reflow, năm hàng lấp vừa, scale 2.0 chuyển sang cuộn, hai ô cùng hàng bằng chiều
cao), `match_board_widget_test.dart` và `match_board_feedback_test.dart` giữ
nguyên xanh, tám golden Match chụp lại ở 393×852.

### Match — trạng thái là viền và chữ, không phải nền

Ba ảnh nữa từ chủ dự án, cùng một nhận xét: board chớp quá mạnh. `selected` phủ
kín ô bằng `primary`, `wrong` phủ kín **hai** ô bằng `danger`, `paired` phủ nền
xanh lên hai ô.

**Nguyên nhân là diện tích, không phải duration.** Mỗi lượt chạm hai ô, nên một
trạng thái đặc tự nhân đôi diện tích của nó; trên bàn mười slot đó là một phần
năm màn hình đổi màu cùng lúc. Và vì meaning nay dài tới sáu dòng, một nền
`error` đặc biến cả đoạn văn thành một panel cảnh báo — một lượt ghép sai bình
thường đọc thành lỗi hệ thống. `wrongHold`/`successFlash` **không** bị rút ngắn:
nhịp giữ là feedback, không phải thứ gây chói.

**Skin mới:** cả năm trạng thái ngồi trên đúng `surfaceContainerLowest` của idle;
chỉ viền, chữ và icon đổi. `selected` → `primaryAccent`, `wrong` → `danger`,
`paired` → `success`, độ dày lên `AppStroke.input` (1.5) từ `hairline` (1).
`cleared` giữ ngoại lệ duy nhất: `background: null`, vì nó phải đọc như một
**lỗ** chứ không phải một ô trống.

`primaryAccent` chứ không phải `primary`, và đây là điểm dễ làm sai: `primary`
cố ý được giữ dưới headline của thẻ để một CTA đặc không lấn, nên dạng **chữ
trần** nó đọc 3.33:1 trên nền tối. Ô nay không còn nền primary, nên chữ là thứ
phải đọc được.

Gỡ `AppMatchTile.pairedFillAlpha` và `pairedOutlineAlpha` — không còn caller.
`clearedOutlineAlpha` ở lại vì viền của `cleared` vẫn blend.

**Ripple giữ nguyên, và nó vẫn là một mảng màu — đã đo, đã ghi.** Ripple là
`primary @ pressed` phủ cả ô; `InkRipple` mờ đi trong ~375ms, dài hơn hold
320ms. Nghĩa là trên máy thật vẫn có một mảng tím nhạt phủ ô **trong suốt** nhịp
giữ trạng thái, và ba golden transient chụp đúng khoảnh khắc đó — thấy rõ ở
light, gần như không thấy ở dark. Đó là phản hồi cho thao tác chạm chứ không
phải fill của trạng thái, nên vòng này không đụng; nếu muốn bàn yên hơn nữa thì
đó là một quyết định riêng về ripple.

**Không đổi:** meaning trái / term phải, thứ tự chọn, BR-118, hai ô cùng báo sai
rồi tự reset, hai ô cùng báo đúng rồi nội dung tan, slot ở lại không reflow,
✓/✕ và Semantics, chạm term kế tiếp vẫn kết thúc red sớm, typography, padding,
maxLines, `minRowHeight`, eight-box mapping, SM-2, scheduler, repository,
database.

**Bằng chứng:** `match_tile_widget_test.dart` +12 test (quan hệ
`background(selected|wrong|paired) == background(idle)` là contract chính, cộng
kiểm không state nào có nền bằng `primary`/`error`/`success`/`danger`, skin từng
state, `cleared` không vẽ nền, và cả ba quan hệ lặp lại ở dark);
`match_board_widget_test.dart` đổi "a selected term is filled" → "is outlined";
`match_board_feedback_test.dart` mở rộng cả hai kịch bản — nền vẫn là idle, viền
đúng token, và sau `wrongHold` viền/chữ quay về `borderControl`/hairline. Tám
golden Match chụp lại.

Một bẫy nữa: `matchesSemantics` khẳng định **cả node**, nên nó đỏ vì những flag
không liên quan mà ô mang hợp lệ. Đọc `Semantics.properties.selected` từ widget,
và phải lọc theo property — `InkWell` với `Material` bọc text bằng node riêng,
node gần nhất không phải của ô.

### Match — chọn được từ cả hai phía, ghi từng cặp, tải từng bàn

Bốn thứ trong một vòng, và ba trong số đó là lỗi chứ không phải tinh chỉnh.

**1. Bàn chỉ nhận term trước — và đó là một luật không ai viết ra.** State chỉ có
`_selectedTerm`, nên chạm nghĩa trước rơi vào hư không: không lựa chọn, không
lượt, không dấu hiệu nào cho biết đã có gì xảy ra. Nửa số cú chạm một người bình
thường làm bị bỏ im lặng, và dòng hint phải đi dạy một thứ tự mà trò chơi không
cần. BR-118 quy định *thẻ nào trả lời cho cặp* — luôn là thẻ sở hữu term — chứ
chưa bao giờ quy định phải chạm phía nào trước; nó nay nói đúng điều đó. Bốn kết
cục cho một cú chạm: giữ, bỏ giữ, chuyển lựa chọn trong cùng cột, hoặc hoàn tất
một cặp. Chuẩn hoá về `(term, meaning)` nên chạm nghĩa trước không đổi ai chịu
trách nhiệm cho lỗi.

**2. Nhịp giữ 320ms là một phép so sai đơn vị.** `AppDurations.slow` là trần
*chuyển động*; nhịp giữ là thời gian một trạng thái **đứng yên để đọc**. Đặt hai
thứ bằng nhau, trên một crossfade 200ms, để lại 120ms màu đứng yên — và kể cả
120ms ấy cũng không tới người dùng, vì màn gọi tải lượt kế tiếp ngay sau khi ghi
xong và bàn bị tháo khỏi cây widget. Nay 500ms cho đúng, 700ms cho sai; sai lâu
hơn vì phải tìm ra *hai ô nào* sai với nhau, còn đúng chỉ xác nhận điều đã biết.
Lo ngại "3.2 giây chết" của bản cũ dựa trên tiền đề nhịp giữ khoá thao tác —
không còn đúng: chạm ô kế tiếp cắt nhịp ngay, và cặp đang ghi DB không đóng băng
bàn (`isLocked` bỏ khỏi `match`).

**3. Reload sau *từng cặp* mới là thứ gây giật, không phải một lần ghi SQLite.**
Mỗi attempt gọi lại advance + get-next-turn: đọc lại session, queue, thẻ,
progress, và thay cả thân màn bằng loading state. Bàn năm cặp trả giá năm lần.
Tách làm hai: `submitMatchAttempt` ghi rồi dừng, cập nhật `completedCardIds` tại
chỗ; `advanceMatchBoard` chỉ chạy khi mọi cặp trên bàn đã ghép đúng. Lô 20 thẻ
vẫn 20 transaction — BR-25 không nhân nhượng — nhưng 4 lần chuyển bàn thay vì 20
lần reload. Callback trả `Future` nên ô chỉ đánh dấu sau khi ghi xong: bàn vẽ thứ
database đang giữ, không đoán theo cú chạm.

**4. Lỗi nghiệp vụ: ghép sai vẫn đánh dấu hàng queue `completed`.** `match` dùng
chung queue effect với các graded mode khác, mà ở những mode đó thẻ rời màn ngay
sau khi trả lời. Ở `match` thẻ **vẫn trên bàn**, nên `completedCardIds` — thứ
quyết định slot nào rỗng — chứa luôn thẻ vừa sai, và nó biến mất khỏi bàn ngay
lần refresh kế tiếp. Nay `match` + lapse: ghi answer/history, tăng
`answersInSession`, enroll round kế tiếp đúng một lần (`insertOrIgnore`, nên sai
bốn lần vẫn một hàng — BR-116), và **giữ hàng round hiện tại ở `pending`**. Ghép
đúng lại mới chuyển `completed`, và không xoá enrollment đã tạo.

Hệ quả phải chấp nhận: round 1 của `match` chỉ kết thúc khi **mọi cặp đã ghép
đúng** — điều đó luôn xảy ra được vì nghĩa đúng nằm sẵn trên bàn. Hai test cũ ở
`study_canonical_action_test.dart` khoá hành vi cũ (`done` đếm cả lượt sai, hai
lượt sai đủ mở round 2) đã viết lại theo luật mới.

**Không đổi:** meaning trái / term phải, typography, `minRowHeight`, feedback
bằng viền + chữ + icon (không nền đặc), năm trạng thái ô, slot ở lại không
reflow, ✓/✕ và Semantics, chrome phiên, BR-25, BR-156, eight-box mapping, SM-2,
scheduler, schema. Không thêm API batch.

**Dọn kèm theo, vì thay đổi này làm chúng thành thừa:** `answer()` mất tham số
`cardId` (chỉ `match` từng dùng, và `match` không đi qua đó nữa) — cùng với nó là
`StudyAnswerSink.cardId`; `browse` gọi thẳng `MarkBrowsedUseCase` thay vì mượn
đường chấm điểm và một hằng số `_browseHasNoAction` chỉ tồn tại để bị vứt đi ở
nhánh đầu tiên; `answer()` và `submitMatchAttempt` dùng chung một `_submit` và
một `_writeFailed`; `StudyBrowseStep` chuyển sang cạnh `StudySessionState`.

**Bằng chứng:** `match_board_layout_test.dart` (+3: cả hai chiều chọn đều ghi cho
thẻ của term, chạm lại để bỏ, chạm ô khác cùng cột chuyển lựa chọn),
`match_board_feedback_test.dart` (+3: nhịp còn sống trước mốc và hết sau mốc, cặp
chỉ được đánh dấu sau khi write resolve, bàn chỉ gọi tải một lần sau cặp cuối),
`study_match_commands_test.dart` (file mới, 5 test: attempt không fetch, đúng thì
counter chạy, sai thì bàn nguyên vẹn, đếm hai lần không vượt round, advance là
lần đọc duy nhất), `study_canonical_action_test.dart` (+3 test queue: sai giữ
`pending` và enroll một lần, đúng lại mới `completed` mà không xoá enrollment, mở
lại session thấy đúng cặp đã cleared). Tám golden Match chụp lại vì dòng hint đổi.

**Hai guard đã chỉ vào cùng một chỗ, và cả hai đều đúng.** Bản nháp đầu thêm
`submitMatchAttempt` **và** `advanceMatchBoard`, làm controller vượt trần 400
dòng, đồng thời `command_query_separation_test.dart` báo tên thứ bảy và thứ tám
trên một tập lệnh cố ý đóng. Đó không phải hai lỗi lint mà là một tín hiệu: viết
một cặp lệnh mới cho `match` là dựng lối ghi thứ hai. Nay chỉ còn **một** lệnh
mới — `advanceMatchBoard` — còn phần ghi là chính `answer` với hai tham số
(`cardId` quay lại, `shouldAdvance` mới), và `_pullTurn` là nhánh chứ không phải
đuôi bắt buộc. Lý do tên thứ bảy được nhận ghi ngay trong CQS test, cạnh lý do
của `browseStep` và `pause`.

### Lifecycle dùng chung cho năm mode — ghi, đọc được, rồi mới chuyển

Vòng Match trước để lộ một thứ lớn hơn Match: **`answer()` gộp hai việc**, ghi
đáp án và tải lượt kế tiếp. Gộp như vậy thì mọi feedback đã viết cho `guess`,
`recall` và `fill` đều không bao giờ đọc được — fetch bắt đầu ngay khi write trả
về, thân màn bị thay bằng spinner, và ô vừa xanh/đỏ được vẽ vào một widget đang
trên đường bị tháo. Sửa riêng cho Match sẽ đẻ tiếp `submitGuessAttempt()`,
`advanceRecall()`…

**Bốn tầng, mỗi tầng một câu hỏi:**

| tầng | trả lời |
|---|---|
| `studyModeHandler(mode)` | Strategy của mode: capacity, `canTake`, `canRunOn`, **`lapsePolicy`** |
| `SubmitStudyAnswerUseCase` | luồng chung mười bước, trả `StudyAnswerCommitModel` |
| repository | thi hành policy trong một transaction, trả status đã ghi |
| `studyModeView` + `studyModeFeedback(mode)` | thân màn của mode, và ngân sách đọc của nó |

**`if (mode == StudyMode.match)` trong data layer đã bỏ.** Mode khai báo
`StudyLapsePolicy` — `noAnswer` / `spacedRetry` / `completeAndEnrollNextRound` /
`retainAndEnrollNextRound` — và repository chỉ thi hành. Tầng dữ liệu không còn
nhận diện mode nào, tức không còn nhánh exhaustive thứ hai mà AD-18 cấm.

**Receipt, không suy luận.** `submitAnswer` trả `StudyAnswerCommitModel`
(`cardId`, `round`, `currentItemStatus`). Controller không được suy status từ
`action.isLapse`: cùng một lapse, `match` giữ hàng `pending` còn ba mode kia đóng
nó — đoán sai thì một ô trên bàn biến mất trong khi database vẫn giữ nó mở.

**`submitAnswer` + `advance(minimumVisible:)` thay cho `answer(shouldAdvance:)`.**
`advance` giữ nguyên `state.turn` trong lúc đọc, chạy song song việc đọc và việc
đợi, rồi mới đổi — fetch chậm không tốn thêm, fetch nhanh vẫn phải chờ hết nhịp.
Tập lệnh của controller vẫn bảy tên; `command_query_separation_test.dart` ghi lý
do tách ngay cạnh lý do của `browseStep` và `pause`.

**Không mode nào bị tháo để tải thứ thay thế** (BR-158). Test cũ
`a non-browse mode still shows loading while advancing` khẳng định đúng hành vi
sai — nay là `no mode is unmounted to fetch its replacement`.

**`isBusy` thay cho `isSubmitting` ở mọi `isLocked`** trừ `match`: thẻ ở lại màn
suốt cả write lẫn fetch, nên cả hai khoảng đều phải từ chối input. Trước đó chỉ
write được che, và cả quãng fetch là một cửa sổ cho cú chạm thứ hai. `match` giữ
`isLocked: false` vì bàn có bốn cặp khác đang chờ; nó tự khoá ở cuối bàn.

**Ngân sách đọc là component constant, không phải token motion** (§8.12):
guess 700/1200, recall 1800/2200, fill 800/2200, match giữ nhịp ở ô 500/700.
Sai luôn dài hơn đúng — một câu đúng cần được nhận ra, một câu sai cần được đọc,
tìm và hiểu.

**Dọn kèm:** `_nextTurn` trong controller ghép hai use case — đúng hình dạng
AD-13 cấm (hai read là hai snapshot). Thành `GetNextStageTurnUseCase`, một read
trả cả mode lẫn turn. Builder map của presentation thành `switch` exhaustive:
thiếu một khoá là màn trống lúc chạy, thiếu một nhánh là lỗi biên dịch.

#### Device suite bắt hai lỗi mà 1910 test trên host không thấy

Chạy trên emulator lần đầu: **5/8**. Ba lần chạy nữa mới về 8/8, và không lần
nào là "sửa test cho xanh".

**1. Khoảnh khắc đầu tiên của mọi phiên học là một màn báo lỗi.** Bỏ nhánh
`isAdvancing` khỏi `_body` mà không viết nhánh thay thế cho ca "chưa có turn
nào": lần `advance()` đầu tiên không có turn để giữ, `studyModeView` trả null, và
màn hình đọc null thành *"stage này không dựng được nội dung"* →
`StudyBlockedSectionWidget`. Comment tự viết đã nói trạng thái tải toàn thân chỉ
còn một ca — rồi không viết cái ca đó. Host không thấy vì lần đọc đầu tiên xong
ngay trong frame mở phiên; chỉ độ trễ thật mới lộ ra.

Test màn hình nay khẳng định thêm **không có `StudyBlockedSectionWidget`**: một
cái frame bọc quanh màn blocked vẫn thoả assertion "không có `MxLoadingState`"
trong khi người dùng chẳng có gì để thao tác.

**2. Robot giả định "có bàn nghĩa là có ô để chạm".** Từ BR-158, cặp cuối cleared
và bàn **vẫn mounted** trong lúc phiên tải bàn kế tiếp — `firstWhere` ném
`Bad state: No element` và không nói gì hữu ích. Bàn không còn ô mở là bàn *đã
xong*, không phải bàn kẹt: đợi, đúng như người dùng làm.

**Và một thứ không phải lỗi app: robot không đợi hết nhịp.** Nhịp giữ là một
`Future.delayed` — nó không schedule frame nào, nên `pumpAndSettle` đi xuyên qua.
Robot trả lời thẻ kế tiếp trong lúc màn hình còn hiện kết quả thẻ trước, đốt lượt,
chạm trần 60 lượt. `_holdFeedback` đọc `studyModeFeedback` — cùng nguồn với app,
nên ngân sách đọc đổi thì robot đi theo thay vì lệch âm thầm.

Thông báo lỗi của `studyUntilFinished` nay nêu **stage nào** đang trên màn. Lần
chạy thứ hai chỉ nói "không có gì để trả lời"; lần thứ ba nói "stage was none —
no mode body was built", và đó là câu chỉ thẳng vào lỗi 1.

### Ba lỗi async lifecycle còn lại, và một `Future<void>` là gốc của hai trong số đó

**1. Match coi "Future hoàn thành" là "đã commit".** `StudyMatchAttemptSink` khai
`Future<void>` trong khi controller trả `Future<StudyAnswerCommitModel?>` — receipt
bị xoá ngay ở typedef. `_land()` thêm term vào `_matched` mỗi khi Future hoàn
thành, nên hai thứ khác nhau cùng làm cặp biến mất: một ghi bị từ chối, và một
submission thứ hai bị controller trả `null` (persistence là single-flight). Cả hai
đọc thành "thành công".

Sửa: typedef trả receipt; `_land` chỉ đánh dấu khi receipt khác `null`; thêm
`_isSubmitting` cục bộ trong board để chặn khoảng trống trước khi parent rebuild —
parent không biết có write nào bắt đầu cho tới khi widget nói.

**2. Cả năm mode vẽ kết quả trước commit.** `guess` đặt `_chosenCardId`, `recall`
đặt `_outcome`, `fill` đặt `_isGraded`, `match` đặt `_wrongPair` — tất cả ngay
trong handler của cú chạm, rồi mới gọi callback. Đó là BR-157 bị vi phạm ở bốn
chỗ, và không chỗ nào kiểm được vì callback là `void`: không có khoảnh khắc nào
giữa cú chạm và write để một test đứng vào.

Sửa: mỗi mode tách **hai** field — cái đóng câu hỏi lại (`_isSubmitting`,
`_claimed`) và cái vẽ kết quả (`_chosenCardId`, `_outcome`, `_isGraded`,
`_wrongPair`). Cái đầu đặt lúc chạm, cái sau chỉ đặt sau receipt. Receipt `null`
trả màn về trạng thái hỏi lại được — từ chối *và* không nói gì là một màn hình
ngừng phản hồi không lý do.

**Nhịp giữ bắt đầu từ lúc kết quả hiện ra**, không phải lúc chạm và cũng không
phải lúc write xong: mode gọi `onFeedbackShown(isCorrect:)` sau `setState`, screen
mới chạy `advance(minimumVisible:)`. Đo từ cú chạm thì nhịp tiêu vào transaction;
đo từ write thì nó bắt đầu trước khi có gì được vẽ. Orchestration vẫn ở một chỗ:
screen ghi và screen chuyển lượt, mode chỉ nói "đã hiện rồi".

**3. Advance cũ ghi state sau khi đã leave.** `advance()` chỉ kiểm `ref.mounted`,
mà notifier vẫn mounted sau khi `leave()` chạy — nên một read đang bay về sau đó
ghi turn/mode/error đè lên phiên đã kết thúc.

Sửa: `_epoch` trong controller. `leave()` tăng epoch **trước** khi await (kết thúc
phiên cũng là một chuyến đi database, và một operation đang bay có thể đáp vào
giữa nó); mọi state write sau một `await` hỏi `_isCurrent(epoch)`. Không có gì bị
huỷ — transaction vẫn commit vì BR-25 muốn thế — thứ đổi là kết quả của nó có
được phép chạm tới màn hình hay không. `submitAnswer` vẫn **trả** receipt khi
stale: row đã được ghi, và người gọi tự quyết định vẽ gì.

**Tách file do guard 400 dòng:** `MatchBoardGridWidget` (hình học của bàn — bao
nhiêu hàng, cao bao nhiêu — tách khỏi cái quyết định một cú chạm *nghĩa là gì*),
`study_mode_bodies_widget.dart` và `recall_timer_pieces_widget.dart` (đều là
`part`, giữ nguyên library nên resolver vẫn là một nhánh exhaustive — AD-18).

**Bằng chứng:** `study_commit_before_feedback_test.dart` (11 test — với mỗi mode:
pending không vẽ gì, commit mới vẽ, `null` không vẽ và không giữ nhịp, chạm hai
lần chỉ một write); `match_board_feedback_test.dart` +5 (correct pending chưa
tick, correct refused ở lại bàn, wrong pending chưa đỏ, wrong commit mới đỏ và
row vẫn `pending`, cặp thứ hai không chen được vào lúc cặp đầu đang ghi — và ghép
được ngay sau khi commit, tức màu không khoá); `study_answer_lifecycle_test.dart`
+3 (leave giữa advance, leave giữa write, write hỏng sau leave). `PendingCommit`
thay cho `Completer<void>`: `Completer<void>` chỉ nói "xong", đúng cái hình dạng
đã cho phép board đọc một lần từ chối thành một lần thành công.

#### Summary rời controller: một query không bao giờ thuộc về một command

Guard 400 dòng là thứ ép phải nhìn lại, nhưng lý do tách được mới là điểm chính:
**đọc summary là một query**. Nó có ba call site trong controller — hết stage,
`leave()`, và nhánh failure — nên summary chỉ đúng bằng người cuối cùng nhớ đủ cả
ba; và `StudySessionState.summary` sống lâu hơn phiên, nên quên một call site là
hiện số của phiên trước dưới tiêu đề phiên mới.

Nay là `studySessionSummaryProvider(deckId)`: màn hình hỏi đúng lúc nhánh
`isFinished` cần, không ai phải nhớ gọi. Controller còn 380 dòng và guard sạch.

Hai convention của repo bắt được lỗi ngay khi viết:
`provider_convention_test.dart` từ chối family key không phải String/int (một cặp
named parameter là record key, so sánh bằng identity → cache một entry mỗi
rebuild) và bắt buộc `@Riverpod(retry: noAutomaticRetry)` cho async provider dưới
`features/*/presentation/`. Nên provider key bằng `deckId` và đọc session id với
scheduler type từ chính controller — không dựng bản sao thứ hai của hai dữ kiện
đã có chủ.

`study_session_summary_test.dart` giữ nguyên các claim cũ (một read chứ không
phải một read mỗi con số — AD-13; lapse action đúng theo scheduler) và thêm hai
cái chỉ có nghĩa sau khi tách: phiên đang chạy **không** đọc summary lần nào, và
một read hỏng là "phiên kết thúc không có số" chứ không phải một lỗi.
