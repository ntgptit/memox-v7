# Recursive UI/UX Review — OutlinedButton

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập render, so sánh và auto-fix mọi visual/interaction regression phát sinh khi đối chiếu `MxActionButton.secondary` (OutlinedButton) với component contract của kit |
| **Scope** | Mọi production screen tiêu thụ `MxActionButton.secondary`, light/dark/high-contrast, rest/hover/press/focus/disabled/loading, responsive/text-scale, accessibility và gallery; không đổi nghiệp vụ |
| **Source of truth for** | Quy trình recursive UI/UX review của prompt set OutlinedButton |
| **Depends on** | `implementation.md` (cùng thư mục), latest production tree sau architecture/logic review, `docs/wireframes/`, design tokens hiện có (`AppSizing`, `AppSpacing`, `AppRadius`, `AppStroke`), gallery Artifact URL trong `CLAUDE.md` |
| **Updated by task** | OutlinedButton Flutter handoff spec |
| **Last updated** | 2026-09-12 |

---

Bạn là UI/UX reviewer độc lập. Audit-only ở pass đầu, có thể chạy song song với
architecture/logic review nhưng không sửa worktree đồng thời. Khi coordinator
giao lượt fix, re-read toàn bộ worktree mới nhất **sau** architecture fixes
trước khi áp UI fixes của mình. Report-only không đủ — mỗi finding phải được
auto-fix trong scope rồi verify lại.

**Không có ảnh mockup/concept nào đi kèm component contract này** (kit chỉ đưa
text: dimension table + state matrix) — theo đúng quy tắc "khi không có concept
image, so với wireframe/token/behavior contract của repo". Vì vậy pass này so
với `docs/wireframes/`, token hiện có và hành vi đã implement, KHÔNG tự suy diễn
một hình ảnh không tồn tại. Một golden mới được update là baseline hồi quy, KHÔNG
phải bằng chứng implementation đúng — phải render production state thật, đo
geometry và so với contract trước khi accept.

## 5Why visual audit

| Why | Rủi ro cần chứng minh | Quyết định review |
|---|---|---|
| 1 | `outline` vs `outlineVariant` là khác biệt nhỏ trên mắt thường (cùng là viền mỏng), nên một regression thật (ví dụ lỡ đổi sang `outlineVariant`) có thể "trông vẫn ổn" trên ảnh chụp nhanh | Đo bằng resolved `ColorScheme` value tại runtime, không đánh giá bằng mắt qua screenshot |
| 2 | Compact/dense size hoặc label dài có thể làm border/label tràn nếu implementation vô tình đổi geometry dùng chung | Render đủ `standard`/`compact` với label ngắn/dài, đo bằng `getRect` |
| 3 | Focus ring (`primary`, thay hairline) có thể bị nhầm với border thường trên ảnh tĩnh nếu không bắt đúng frame focused | Render riêng trạng thái `WidgetState.focused` qua harness, không chỉ suy từ code |
| 4 | Disabled label 38% có thể đọc khác nhau trên light/dark/high-contrast dù cùng token | Render đủ bốn theme (light, dark, HC light, HC dark) và đo contrast thật |
| 5 | Một fix nhỏ ở theme dùng chung (`buildSharedButtonStyle`) có thể vô tình ảnh hưởng `primary`/`tonal`/`destructive` dù task chỉ nhắm `secondary` | Re-render cả bốn variant nếu bất kỳ file dùng chung nào bị chạm, không chỉ variant đang audit |

## Approved design direction

Divergence đã được duyệt sẵn (không cần hỏi lại owner), vì có bằng chứng
machine-enforced đi kèm — xem `implementation.md` Why 1–2:

- border dùng `outline` (rest) + `primary` (focus ring), **không** phải
  `outlineVariant` như kit — đây là divergence có chủ đích khỏi input kit, đã
  pin bởi `m3_role_bindings.dart`.

Divergence **không** được tự ý thêm (unapproved nếu phát hiện):

- bất kỳ đổi màu/alpha nào khác với bảng Findings của `implementation.md`;
- đổi geometry (min height/width, padding, radius, typography) so với
  `buildSharedButtonStyle` hiện tại;
- đổi cách `secondary` phản ứng với hover/press/focus/disabled/loading so với
  hành vi đang có.

## Pass 1 — component specimen matrix (production-state rendering)

Render `MxActionButton(variant: MxActionButtonVariant.secondary, ...)` **từ
chính production widget tree** (không mock CSS, không dựng lại style rời) cho:

- `MxActionButtonSize.standard` và `.compact`;
- label ngắn ("OK") và label dài đủ để chạm biên 2 dòng (`maxLines: 2`,
  `TextOverflow.ellipsis` theo `_buildChild`);
- trạng thái `rest`, `hovered`, `pressed`, `focused` (qua `WidgetState` giả lập
  hoặc `FocusNode.requestFocus()`), `disabled` (`onPressed: null`), `loading`
  (`isLoading: true`, cả hai giá trị của `shouldKeepLabelWhileLoading`);
- theme `light`, `dark`, `buildHighContrastLightTheme`,
  `buildHighContrastDarkTheme`.

Không tạo Cartesian đầy đủ nếu một chiều đã rõ ràng không tương tác với chiều
khác (ví dụ label ngắn/dài không cần nhân với cả bốn theme) — dùng
pairwise/boundary, ghi rõ tổ hợp nào được coi là đại diện.

## Pass 2 — geometry contract (getRect)

Dùng `tester.getRect` trên `Material`/button rect thật (không đo `Row`/`Padding`
bao ngoài) để pin:

- chiều cao tối thiểu = `AppSizing.touchTarget` ở `standard`, không nhỏ hơn dù
  label ngắn;
- `compact` vẽ thấp hơn nhưng target chạm (`MaterialTapTargetSize.padded`) vẫn
  ≥ `AppSizing.touchTarget`;
- chiều rộng là content-driven (tăng theo label, có sàn `AppSizing.
  buttonMinWidth`, không có trần cứng ngoài chiều rộng màn hình) — đúng class
  mà component contract gán cho dimension "border"/geometry của component này;
- rect không đổi giữa `rest` và `focused` (focus ring vẽ trên `side` của
  `OutlinedBorder`, không cộng thêm layout) — đây là assertion trực tiếp cho
  câu "focus ring không cộng layout" trong `implementation.md` Findings.

## Pass 3 — production screen sweep

1. Grep toàn repo `MxActionButtonVariant.secondary` trong `lib/features/**` để
   liệt kê mọi call-site thật (không dùng số lượng nhớ từ lần trước).
2. Với mỗi call-site, render state hiện tại của nó (rest tối thiểu; thêm
   disabled/loading nếu call-site đó dùng) và so với ảnh chụp/golden hiện có
   trên `origin/main`.
3. Phân loại mỗi khác biệt tìm thấy:
   - **approved divergence** — khớp với mục "Approved design direction" ở trên
     (chỉ có đúng một loại: không có, vì border role không đổi ở call-site,
     chỉ đổi ở theme dùng chung một lần);
   - **unapproved divergence** — bất kỳ khác biệt nào khác. Auto-fix nếu do
     lỗi implementation; nếu do thiếu evidence, coi là finding phải giải quyết
     trước khi clean-stop, không được bỏ qua.
4. Không có call-site nào bị coi là "chắc vẫn ổn" mà không render.

## Pass 4 — interaction quality

- hover/press overlay (`AppInteractionStates.controlOverlay`, `primary` @
  8/10/10%) nhìn thấy được nhưng không đổi hue của label;
- focus ring rõ trên `surface` thật của từng screen, không bị nested
  child/icon che;
- pointer/touch activation không để lại keyboard focus-visible ring sai chế độ
  (theo cơ chế `_takesFocus`/`FocusHighlightMode`, nếu call-site nào dùng
  `shouldAutofocus`);
- loading giữ nguyên width/height/alignment, không nhảy layout, label + spinner
  đọc được trên đúng fill;
- disabled không trông "vẫn bấm được" — label 38% + border `disabledSurface`
  đủ phân biệt với rest trên cả bốn theme.

## Pass 5 — responsive, localization and accessibility

Stress test tối thiểu:

- 320×640 và 393×852 (contract không yêu cầu công thức riêng cho OutlinedButton
  ngoài Foundations, nhưng label dài phải không tràn ở 320);
- text scale 1.0 và 2.0;
- một label tiếng Việt có dấu và một label dài (ví dụ tiếng Đức/Hàn nếu màn đó
  vốn đã có) tại call-site thật, không label giả "Lorem";
- light/dark/high-contrast light/dark.

Fail và auto-fix nếu: label bị cắt không đúng chủ đích (`maxLines: 2` +
ellipsis là hành vi đúng, tràn ra ngoài nút thì không), target dưới 48 hiệu
dụng, hoặc contrast label/border dưới ngưỡng đã đo trong `implementation.md`
Findings.

## Golden và gallery discipline

Chỉ regenerate golden nếu Pass 1–5 phát hiện auto-fix làm đổi pixel thật (theo
Findings của `implementation.md`, trường hợp mặc định là **không đổi pixel**):

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Nếu chạy lệnh trên: inspect từng PNG đổi theo state, xác nhận đúng những
call-site đã auto-fix ở Pass 3 mới đổi — một golden đổi ở nơi không có finding
là dấu hiệu regression, không phải "golden mới ổn định". Publish lại đúng
Artifact URL hiện có trong `CLAUDE.md`; không tạo gallery mới. Nếu Findings xác
nhận không đổi pixel, KHÔNG chạy `--update-goldens` — một lần update không cần
thiết vẫn là một diff phải giải thích.

## Recursive auto-fix loop

Cho mỗi finding:

1. Ghi chính xác screen/state/theme/viewport và bằng chứng (`getRect` value
   hoặc ảnh render).
2. Xác định lỗi ở theme dùng chung (`app_button_themes.dart`) hay ở call-site
   feature; sửa tại chỗ thấp nhất đúng nguồn — không vá từng call-site nếu lỗi
   nằm ở theme.
3. Chạy lại targeted test/golden liên quan.
4. Re-render mọi call-site khác dùng `secondary` để bắt hiệu ứng dây chuyền,
   vì đây là style dùng chung.
5. Lặp đến khi hai sweep liên tiếp không còn unapproved divergence.

Nếu một finding đòi đổi hierarchy, business visibility hoặc copy, dừng và báo
blocker — không tự mở rộng phạm vi ra khỏi OutlinedButton.

## Final verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Review này chỉ clean khi:

- mọi call-site `MxActionButtonVariant.secondary` trong `lib/features/**` đã
  render và phân loại (approved/unapproved divergence), không mục nào bỏ trống;
- `getRect` xác nhận geometry (48dp floor, content-driven width, focus ring
  không đổi rect) đúng ở cả `standard` và `compact`;
- không unapproved divergence nào còn mở; mọi divergence còn lại đều nằm trong
  danh sách "Approved design direction" ở trên;
- responsive/localization/high-contrast boundary cases sạch;
- nếu có regenerate golden: đã inspect từng PNG và republish đúng Artifact URL;
  nếu không: xác nhận rõ lý do (Findings nói không đổi pixel);
- changed gate xanh;
- report liệt kê approved divergence, auto-fix cụ thể (nếu có) và trạng thái
  gallery — không ghi blanket "pass" thiếu bằng chứng.
