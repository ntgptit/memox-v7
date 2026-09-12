# Design System V1 — FROZEN

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi nhận Design System V1 là baseline ổn định của repo: hợp đồng nào đóng băng, bằng chứng nào chứng minh, và điều kiện nào mở lại |
| **Scope** | Foundation, theme mapping, shared primitive contract, a11y floor, golden authoring policy. Ngoài phạm vi: **composition của từng màn hình nghiệp vụ** (không đóng băng), giá trị token cụ thể (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Freeze record của V1 · danh sách hợp đồng đóng băng · reopen trigger · bản đồ enforcement cho từng hợp đồng · ràng buộc lên task feature |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-15, AD-23) · `design-system/theme-architecture.md` · `reviews/a20-1-design-system-reconciliation.md` (bằng chứng lịch sử) |
| **Updated by task** | M100.73 |
| **Last updated** | 2026-09-12 |

---

## 1. Freeze record

| | |
|---|---|
| **FREEZE_SHA** | **`e516af4b`** — commit squash của #466 trên `main`. Đây là SHA có thật và `git`-resolve được; nhánh bị squash nên SHA trước merge (`b4599c35`) không nằm trên `main` và không dùng làm mốc được. Tree của `e516af4b` **trùng byte** với head của PR mà cả bảy check của CI đã chạy qua, kể cả `goldens (linux)` |
| **START_SHA** | `9443c49c` (= `origin/main` lúc bắt đầu) |
| **Flutter** | 3.44.8 · Dart 3.12.2 (khớp `.fvmrc`, khớp runner của CI) |
| **Architecture (A20.1 §23)** | **30 / 30** |
| **Verification (A20.1 §24)** | **22 / 22** |
| **Golden count** | **325 / 325** xanh trên Linux (WSL Ubuntu 24.04, `TZ=UTC`), cây làm việc sạch sau khi chạy — so sánh, không vẽ lại |
| **Guard** | 84 rule, 0 violation; 195 pytest probe xanh |
| **Host suite** | `TZ=UTC flutter test --exclude-tags golden` — **4772 passed**, exit 0 |
| **Android integration** | **8 / 8** trên `emulator-5554`, `--flavor development`, exit 0 |
| **Widgetbook** | catalog smoke xanh; `flutter analyze` repo-wide **No issues found** |

Tiêu chí duy nhất còn `NOT RUN` ở lần đóng trước (§24 #8 — bộ integration trên
thiết bị) đã được chạy thật ở task này. Không có mục nào được tính PASS mà không
chạy.

---

## 2. Hợp đồng đóng băng

Mỗi dòng dưới đây là một hợp đồng của V1. Cột **Enforcement** là thứ làm nó đỏ
khi bị phá — không phải prose, mà là một rule hoặc một test chạy trong CI.

| # | Hợp đồng | Enforcement |
|---|---|---|
| 1 | 45 role của `ColorScheme` là danh tính chuẩn, hai chiều allowlist | `theme_coverage_test`, `m3_role_contract_test` |
| 2 | Retune trong cùng role; **không** thay role ngữ nghĩa bằng role khác | guard `color_scheme_arguments_are_m3_roles`, `color_scheme_reads_are_m3_roles`, `no_raw_color` |
| 3 | Mapping `ThemeData` / component theme | `app_unrendered_component_themes_test`, `theme_coverage_test` |
| 4 | Thang typography và hợp đồng weight của variable font | `app_typography_test`; guard `no_bare_font_weight`, `no_raw_text_style`; `app_bold_text_components_test` (registry theo **component theme + slot**), `app_media_query_wiring_test` |
| 5 | Foundation: spacing / radius / sizing / stroke / elevation | guard `no_raw_spacing_literal`, `no_raw_border_radius`, `no_raw_stroke_width`; `design_tokens_test`, `feature_geometry_grid_test`, `app_stroke_test`, `css_scale_parity_test` |
| 6 | Public contract của shared primitive | `shared_api_closure_test`, `mx_stress_test` |
| 7 | Target tương tác ≥ 48dp | bốn `*_accessibility_sweep_test` (`meetsGuideline`) |
| 8 | Ripple / state behaviour trên Android | `component_depth_and_state_test`, `app_selection_disabled_states_test` |
| 9 | High contrast | `high_contrast_figures_test`; 4 golden HC; `widgetbook_coverage_test` (4 theme mode) |
| 10 | #435 — Card không glow, hợp đồng depth | `mx_card_mobile_test` (dark: đúng **một** shadow, `outlineVariant`, `blurRadius` 0), `mx_card_test` ("is the no-shadow card"), `component_depth_and_state_test` |
| 11 | Chrome contract của `MxContentShell` | `mx_content_shell_chrome_test`, `mx_content_shell_bar_test`, `study_session_chrome_test` |
| 12 | Chính sách restyle text ngữ nghĩa | guard `no_text_restyle` (file mode, 5 pattern), `text_restyle_alias_test` |
| 13 | Chính sách sở hữu raw Material | guard `no_raw_button`, `no_raw_widget`, `no_raw_screen_chrome`, `no_raw_sheet_route`, `no_raw_loading_indicator`, `no_raw_choice_chip`; `raw_progress_exclusions_test` |
| 14 | Golden chỉ được author trên Linux | policy ở `dart_test.yaml`; job `goldens (linux)` của `ci.yml` — một PNG vẽ trên Windows làm job đỏ |

Mười bốn dòng trên là **hợp đồng đóng băng** của V1. Cụm từ "hợp đồng đóng
băng" ở tài liệu này luôn có nghĩa là *cả mười bốn dòng*, không phải riêng
những dòng có guard: chín dòng được giữ bằng test, và một test cũng là hợp
đồng.

**Guard rule ở các dòng 2, 4, 5, 12 và 13 nay cũng được canh.**
`code-verification-guard-v2/tests/test_memox_v7_frozen_contract_enforcement.py`
đọc mười lăm rule đó **đúng như guard resolve chúng** — `scopes` đã bung,
`exclude` cấp rule đã gộp, `enabled` đã tính — rồi đòi mỗi rule còn phủ một file
presentation của **mọi** feature trong `lib/features/`. Thêm `exclude`, đặt
`enabled: false`, hay xoá hẳn rule đều làm nó đỏ. Ghi ở đây một lần thay vì lặp
vào năm ô của bảng, theo `document-conventions.md` §5.

**Không đóng băng:** composition của màn hình nghiệp vụ. Một task feature **MAY**
xếp đặt, thêm, bớt section, và **MAY** compose shared widget rồi layout chúng —
primitive của framework và của layout vẫn dùng bình thường, và **MUST NOT** dựng
wrapper chỉ để có wrapper.

---

## 3. Điều kiện mở lại

V1 **MUST NOT** được mở lại, trừ bằng **một task design-system tường minh**; và
task đó **MUST** được kích hoạt bởi ít nhất một trong năm điều kiện sau:

1. Nâng Flutter SDK làm đổi hành vi Material.
2. Chủ đích thiết kế lại palette / theme.
3. Thêm một họ shared primitive / component mới.
4. Thay đổi spec hoặc yêu cầu accessibility buộc hợp đồng phải đổi.
5. Một defect production được chứng minh nằm trong một hợp đồng đã đóng băng.
6. **Chủ dự án chỉ định một thay đổi hình thức cho component đã có**, kèm tham
   chiếu thị giác cụ thể (mockup, ảnh chụp, bản dựng) — xem §3a.

Không điều kiện nào trong sáu điều kiện trên đúng, thì hợp đồng ở §2 **MUST NOT**
bị sửa.

**Một task feature MUST NOT sửa bất kỳ hợp đồng đóng băng nào ở §2** — cả mười
bốn dòng. Nếu công việc đòi hỏi một thay đổi như vậy, task feature **MUST** dừng
lại và mở một task design-system riêng; nó **MUST NOT** tự sửa rồi ghi chú lại,
và **MUST NOT** merge một phần thay đổi để "mở đường".

**Sửa thứ đang canh hợp đồng cũng là sửa hợp đồng.** Một task feature **MUST
NOT** nới lỏng, thêm exclude, hay xoá rule guard và test ở cột Enforcement của
§2 để code của nó đi qua. Đây là lối vòng thật chứ không phải giả định, và nó
**từng mở**: guard không đỏ khi chính nó bị sửa, nên tới trước M100.48, thêm một
dòng `exclude` vào một rule ở §2 vẫn để guard, probe và CI xanh cùng lúc — đo
được, không phải suy đoán. Mục 2 ở trên nói cái nay đóng đường đó cho năm dòng
có guard canh.

Chín dòng còn lại vẫn chỉ có test giữ, và test thì nằm trong repo và sửa được —
kể cả chính probe vừa nói. Vòng này phải dừng ở đâu đó, và chỗ nó dừng là câu
**MUST NOT** mở đầu đoạn này, không phải ở một lớp canh nữa.

Ba câu trên có từ khoá là **cố ý**. Theo `document-conventions.md` §3, câu không
mang MUST/SHOULD/MAY là *giải thích, không phải ràng buộc* — bản đầu của tài liệu
này viết điều kiện mở lại thành prose trần, nên nó chưa từng ràng buộc ai.

---

## 3a. Reopen record — M100.73 (2026-09-10)

**Đây là lần mở lại đầu tiên của V1, và điều kiện số 6 được thêm trong chính
lần này.** Ghi nguyên nhân ở đây thay vì để lần sau tự suy ra.

**Chuyện đã xảy ra.** Chủ dự án đưa một mockup HTML của màn Library kèm ảnh chụp
bản dựng, yêu cầu bố cục theo đó và giữ nguyên token với chức năng. Đối chiếu
xong, hai trong bốn chỗ lệch không làm được ở tầng feature:

- nút search / overflow trên bar là **hình tròn có viền**, trong khi `MxIconButton`
  chỉ có một hình dạng — và variant filled của nó đã bị gỡ **hai lần** trước đây;
- nút Study trên hàng deck là **pill tông nhạt**, trong khi `MxActionButtonVariant`
  có đúng ba giá trị và không giá trị nào là tonal: `primary` là fill đặc,
  `secondary` là outline.

**Vì sao phải thêm điều kiện thứ sáu.** Năm điều kiện cũ không cái nào đúng. Đây
không phải nâng SDK (1), không phải thiết kế lại palette hay theme (2) — palette
không đổi một giá trị nào; không phải thêm **họ** primitive mới (3) — cả hai đều
là variant của primitive đã có; không phải yêu cầu accessibility (4); và không
phải defect (5) — cái đang có chạy đúng, chỉ là không phải hình thức chủ dự án
muốn.

Nói cách khác: **tài liệu này chưa từng lường trước việc chủ dự án chủ động đổi
hình thức của component đã có.** Nó lường trước SDK, palette, họ mới, a11y và
defect — tất cả đều là sức ép từ bên ngoài đẩy vào. Một chỉ định thiết kế đi từ
người sở hữu sản phẩm ra là hướng còn lại, và nó không có cửa nào. Bịt lỗ hổng
đó bằng một điều kiện tường minh tốt hơn là nong một trong năm điều kiện kia cho
vừa, vì cách thứ hai làm mọi điều kiện mất nghĩa.

**Cái gì đã đổi, và cái gì không.**

| Hợp đồng §2 | Đổi | Không đổi |
|---|---|---|
| 6 — public contract của shared primitive | `MxActionButtonVariant` thêm `tonal`; `MxIconButton` thêm trục `MxIconButtonShape` | `shared_api_closure_test` không phải nới: allowlist của nó vốn nhận **enum do chính component khai báo**, nên cả hai giá trị mới đi qua mà không sửa test |
| 1, 2 — role identity và role ngữ nghĩa | không | `tonal` đọc `secondaryContainer` / `onSecondaryContainer`, đúng cặp `_FilledButtonDefaultsM3` cấp cho `FilledButton.tonal`. Không role nào bị thay bằng role khác, không hex nào mới |
| 5 — foundation | **có, ở M100.76**: `AppSizing.statusDot = 8` | Ở M100.73 thì không: viền tròn dùng `AppRadius.pill` đã có; độ dày là default của `BorderSide`, và `mx_tonal_and_outlined_test.dart` ghim sự trùng khớp giữa nó với `AppStroke.hairline` — đã kiểm bằng tiêm lỗi (dời token lên 1.5 thì test đỏ). Xem §3b |
| 8 — ripple / state | không | Cả hai variant đi qua `buildFilledStyle` / resolver dùng chung, không qua `styleFrom`. Đây đúng là điều `MxIconButton` đã tự ghi lại sau hai lần gỡ variant filled: *"build its colours from the shared resolvers, not from `styleFrom`"* |
| 11 — chrome của `MxContentShell` | không | Shell không bị chạm. Nút bar là widget do feature truyền vào `actions:`, nên đổi hình dạng của chúng là việc của feature |

**Ràng buộc lên task feature không đổi.** M100.73 chỉ thêm variant vào primitive
và **MUST NOT** dùng chúng ở đâu cả; task feature đi sau (M100.74) là nơi chúng
có caller đầu tiên. Tách như vậy vì §3 cấm "merge một phần thay đổi để mở đường"
— một PR vừa nới primitive vừa dùng nó là đúng thứ câu đó nói tới.

---

## 3b. Reopen record — M100.76 (2026-09-10)

**Cùng brief với §3a, cùng điều kiện số 6, và nó tồn tại vì một lối tắt đã bị
CI bắt.**

Chấm trạng thái ở header Library cần đường kính 8. M100.75 viết
`width: AppSpacing.sm` kèm một comment lập luận rằng thêm token dimension mới là
mở lại hợp đồng §2 dòng 5 và "một cái chấm không đáng". Lập luận đó **sai**, và
repo đã trả lời từ trước: `spacing_is_a_gap_test` cấm đúng cặp
`width:`/`height:` mang token `AppSpacing`, với lý do viết sẵn trong doc của nó
— *"a spacing token names a gap on one axis... dimensions live in `AppSizing` /
`AppIconSize`"*. Test đó đỏ ở shard 4 của CI.

**Bài học ghi lại, vì nó là loại sai dễ lặp:** né một hợp đồng đóng băng bằng
cách mượn token của trục khác không phải là tôn trọng hợp đồng, nó là vi phạm
một hợp đồng khác lặng lẽ hơn. Đường đúng là mở task design-system — điều kiện
số 6 đã có sẵn cho brief này.

`AppSizing.statusDot = 8` là **giá trị duy nhất được thêm**. Nó nằm trên lưới
4dp như mọi giá trị khác trong file (`app_sizing_test` giữ), và
`app_sizing_test` có thêm một khẳng định nói rõ nó **không** phải control: nó
nhỏ hơn `controlDense`, nên sàn 48dp không áp — và nếu ai đó làm nó bấm được mà
quên chuyển nó ra khỏi nhóm này thì test đỏ.

---

## 3c. Reopen record — M100.85 (2026-09-12)

**Lần mở lại thứ ba, cùng điều kiện số 6, và lần này hợp đồng bị chạm là một
guard AST chặn cứng — không phải một token bị mượn sai trục như §3b.**

**Chuyện đã xảy ra.** Chủ dự án đưa một bản đặc tả component Chip (bảng
dimension + state matrix, dẫn từ MemoX HTML design kit) và đặt tên role trực
tiếp: `selected — primaryContainer fill, onPrimaryContainer label`. Đối chiếu
với `m3_role_bindings.dart` thì phát hiện `ChoiceChip._restingFill` và
`._labelColorFor` đang ghim `secondaryContainer` / `onSecondaryContainer`, với
`refuses: ['primaryContainer']` / `['onPrimaryContainer']` tường minh — lý do
ghi trong chính binding: đây là default canonical của `_ChoiceChipDefaultsM3`.
`app_chip_theme.dart` còn nói thêm: `secondaryContainer` được chọn để "đang
active" trông giống hệt `NavigationBar` indicator và `SegmentedButton`.

**Đúng điều kiện thứ sáu, không phải điều kiện nào khác.** Không phải nâng SDK
(1); không phải thiết kế lại palette (2) — không hex nào đổi; không phải thêm
họ primitive mới (3) — `MxPillButton`/`ChoiceChip` đã có; không phải yêu cầu
accessibility (4); không phải defect (5) — hành vi cũ chạy đúng theo đúng M3.
Đây là chủ dự án chủ động chỉ định hình thức mới cho một component đã có, kèm
tham chiếu cụ thể (bản đặc tả Chip) — đúng khuôn điều kiện 6 đã ghi từ §3a.

**Quyết định được hỏi thẳng, không tự suy.** Ba hướng được đặt ra: giữ
`secondaryContainer` (coi chữ trong spec là mô tả, không phải role Flutter bắt
buộc); đổi `primaryContainer` chỉ cho Chip; hoặc đổi cả ba component
(`ChoiceChip` + `SegmentedButton` + `NavigationBar` indicator) để giữ "đang
active" đồng nhất toàn app. Chủ dự án chọn **chỉ Chip**. Hệ quả được chấp nhận
tường minh, không phải bỏ sót: từ M100.85, Chip đọc `primaryContainer` trong
khi tab đang chọn và segment đang chọn vẫn đọc `secondaryContainer` — ba
component "đang active" không còn cùng một ngôn ngữ màu. `SegmentedButton` và
`NavigationBar` **không đổi** trong task này; nếu sau này chúng cần đồng bộ lại
với Chip, đó là một task design-system riêng, không phải phần mở rộng ngầm của
M100.85.

**Cái gì đã đổi, và cái gì không.**

| Hợp đồng §2 | Đổi | Không đổi |
|---|---|---|
| 2 — role identity, role ngữ nghĩa | có: `ChoiceChip` selected fill/label rời `secondaryContainer`/`onSecondaryContainer` sang `primaryContainer`/`onPrimaryContainer`. `m3_role_bindings.dart` đảo `requires`/`refuses`; `m3_role_contract_test.dart` và `m3_combined_state_test.dart` ghim giá trị mới | `SegmentedButton`, `NavigationBar` indicator/label, mọi role khác của Chip (unselected fill vẫn `surfaceContainerLow`, side/disabled/elevation không đổi) |
| 1 — 45 role là danh tính chuẩn | không | không role nào bị thêm hay bớt khỏi allowlist; `primaryContainer`/`onPrimaryContainer` đã có sẵn trong 45 role |
| 3 — mapping ThemeData/component theme | có, ở đúng slot đang đổi | `docs/design-system/tokyo-component-mapping.md` selection/ cập nhật hai dòng (selected fill, selected label) |
| 5 — foundation sizing | có, nhưng không thêm token: icon glyph của Chip đổi từ `AppIconSize.sm` (16) sang `AppIconSize.md` (24) — cả hai đã tồn tại | không token `AppSizing`/`AppSpacing`/`AppRadius` nào mới; `MxPillButton`'s `SizedBox.square` đổi theo cùng bước để tick và icon vẫn khớp khung |
| 6 — public contract của shared primitive | không | `MxPillButton`'s API (`label`/`isSelected`/`onPressed`/`icon`/`semanticLabel`) không đổi; đây là retune bên trong theme, không phải một tham số mới |
| 8 — ripple/state trên Android | không | Cơ chế "một mechanism mỗi state" (hover = fill tint, press = ripple SDK, focus = `MxFocusRing`) không bị chạm — chỉ giá trị resting/selected fill đổi |

**Ràng buộc lên task feature không đổi.** Không có feature nào được sửa
`SegmentedButton` hay `NavigationBar` để "theo kịp" Chip trong lúc chờ quyết
định đồng bộ — đó vẫn là §3 cấm "mở đường".

---

## 4. Vì sao A20.1 không còn là backlog

`docs/reviews/a20-1-design-system-reconciliation.md` từ đây là **bằng chứng đóng
lịch sử**, không phải danh sách việc phải làm. Cả 51 finding đã đóng (§27), pass
sửa lỗi đã đóng lại ba cái ngắn hợp đồng (§27.1), và tiêu chí cuối cùng còn thiếu
bằng chứng — bộ integration trên thiết bị — đã chạy ở task này.

**Không mở A21 hay một audit khác.** Một audit mới không sinh ra thông tin: thứ
làm V1 giữ được là bảng enforcement ở §2, và chỗ nào bảng đó trống thì việc phải
làm là thêm một guard, không phải viết thêm một báo cáo.
