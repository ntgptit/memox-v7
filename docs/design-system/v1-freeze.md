# Design System V1 — baseline lịch sử

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi nhận Design System V1 như một **baseline lịch sử**: nó đã chốt những gì, bằng chứng nào đo được ở thời điểm đó, và hôm nay guard rule / test nào đang canh từng hợp đồng |
| **Scope** | Foundation, theme mapping, shared primitive contract, a11y floor, golden authoring policy. Ngoài phạm vi: composition của từng màn hình nghiệp vụ, giá trị token cụ thể (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Bản ghi V1 · bản đồ enforcement cho từng hợp đồng · lịch sử reopen và lần mở khoá |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-15, AD-23) · `design-system/theme-architecture.md` · `reviews/a20-1-design-system-reconciliation.md` (bằng chứng lịch sử) |
| **Updated by task** | unlock-design-system-v1 |
| **Last updated** | 2026-09-17 |

> **V1 KHÔNG còn là hợp đồng bất biến.** Tài liệu này từng đóng băng mười bốn
> hợp đồng và đòi một trong sáu "reopen trigger" trước khi ai được sửa chúng.
> Chủ dự án đã gỡ ràng buộc đó — xem [§3](#3-v1-đã-được-mở-khoá). Một task
> design-system **MAY** đổi bất kỳ token, theme mapping hay component contract
> nào ở đây mà không cần xin phép và không cần viện dẫn điều kiện nào.
>
> Toàn bộ nội dung bên dưới được **giữ nguyên làm lịch sử**: số đo ở §1 là số đo
> của lần đóng V1, không phải cam kết cho hôm nay; bảng ở §2 vẫn hữu ích vì nó
> chỉ đúng **cái gì sẽ đỏ** khi một hợp đồng đổi.

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

## 2. Hợp đồng của V1, và thứ đang canh chúng

Mỗi dòng dưới đây là một hợp đồng V1 đã chốt. Cột **Enforcement** là thứ làm nó
đỏ khi bị phá — không phải prose, mà là một rule hoặc một test chạy trong CI.

**Bảng này nay là bản đồ, không phải rào chắn.** Nó không còn nói "MUST NOT đổi";
nó nói **đổi dòng này thì cái gì sẽ đỏ**. Một task design-system đổi một hợp đồng
ở đây đọc cột Enforcement để biết phải cập nhật những gì trong cùng commit, rồi
cập nhật cả bảng.

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

Mười bốn dòng trên là các hợp đồng V1 đã chốt — chín dòng được giữ bằng test,
năm dòng (2, 4, 5, 12, 13) có thêm guard rule quét `lib/features/`.

**Lớp canh thứ hai đã được gỡ cùng lần mở khoá.** Trước đây
`code-verification-guard-v2/tests/test_memox_v7_frozen_contract_enforcement.py`
đọc mười lăm guard rule của năm dòng đó **đúng như guard resolve chúng** —
`scopes` đã bung, `exclude` cấp rule đã gộp, `enabled` đã tính — rồi đòi mỗi rule
còn phủ một file presentation của **mọi** feature trong `lib/features/`. Nó tồn
tại để không ai tắt được một hợp đồng đóng băng bằng cách sửa chính thứ đang canh
nó. Khi V1 không còn bất biến thì đó đúng là thứ một task design-system **cần**
làm được, nên probe đã bị xoá (§3). Guard rule thì **vẫn nguyên và vẫn chạy**:
cái mất đi là lệnh cấm sửa chúng, không phải chúng.

**Chưa bao giờ thuộc V1:** composition của màn hình nghiệp vụ. Một task feature **MAY**
xếp đặt, thêm, bớt section, và **MAY** compose shared widget rồi layout chúng —
primitive của framework và của layout vẫn dùng bình thường, và **MUST NOT** dựng
wrapper chỉ để có wrapper.

---

## 3. V1 đã được mở khoá

**Chủ dự án gỡ trạng thái bất biến của V1 (2026-09-17).** Từ đây:

- Một task design-system **MAY** đổi bất kỳ hợp đồng nào ở §2 — palette,
  ColorScheme, mapping `ThemeData`, typography, spacing / radius / sizing /
  stroke / elevation, public API của shared primitive, hợp đồng thị giác của
  component. Không cần viện dẫn điều kiện nào, không cần xin mở lại.
- Task đó **MUST** cập nhật guard rule và test ở cột Enforcement của §2 trong
  **cùng commit** với thay đổi — không phải vì V1 cấm, mà vì một test ghim giá
  trị cũ sẽ đỏ, và để nó đỏ rồi sửa sau là để CI nói dối trong khoảng giữa.
- Task đó **SHOULD** ghi lại quyết định ở đây theo mẫu §3a / §3b: đổi gì, vì
  sao, và cái gì **không** đổi.

**Cái gì vẫn đứng.** Mở khoá V1 là gỡ tính bất biến của *quyết định thiết kế*,
không phải gỡ kỷ luật chung của repo. Những thứ sau không thuộc V1 và không đổi
theo: sàn accessibility (contrast, target ≥ 48dp), luật "dùng token chứ không
dùng literal", lưới 4dp, thứ tự và tính đầy đủ của thang token, layering của
`lib/core/theme/` (`theme-architecture.md`), l10n, và mọi gate architecture /
domain / data / business-rule. Một redesign hợp lệ vẫn thoả tất cả những thứ đó.

**Vì sao mở.** Không phải vì cơ chế đóng băng hỏng — nó chạy đúng như thiết kế.
Mà vì cái giá của nó đã lộ ra: sáu mục `DESIGN_SYSTEM_BLOCKED` trong `wbs.md`
là sáu defect UI đã chẩn đoán xong, có cách sửa, và nằm chờ một "điều kiện mở
lại" thay vì chờ một quyết định. Một baseline mà mọi cải thiện đều phải xin phép
sẽ tích nợ nhanh hơn tốc độ trả.

### 3-bis. Điều kiện mở lại cũ — lịch sử, không còn hiệu lực

Giữ nguyên ở đây vì §3a và §3b viện dẫn chúng, và vì `wbs.md` còn trỏ tới
"Trigger 2 / Trigger 3". **Không mục nào dưới đây còn ràng buộc ai.**

Bản cũ nói V1 MUST NOT được mở lại trừ bằng một task design-system tường minh,
và task đó MUST được kích hoạt bởi ít nhất một trong sáu điều kiện:

1. Nâng Flutter SDK làm đổi hành vi Material.
2. Chủ đích thiết kế lại palette / theme.
3. Thêm một họ shared primitive / component mới.
4. Thay đổi spec hoặc yêu cầu accessibility buộc hợp đồng phải đổi.
5. Một defect production được chứng minh nằm trong một hợp đồng đã đóng băng.
6. **Chủ dự án chỉ định một thay đổi hình thức cho component đã có**, kèm tham
   chiếu thị giác cụ thể (mockup, ảnh chụp, bản dựng) — xem §3a.

Bản cũ cũng cấm task feature nới lỏng, thêm `exclude`, hay xoá rule guard và
test ở cột Enforcement để code của nó đi qua — và ghi lại rằng lối vòng đó
**từng mở**: tới trước M100.48, thêm một dòng `exclude` vào một rule ở §2 vẫn để
guard, probe và CI xanh cùng lúc, đo được chứ không phải suy đoán. M100.48 bịt
nó bằng `test_memox_v7_frozen_contract_enforcement.py`; lần mở khoá này xoá
probe đó, vì nó chính là thứ chặn một task design-system sửa rule một cách có
chủ đích.

**Chỗ đó nay dựa vào review, không dựa vào một lớp canh.** Sửa một guard rule
hay một test ở cột Enforcement là thay đổi nhìn thấy được trong diff, và nó
**MUST** đứng riêng trong một task design-system chứ không đi ké một PR feature
— cùng luật "no drive-by refactors outside the stated scope" ở `CLAUDE.md`.

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
| 1, 2 — role identity và role ngữ nghĩa | không | `tonal` đọc `secondaryContainer` / `onSecondaryContainer`, đúng cặp `_FilledButtonDefaultsM3` cấp cho `FilledButton.tonal`. (Ghi lại lịch sử M100.73; đến M100.112 `tonal` đọc `surfaceContainer` / `onSurface` — xem WBS.) Không role nào bị thay bằng role khác, không hex nào mới |
| 5 — foundation | **có, ở M100.76**: `AppSizing.statusDot = 8` | Ở M100.73 thì không: viền tròn dùng `AppRadius.pill` đã có; độ dày là default của `BorderSide`, và `mx_tonal_and_outlined_test.dart` ghim sự trùng khớp giữa nó với `AppStroke.hairline` — đã kiểm bằng tiêm lỗi (dời token lên 1.5 thì test đỏ). Xem §3b |
| 8 — ripple / state | không | Cả hai variant đi qua `buildFilledStyle` / resolver dùng chung, không qua `styleFrom`. Đây đúng là điều `MxIconButton` đã tự ghi lại sau hai lần gỡ variant filled: *"build its colours from the shared resolvers, not from `styleFrom`"* |
| 11 — chrome của `MxContentShell` | không | Shell không bị chạm. Nút bar là widget do feature truyền vào `actions:`, nên đổi hình dạng của chúng là việc của feature |

**Ràng buộc lên task feature không đổi.** M100.73 chỉ thêm variant vào primitive
và **MUST NOT** dùng chúng ở đâu cả; task feature đi sau (M100.74) là nơi chúng
có caller đầu tiên. Tách như vậy vì §3 khi đó (nay là §3-bis) cấm "merge một
phần thay đổi để mở đường"
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

## 4. Vì sao A20.1 không còn là backlog

`docs/reviews/a20-1-design-system-reconciliation.md` từ đây là **bằng chứng đóng
lịch sử**, không phải danh sách việc phải làm. Cả 51 finding đã đóng (§27), pass
sửa lỗi đã đóng lại ba cái ngắn hợp đồng (§27.1), và tiêu chí cuối cùng còn thiếu
bằng chứng — bộ integration trên thiết bị — đã chạy ở task này.

**Không mở A21 hay một audit khác.** Một audit mới không sinh ra thông tin: thứ
làm V1 giữ được là bảng enforcement ở §2, và chỗ nào bảng đó trống thì việc phải
làm là thêm một guard, không phải viết thêm một báo cáo.
