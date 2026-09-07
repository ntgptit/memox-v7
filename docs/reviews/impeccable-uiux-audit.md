# Impeccable UI/UX audit — kết quả sau khi tự bác bỏ

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại một vòng audit UI/UX toàn repo mà **phần lớn finding của nó đã bị chính pass verify của nó bác bỏ**, giữ lại đúng phần sinh ra thông tin mới, và ghi lại lỗi phương pháp đã tạo ra phần còn lại |
| **Scope** | Ba thứ: (1) năm khiếm khuyết về **tính trung thực của bằng chứng review**, (2) đối chiếu trạng thái các defect còn mở của chuỗi audit A7–A20 tại `617b03f7`, (3) khoảng trống guard. Ngoài phạm vi: mọi thứ 30 claim ban đầu đòi hỏi mà verify không giữ lại — xem §4 |
| **Source of truth for** | Năm finding `EV-*` về bằng chứng review · trạng thái tại `617b03f7` của `A19-01`, `A19 F1/F2/F3`, `A9-02` · lỗi phương pháp §4 và bốn ca đo được của nó |
| **Depends on** | `document-conventions.md` · `design-system/v1-freeze.md` · `reviews/app-wide-screen-consistency.md` · `reviews/a8-navigation-chrome-audit.md` · `reviews/a9-modal-overlay-audit.md` · `reviews/a19-accessibility-audit.md` · `business-rules.md` |
| **Updated by task** | M100.56 |
| **Last updated** | 2026-09-07 |

---

## 0. Đọc mục này trước

Vòng audit này chạy 30 claim có trích dẫn `file:line` qua một pass verify đối kháng
hai lăng kính — một literalist đọc code hỏi *"có đúng chữ không"*, một warrant auditor
đi tìm guard, test hoặc quyết định đã ghi để **bác**. 61 agent, hai lăng kính độc lập
cho mỗi claim.

**Kết quả: 1 CONFIRMED · 24 IMPRECISE · 5 REFUTED.**

Một claim duy nhất qua được cả hai lăng kính nguyên vẹn. Nên tài liệu này **không phải
bản báo cáo audit**; nó là thứ còn lại sau khi bản báo cáo đó bị chính nó bác bỏ, cộng
với lý do vì sao — vì cái lý do đó có giá trị hơn phần lớn các finding.

`design-system/v1-freeze.md` §4 viết: *"Không mở A21 hay một audit khác. Một audit mới
không sinh ra thông tin."* **Vòng này là bằng chứng thực nghiệm cho câu đó**, không
phải ngoại lệ của nó. Bốn ca ở §4 cho thấy chính xác cơ chế: một reviewer đọc code và
comment mà không đọc `business-rules.md`, `docs/wireframes/` và `design_audit/` sẽ tái
phát hiện những quyết định đã chốt, và tin rằng mình vừa tìm ra chúng.

Phần **sinh ra thông tin mới** hẹp và nằm ở đúng một chỗ: **bằng chứng mà repo dùng để
tự review không hoàn toàn nói thật.** Đó là §2.

---

## 1. Phân lớp bằng chứng

| Nhãn | Nghĩa |
|---|---|
| `[V]` | **Đã nhìn tận mắt** — mở golden PNG đã commit ở 393×852 dp |
| `[S]` | **Bằng chứng source** — đã đọc đúng `file:line` được trích |
| `[I]` | **Suy luận**, cần thiết bị mới chốt. Luôn gắn nhãn |

Vòng chạy **không có emulator hay thiết bị**, và checkout Windows không được phép vẽ
golden (hợp đồng đóng băng #14). **Không claim nào ở đây được coi là đã verify trên
máy thật.**

---

## 2. `EV-*` — bằng chứng review không nói thật

Năm khiếm khuyết, tất cả nằm ở **tầng bằng chứng** chứ không ở app. Đây là phần duy
nhất của vòng này sống sót qua verify với nội dung còn nguyên.

### EV-01 · Golden của Guess vẽ một trạng thái production không bao giờ render — P1

`study_guess_states_demo_test.dart:119-140` mount `StudySessionFrameSectionWidget`
trực tiếp và **không truyền `hintOverride`, cũng không truyền `onResolved`**. Bốn
golden `guess_correct_{light,dark}.png` và `guess_wrong_{light,dark}.png` vì thế vẽ
`studyHintGuess` — *"Choose the right meaning"* — bên dưới một bàn **đã trả lời**.

`StudySessionScreen` không bao giờ render cặp đó: `_guessView` nối `onResolved`,
`_grade` bắn nó trong cùng khối đồng bộ đặt `_chosenCardId`, và `_hintOverrideFor` trả
`studyModeHintResolved(guess)` = *"Answer shown — the correct option is highlighted"*.
`didUpdateWidget` xoá lựa chọn trong cùng lần rebuild xoá key, nên **không có cả một
frame chuyển tiếp** nào trông như tấm ảnh đã commit. `[S]` `[V]`

Harness anh em làm đúng và **comment của nó gọi tên chính lỗi này**:
`study_recall_states_demo_test.dart:88-90` truyền `hintOverride`, kèm giải thích rằng
một bản render chỉ-thân sẽ bỏ mất dòng hint mà màn hình hoán đổi.

**Không gì bắt được.** Không guard rule nào phủ độ trung thực của demo harness, và
`study_session_frame_test.dart:147-166` assert đủ sáu hint gốc mà **chưa bao giờ chạm
`hintOverride`**.

### EV-02 · Ba bề mặt không có ảnh ở bất kỳ đâu — P2

Session **summary**, session **blocked** và session **error** không có golden **và**
không có scenario trong Widgetbook. `StudySessionScreen` có đăng ký catalogue, nhưng
`StudyCatalogScenario` không có entry finished/blocked/error, và companion MX-VIS-001
của nó chỉ dựng `self_assess`. Primitive của chúng được ghim bởi
`test/shared/widgets/goldens/empty_state_*` và `error_state_*` — thứ đó cố định *diện
mạo*, không cố định *composition*. `[S]`

Màn tổng kết là đỉnh cảm xúc của hành trình hằng ngày, và là màn duy nhất phân biệt
*"một phiên dừng lại không phải một phiên hoàn thành"*. Không ai nhìn được nó.

### EV-03 · Một tài liệu review đang ghi công sai cho một cặp golden — P2

`ProgressDeckScreen` ở `/progress/:deckId` **không có golden**: mọi call site của
`progressShellWith` đều lấy mặc định `location: RoutePaths.progress`, nên
`progress_deck_{light,dark}.png` thật ra vẽ **cấp library** composed bên trong
`ProgressScreen`.

`docs/reviews/app-wide-screen-consistency.md` §2 hàng 17 **ghi công cặp ảnh đó cho cấp
drill-down mà nó không hề vẽ**. `[S]`

Cấp đó **có** trong catalogue (`widgetbook/lib/screens/progress_deck_screen_use_case.dart`),
nên đây là khiếm khuyết của trang gallery và của dòng ghi công, không phải của phạm vi
Widgetbook.

### EV-04 · Tám hàng gallery dựng không có navigation shell — P2

`feature_screens_demo_test.dart` mount `ReviewApp(home: <Screen>)` không router cho:
`study_home`, `progress_overview`, `settings`, `settings_save_failed`,
`reminder_settings`, `reminder_settings_hc`, `library_search`, `trash`. Cả tám màn này
trong production đều route **bên trong** một `StatefulShellBranch`, nên thanh bốn đích
là một phần của màn người dùng thật sự thấy. `[S]`

Hàng thứ chín cùng file — `progress_deck` — là ngoại lệ: nó đi qua `progressShellWith`
→ `createAppRouter` → `Router.withConfig`, và PNG của nó **có** mang thanh đó. Chính
`app-wide-screen-consistency.md:883` đã đo thanh ấy ở `Rect.fromLTRB(0.0, 772.0, 393.0,
852.0)` trên đúng fixture này.

`study_options_demo_test.dart:31-36` ghi sẵn vì sao không được làm thế: *"a bare pump
loses the shell's navigation bar and its safe area, and those are exactly the parts a
layout review has to score."* Bài học được áp ở một file và không áp ở file anh em.

### EV-05 · 52 ảnh đúng bề mặt, không hàng nào trên gallery — P3

Manifest `SCREENS` có **65 hàng**; `test/demo/goldens/` có **164 PNG**. Hai số không so
trực tiếp được: mỗi hàng nhúng một cặp light+dark, nên 65 hàng tiêu thụ **103** PNG.
Trong 61 PNG còn lại, **9** là render cố ý ngoài bề mặt (320×568, 320×1400, 412×915) —
quyết định ghi ở `CLAUDE.md`, ở docstring của module và ở `wbs.md` M99.60, và được
cưỡng chế bằng `_check_surface`, thứ exit non-zero và gọi tên file cùng cỡ dp của nó.

Còn lại **52 PNG chụp đúng 393×852 dp mà không có hàng nào** — phần lớn là trạng thái
của phiên học. Chúng đã được commit, đã đúng bề mặt, và trang gallery không hiện.
`[S]`

---

## 3. Đối chiếu chuỗi A7–A20 tại `617b03f7`

Vòng này ban đầu **không** đối chiếu chuỗi A, và đó là một nửa của lỗi phương pháp ở
§4. Đối chiếu đã chạy đủ. Kết quả có giá trị độc lập với phần còn lại: **năm defect
còn mở của chuỗi A nay đã đóng thật**, mỗi cái có quyết định sửa ghi tại chỗ.

| ID | Sev gốc | Trạng thái tại `617b03f7` | Bằng chứng |
|---|---|---|---|
| `A19-01` | **P0** | **Đã đóng.** `browse` có `_pointerRow` với hai `MxIconButton` — `navigate_before` / `navigate_next`, mỗi cái có `semanticLabel` **và** `tooltip`. Nút lùi ẩn bằng `Visibility(maintainSize: true)` ở đầu trail nên nút tiến không nhảy chỗ | `study_swipe_deck_widget.dart:242-277` `[S]` |
| `A19 F1` | P1 | **Đã đóng.** `MxSearchField.semanticLabel` nay **bắt buộc**, gắn qua `Semantics(label:)`; `hintText` bị `ExcludeSemantics` kèm ghi chú "Painted, not announced" | `mx_search_field.dart:66-67`, `:85`, `:190-205` `[S]` |
| `A19 F2` | P1 | **Đã đóng.** Hộp cố định đổi thành `BoxConstraints(minHeight: AppSizing.touchTarget)`; doc ghi đúng lỗi cũ — một *sàn* bị dùng thành *trần* | `mx_search_field.dart:50-56`, `:164` `[S]` |
| `A19 F3` | P1 | **Đã đóng.** `focusedErrorBorder` nay dày hơn `errorBorder` (`AppStroke.focus`): dưới error thì *hue* đã bị chiếm, nên stroke là kênh duy nhất còn lại để nói "và nó đang focus" | `app_input_theme.dart:15-25`, `:63-64` `[S]` |
| `A9-02` | P1 | **Đã đóng.** `showMxSheet` là **lối duy nhất** một bottom sheet mở ra và nó set `useSafeArea: true`; trong `lib/` chỉ còn **một** lời gọi `showModalBottomSheet` | `mx_sheet.dart:9-41` `[S]` |

**Bốn quyết định của chủ dự án vẫn còn mở**, và ghi lại đây vì vòng này đã đâm vào cả
bốn mà không biết: `A8 D4` ⇄ `A8 P2-08` (long-press trên dải path không được đọc lên —
và `a20-1` P3-10 đã tiêu phương án (a) bằng cách gỡ `deckPathAncestorsHint`); `A8 P3-19`
(session và 404 không tự phát `SystemUiOverlayStyle`); `A8 D3` (tablet / foldable có
phải bề mặt được hỗ trợ không); `A18 §10 / G5` (landscape *được hỗ trợ* hay chỉ *được
phép*).

---

## 4. Lỗi phương pháp — phần đáng giá nhất của vòng này

**Bốn ca, mỗi ca là một finding tự tin bị bác bằng một tài liệu reviewer chưa đọc.**

| Finding bị bác | Thứ đã trả lời nó từ trước |
|---|---|
| *"Hai từ vựng cho workload, không ai sở hữu"* — finding hệ thống trung tâm của bản nháp | **`business-rules.md`, Status `frozen for MVP`, bắt buộc cả hai bên trong cùng một file.** `BR-162` quy định chip chỉ hiện khi count > 0 cho deck tile (quyết định của chủ dự án 2026-08-20); `BR-201` quy định Study Home **MUST** luôn hiện cả ba số kể cả bằng 0, mỗi số **MUST** có icon và nhãn chữ riêng, và màu **MUST NOT** là tín hiệu duy nhất. **`BR-201` trích dẫn thẳng `BR-162` ở cột related** — nó được viết khi đã nhìn thấy luật kia. Hai bề mặt khác nhau vì Study Home **xếp hạng deck theo đúng ba số đó** và giữ deck workload-0 ở cuối, nên số 0 là cơ sở nhìn thấy được của thứ tự; deck list không xếp hạng theo workload. Cả hai widget đang thực thi trung thành BR của mình |
| *"Thanh filter tràn ở mọi width — defect"* | **`docs/wireframes/m4-14-tag-management.md:28`** (T3a, Status `active`, 2026-08-14) là quyết định đã cân giá, và nó gọi tên đúng cái giá đã chọn: *"ở 393dp `Flagged` cắt giữa chữ"*, kèm đo lại sau khi pin ở 320dp. Hợp đồng G10 và `tag_catalog_alignment_test.dart:236-270` ghim kết quả ở 320 · 390 · 412dp |
| *"Progress chồng hai phạm vi — selector mơ hồ"* | **Divergence X9** ở `m99-23-progress-overview.md:185` ghi quyết định M99.24 của chủ dự án đổi tên biểu đồ thành "Daily activity" **đúng vì lý do này**; **X10** chuyển selector khỏi `subheader` xuống `PinnedHeaderSliver` **đặt sau** overview để nó không đọc thành đang điều khiển overview, và `progress_composition_test.dart:151-185` ghim đúng thứ tự ấy |
| *"Test tên clears-the-touch-floor không thể đỏ"* | **`design_audit/layout_review/README.md:39`** nêu thành **quy tắc phương pháp** rằng `meetsGuideline` đọc semantics rect nên không phải bằng chứng về vùng chạm — đó là lý do layout probe hit-test thay vì dùng nó. **`deck_list_level.md:143-149` (F2)** là phép đo của chính probe đó trên đúng dải này — 265×32 xác nhận bằng hit-test — và **được chấp nhận như ngoại lệ có ghi**. Còn assert của constructor không "cho phép" sub-48: nó là **closure của A20.1 P3-13**, thứ siết một tình trạng trước đó chỉ có quy ước giữ |

**Cơ chế chung:** cả bốn lần, reviewer đọc code và doc comment tại chỗ, rồi kết luận
"không ai sở hữu chuyện này". Ba nguồn trả lời đều nằm ngoài code:
`docs/business-rules.md`, `docs/wireframes/` và `design_audit/layout_review/`. Thứ tư
là sổ nợ trong `wbs.md` — `P1-C` (Progress quét toàn bảng) đã nằm ở `wbs.md:9766-9771`
như nợ hoãn thuộc M99.23, và `BR-199` **yêu cầu** stream chạy lại trên mỗi lượt trả
lời, nên hành vi ấy là hợp đồng chứ không phải khiếm khuyết.

`CLAUDE.md` xếp `business-rules.md` ở vị trí #5 của thứ tự đọc bắt buộc. Vòng này bỏ
qua nó và trả giá bằng finding trung tâm.

**Hệ quả cho vòng audit sau:** một finding chỉ được coi là mới sau khi đã tra **bốn**
chỗ — `business-rules.md`, `docs/wireframes/`, `design_audit/` và mục nợ của `wbs.md` —
chứ không phải sau khi đọc code và thấy comment không nhắc tới nó.

---

## 5. Khoảng trống guard — claim còn giữ, có sửa số

Ruleset `memox-v7` resolve **mười lăm** file rule, không phải mười: mười file của
chính nó, cộng `registries/common/*.yaml` và
`registries/languages/dart/{dart,flutter}-rules.yaml`, bật qua `rule_sets: common:
true` và `languages: [dart, flutter]`. `[S]`

Qua cả mười lăm: **không có rule accessibility, không có rule performance, và không có
rule nào đo orientation, window size, edge-to-edge hay diện mạo thanh hệ thống.**

Một điều kiện: lát cắt inset/platform-chrome được giữ **về mặt cấu trúc** chứ không
bằng phép đo — `memox_v7.design_system.no_raw_sheet_route` và các rule cùng họ buộc mọi
sheet đi qua một lối duy nhất, và chính điều đó là thứ đã đóng `A9-02`. Nên khoảng
trống là ở **đo lường**, không phải ở vô chính phủ.

Đây cũng là chỗ `v1-freeze.md` §4 đã chỉ sẵn: chỗ bảng enforcement trống thì việc phải
làm là **thêm một guard**, không phải viết thêm một báo cáo.

---

## 6. Việc nên làm, theo thứ tự

Không triển khai ở task này.

| # | Việc | Finding |
|---|---|---|
| 1 | Truyền `hintOverride` (và `onResolved`) ở harness guess, vẽ lại bốn golden, rồi thêm assertion buộc mọi harness dựng session frame cho một mode **có** `studyModeHintResolved` phải cấp nó | `EV-01` |
| 2 | Thêm golden **và** scenario catalogue cho ba mặt session chưa từng được vẽ; thêm golden cho cấp drill-down của Progress; sửa dòng ghi công sai ở `app-wide-screen-consistency.md` §2 hàng 17 | `EV-02`, `EV-03` |
| 3 | Cho tám hàng kia đi qua router như `progress_deck` đã đi, hoặc đánh dấu trên trang là render không shell | `EV-04` |
| 4 | Quyết 52 PNG đúng bề mặt kia: lên gallery, hay ghi lý do vắng mặt | `EV-05` |
| 5 | Thêm rule guard cho ba vùng ở §5 — bắt đầu bằng vùng rẻ nhất đo được | §5 |

Lệnh Impeccable phù hợp cho 1–4 là `/impeccable harden`.

---

## 7. Cái vòng này KHÔNG kết luận được

Ghi lại để không ai đọc sự vắng mặt thành sự trong sạch:

- **Không chạy trên thiết bị.** Landscape, edge-to-edge và hành vi TalkBack thật đều
  chưa được kiểm; `A8 D3`, `A8 P3-19` và `A18 G5` vẫn là ba câu hỏi mở của chủ dự án.
- **Không vẽ lại golden nào**, và không thể — hợp đồng đóng băng #14.
- **Không phán được về mỹ thuật.** 24 claim trở về IMPRECISE, nên mọi điểm số mà bản
  nháp từng đưa ra — native score, thang UX 12 chiều — **đã bị rút**. Chúng dựa trên
  một tập finding không đứng vững, và một con số dựng trên nền đó tệ hơn không có số.
- **Không mở lại `SC-*` nào**, và không đề nghị sửa hợp đồng đóng băng nào.
