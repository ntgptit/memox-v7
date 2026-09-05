# Design System V1 — FROZEN

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi nhận Design System V1 là baseline ổn định của repo: hợp đồng nào đóng băng, bằng chứng nào chứng minh, và điều kiện nào mở lại |
| **Scope** | Foundation, theme mapping, shared primitive contract, a11y floor, golden authoring policy. Ngoài phạm vi: **composition của từng màn hình nghiệp vụ** (không đóng băng), giá trị token cụ thể (AD-14), hợp đồng component-level (`.claude/skills/flutter-theme-design/`) |
| **Source of truth for** | Freeze record của V1 · danh sách hợp đồng đóng băng · reopen trigger · bản đồ enforcement cho từng hợp đồng |
| **Depends on** | `document-conventions.md` · `architecture.md` (AD-14, AD-15, AD-23) · `design-system/theme-architecture.md` · `reviews/a20-1-design-system-reconciliation.md` (bằng chứng lịch sử) |
| **Updated by task** | M100.40 |
| **Last updated** | 2026-09-05 |

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

**Không đóng băng:** composition của màn hình nghiệp vụ. Một feature vẫn được
xếp đặt, thêm, bớt section; cái nó không được làm là mục 2, 4, 5, 12, 13 ở trên.

---

## 3. Điều kiện mở lại

V1 chỉ mở lại bằng **một task design-system tường minh**, và chỉ khi có một
trong năm trigger sau:

1. Nâng Flutter SDK làm đổi hành vi Material.
2. Chủ đích thiết kế lại palette / theme.
3. Thêm một họ shared primitive / component mới.
4. Thay đổi spec hoặc yêu cầu accessibility buộc hợp đồng phải đổi.
5. Một defect production được chứng minh nằm trong một hợp đồng đã đóng băng.

**Làm feature không phải là quyền sửa foundation hay shared contract.** Một task
feature chạm vào mục 2, 4, 5, 12 hoặc 13 của bảng trên MUST dừng lại và mở một
task design-system riêng.

---

## 4. Vì sao A20.1 không còn là backlog

`docs/reviews/a20-1-design-system-reconciliation.md` từ đây là **bằng chứng đóng
lịch sử**, không phải danh sách việc phải làm. Cả 51 finding đã đóng (§27), pass
sửa lỗi đã đóng lại ba cái ngắn hợp đồng (§27.1), và tiêu chí cuối cùng còn thiếu
bằng chứng — bộ integration trên thiết bị — đã chạy ở task này.

**Không mở A21 hay một audit khác.** Một audit mới không sinh ra thông tin: thứ
làm V1 giữ được là bảng enforcement ở §2, và chỗ nào bảng đó trống thì việc phải
làm là thêm một guard, không phải viết thêm một báo cáo.
