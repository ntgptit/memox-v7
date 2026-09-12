# Implement: xác nhận và đóng contract OutlinedButton

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đối chiếu `OutlinedButton`/`MxActionButton.secondary` hiện tại với component contract "B · Buttons & actions · OutlinedButton" của MemoX HTML design kit, đóng đúng một sai khác đã xác định (border role) mà không mở lại bất kỳ hợp đồng đóng băng nào khác |
| **Scope** | `lib/core/theme/components/actions/app_button_themes.dart` (`buildOutlinedButtonTheme`), `lib/shared/widgets/mx_action_button.dart` (nhánh `MxActionButtonVariant.secondary`), test coverage tương ứng. KHÔNG tạo widget `OutlinedButton` trần hay class `MxOutlinedButton` mới |
| **Source of truth for** | Hướng dẫn thực thi xác nhận/đóng gap cho component OutlinedButton của đợt port design kit; quyết định kiến trúc chính thức (nếu phát sinh ngoài dự kiến) phải được promote vào AD/design-system contract của repo, không sống trong prompt này |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, `docs/design-system/v1-freeze.md` (§2 dòng 1, 2, 6, 13), `docs/design-system/tokyo-component-mapping.md`, `.claude/skills/flutter-theme-design/references/buttons-actions.md` §16, component contract gốc chép nguyên văn ở mục "Input" dưới đây |
| **Updated by task** | OutlinedButton Flutter handoff spec |
| **Last updated** | 2026-09-12 |

---

Thực hiện trên worktree sạch đã sync `origin/main` mới nhất (fetch + `git status`
trước khi sửa, ghi baseline SHA vào PR). Prompt này là execution aid, không phải
nguồn business behavior: mọi callback, navigation, controller/use-case call và
BR/UC hiện hữu phải được giữ nguyên. Đây là task xác nhận (confirmation task),
không phải refactor — chỉ sửa code khi một bước verification ở dưới **tái hiện
một defect thật**.

## Input — component contract gốc (từ kit, chưa qua kiểm chứng)

```
Component: OutlinedButton — low-emphasis / cancel
Dimension: border = outlineVariant, CONTENT-DRIVEN
Icons: none
State matrix:
  default   transparent fill, outline border, primary label
  pressed   8% primary tint fill [INFERRED]
  disabled  outlineVariant border, 38% label [INFERRED]
```

Đây là **input chưa qua kiểm chứng**, không phải ground truth — AGENTS.md nói rõ
prompt artifact không phải nguồn business behavior. Mục 5Why và "Findings" dưới
đây là kết quả đối chiếu input này với contract thật của repo.

## 5Why bắt buộc

| Why | Bằng chứng | Quyết định mở khoá |
|---|---|---|
| 1. Vì sao KHÔNG chép nguyên "border: outlineVariant" từ kit vào code? | `test/core/theme/contracts/m3_role_bindings.dart:267-277` pin cứng `RoleBinding(component: 'OutlinedButton', slot: 'side', requires: ['outline', 'primary'], refuses: ['outlineVariant'])`, chạy qua `m3_role_contract_test.dart`. Đổi sang `outlineVariant` làm test này đỏ ngay lập tức | Giữ nguyên `scheme.outline` (rest) + `scheme.primary` (focus ring) tại `app_button_themes.dart:444` và `:431`. Đây là hợp đồng đóng băng V1 §2 dòng 1–2 (role identity, không retune role ngữ nghĩa), không phải preference của task này |
| 2. Vì sao không tự ý "sửa cho khớp kit" rồi ghi chú lại? | `docs/design-system/v1-freeze.md` §3: mở lại hợp đồng đóng băng cần 1 trong 6 điều kiện; điều kiện 6 (chủ dự án chỉ định thay đổi hình thức) đòi "tham chiếu thị giác cụ thể (mockup, ảnh chụp, bản dựng)". Input ở trên là text thuần, không kèm ảnh/mockup | Task này KHÔNG mở lại hợp đồng. Ghi nhận sai khác vào tài liệu, giữ `outline`; nếu chủ dự án sau này cung cấp ảnh chụp cụ thể muốn `outlineVariant`, đó là một task design-system riêng, không phải fix trong task này |
| 3. Vì sao khối test `secondary` đang bị comment trong `mx_action_button_state_matrix_test.dart:207-280` KHÔNG phải gap của task này? | Commit `dd627840` (PR #542, `test: disable colour-contrast gates for the Tokyo palette swap (M100.84)`): chủ dự án đã duyệt "ship verbatim" palette Tokyo dù 11/30 cặp light-mode fail WCAG AA; việc tắt gate là **task-2 của tokyo-palette-plan** (tag `TOKYO-2`), một quyết định cross-cutting toàn app, không riêng OutlinedButton | Task này KHÔNG bật lại khối test đó và KHÔNG viết lại phép đo contrast thay nó. Nêu rõ trong review prompt rằng TOKYO-2 là out-of-scope, để phiên sau không tưởng nhầm đây là nợ của riêng component này |
| 4. Vì sao dùng lại `MxActionButton(variant: .secondary)` thay vì tạo widget mới? | `.claude/skills/flutter-theme-design/references/buttons-actions.md` §16 định nghĩa shared widget của `OutlinedButtonThemeData` chính là `MxActionButton.secondary`; `v1-freeze.md` §2 dòng 13 (guard `no_raw_button`) cấm `OutlinedButton` trần trong `lib/features/` | Không tạo `MxOutlinedButton` hay export `OutlinedButton` trần. Một class song song cho cùng nghĩa là đúng kiểu "hai hệ button" mà `MxActionButtonVariant` sinh ra để chặn (xem doc-comment enum tại `mx_action_button.dart`) |
| 5. Vì sao "pressed: 8% primary tint [INFERRED]" trong kit KHÔNG trở thành một test mới ép đúng 8%? | `lib/core/theme/states/app_interaction_states.dart:72-74`: `stateLayerHover = 0.08`, `stateLayerFocus = 0.10`, `stateLayerPressed = 0.10`. Giá trị pressed thật là **10%**, không phải 8% — 8% là của hover. `mx_action_button_state_matrix_test.dart` tự nói (dòng 18-21) nó "pins exact tokens only where a milestone already pinned them"; chưa milestone nào pin alpha chính xác cho `secondary` | Ghi nhận số đúng (pressed = 10%, hover = 8%, focus = 10%, cùng qua `AppInteractionStates.controlOverlay(scheme)` với `hoverColor: scheme.primary`) làm tài liệu tham chiếu. KHÔNG mint một assertion mới ép alpha nếu không có milestone nào yêu cầu — việc đó là rigor task này không được giao |

## Findings — đối chiếu input với contract thật

Contract thật hiện đã cài đủ cho **cả ba dòng** của state matrix trong input,
với đúng một sai khác (dòng border role):

| Thuộc tính kit | Input (kit) | Contract thật của repo | Vị trí | Khớp? |
|---|---|---|---|---|
| Fill lúc rest | transparent | Không set `backgroundColor` → Material vẽ trong suốt (`_OutlinedButtonDefaultsM3`) | `app_button_themes.dart:405-445` | Khớp |
| Border lúc rest | outlineVariant | `scheme.outline` | `app_button_themes.dart:444` | **Khác — xem Why 1** |
| Label lúc rest | primary | `scheme.primary` | `app_button_themes.dart` (nhánh `foregroundColor`, ngay trên dòng 418) | Khớp |
| Border khi focus | (không nêu trong kit) | `scheme.primary`, width `AppStroke.focus` — ring thay hairline, không cộng layout | `app_button_themes.dart:431` | N/A trong kit, đã đúng theo M3 (`_OutlinedButtonDefaultsM3.side` tự đổi role khi focus) |
| Pressed | 8% primary tint [INFERRED] | `scheme.primary` tại alpha `stateLayerPressed = 0.10` (10%), qua `AppInteractionStates.controlOverlay` | `app_button_themes.dart:79` + `app_interaction_states.dart:72-119` | **Số inferred sai (8% thay vì 10%) — xem Why 5** |
| Disabled border | outlineVariant | `semantic.disabledSurface` (solid, 12% onSurface blend qua `disabledSurfaceBlend`) | `app_button_themes.dart:418` | **Khác — cùng nguyên nhân Why 1**, nhưng đây là role "disabled chung" của mọi button (filled lẫn outlined), không riêng `outlineVariant`/`outline` |
| Disabled label | 38% [INFERRED] | `semantic.onDisabled` = `Color(0x61313133)` light / `Color(0x61E3E3E6)` dark — alpha `0x61` ≈ 38% | `app_colors.dart:86-87` | **Khớp đúng** |
| Icon | none | Không nhánh icon riêng cho `secondary`; `MxActionButton.icon` dùng chung mọi variant | `mx_action_button.dart` | Khớp |
| Kích thước / geometry | (không có dimension nào khác ngoài border) | Geometry dùng chung mọi button: `AppSizing.touchTarget` (cao tối thiểu 48, content-driven theo chiều rộng), `AppSpacing.xl`/`md` padding, `AppRadius.md` bo góc, nhãn `labelLarge` + `buttonLabelWeight` (w700) | `app_button_themes.dart` (`buildSharedButtonStyle`) | Khớp — không có dimension riêng nào của OutlinedButton lệch khỏi Foundations |

**Kết luận:** không cần đổi code để hai dòng "Khớp đúng"/"Khớp" giữ nguyên.
Hai dòng "Khác" đều có cùng gốc (kit dùng `outlineVariant`, repo dùng `outline`
có chủ đích, có test pin) — action đúng là **giữ nguyên code, sửa/ghi tài liệu**,
không phải sửa code theo kit.

## Việc phải làm

1. Đọc đủ nguồn ở "Depends on" và mục Findings ở trên trước khi verify — không
   suy diễn lại từ đầu.
2. Chạy bộ test hiện có để xác nhận Findings vẫn đúng trên `origin/main` mới
   nhất (baseline có thể trôi giữa các PR song song trong cùng đợt port kit):
   - `flutter test test/core/theme/contracts/m3_role_contract_test.dart`
   - `flutter test test/shared/widgets/mx_tonal_and_outlined_test.dart`
   - `flutter test test/shared/widgets/mx_action_button_state_matrix_test.dart`
   - `flutter test test/shared/widgets/mx_action_button_composite_state_test.dart`
   - `flutter test test/core/theme/app_theme_test.dart`
3. Nếu cả năm suite trên xanh và không assertion nào mâu thuẫn với bảng Findings:
   **không sửa code**. Cập nhật đúng một dòng vào `docs/wbs.md` (mục sổ nợ hoặc
   mục port-kit tương ứng) ghi nhận: OutlinedButton đã đối chiếu với kit, sai
   khác border-role là có chủ đích (dẫn `m3_role_bindings.dart:267-277`), không
   cần action thêm.
4. Nếu một trong năm suite đỏ theo cách **không** giải thích được bằng
   Findings ở trên (nghĩa là một regression thật, không phải chỉ do
   TOKYO-2 đang tắt gate) — đó là defect thật. Sửa tối thiểu để suite xanh trở
   lại, KHÔNG đổi role border sang `outlineVariant` để "cho qua" — nếu sửa lỗi
   đó đòi đổi role, dừng lại và báo blocker thay vì tự mở hợp đồng đóng băng.
5. MAY (tuỳ chọn, không bắt buộc): thêm một assertion nhỏ pin đúng
   `stateLayerPressed = 0.10` cho `MxActionButtonVariant.secondary` nếu muốn có
   bằng chứng máy-kiểm cho Why 5 — chỉ làm nếu không đụng khối test đang bị
   TOKYO-2 comment-out; đặt trong một `test()`/`testWidgets()` mới, không bỏ
   comment khối cũ.

## Ngoài phạm vi (out of scope)

- Bật lại hoặc viết lại khối test bị comment bởi M100.84/TOKYO-2 trong
  `mx_action_button_state_matrix_test.dart` và `mx_pressable_test.dart` —
  thuộc tokyo-palette-plan, một task cross-cutting riêng.
- Đổi border role `OutlinedButton` sang `outlineVariant`, hoặc bất kỳ retune
  role ngữ nghĩa nào khác trong `docs/design-system/v1-freeze.md` §2.
- Tạo `MxOutlinedButton`, export `OutlinedButton` trần, hoặc thêm tham số cho
  phép caller truyền `borderColor`/`Color` vào `MxActionButton`.
- Đổi palette, type scale, spacing/gutter nền tảng — các "P0 changes" nêu ở
  cuối component contract gốc thuộc phạm vi Foundations/tokyo-palette-plan,
  không phải phạm vi component-level của prompt này.
- Domain/data/DB/BR/UC/generated files — task không đổi nghiệp vụ.

## Tests bắt buộc

Chạy đủ năm suite ở mục "Việc phải làm" bước 2. Nếu thêm assertion tuỳ chọn ở
bước 5, nó phải nằm trong phạm vi các file test đã liệt kê hoặc một file test
mới cùng thư mục `test/shared/widgets/`, và phải fail nếu `stateLayerPressed`
bị đổi (kiểm bằng tiêm lỗi tạm thời, revert trước khi commit).

## Verification và delivery

Inner loop trong lúc sửa (nếu có sửa):

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Trước khi mở PR, chạy full gate:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Không cần emulator IT (task không thêm flow mới trên device — hoặc xác nhận
không đổi gì, hoặc sửa một defect thuần presentation/theme). Không cần
regenerate golden nếu Findings xác nhận "không sửa code": không pixel nào đổi.
Nếu bước 4 buộc phải sửa code và pixel của `MxActionButton.secondary` đổi, MUST
chạy:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

rồi republish đúng Artifact URL đã có trong `CLAUDE.md`, không tạo gallery mới.

Nếu Bash/PowerShell hoặc `dod_check.sh` không chạy được trong môi trường thực
thi, báo blocker cụ thể (thiếu gì, lỗi gì) — không thay bằng một "pass" chung
chung.

## Clean stop

Dừng sạch khi:

- Năm suite ở mục "Việc phải làm" xanh trên `origin/main` mới nhất;
- Bảng Findings ở trên hoặc đã được xác nhận đúng, hoặc mọi sai khác mới phát
  hiện đã được giải thích bằng một defect thật kèm bằng chứng tái hiện được —
  không có mục nào bỏ trống hoặc gắn nhãn "chắc vậy";
- Không dòng nào trong `docs/design-system/v1-freeze.md` §2 bị đổi, và
  `m3_role_bindings.dart` cho `OutlinedButton` vẫn `refuses: ['outlineVariant']`;
  nếu bước 4 chứng minh cần đổi, task đã dừng và báo blocker thay vì tự sửa;
- `docs/wbs.md` có đúng một dòng ghi nhận kết quả đối chiếu (mục 3);
- changed gate và full gate xanh (mục Verification);
- git status sạch, branch đã commit/push, PR non-draft đã mở kèm: kết quả năm
  suite, dòng WBS đã thêm, và xác nhận rõ có sửa code hay không (không ngụ ý);
- không merge PR nếu execution session không được user yêu cầu rõ.
