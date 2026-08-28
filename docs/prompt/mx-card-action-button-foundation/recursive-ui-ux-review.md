# Recursive UI/UX Review — MxCard and MxActionButton Foundation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập render, so sánh và auto-fix mọi visual/interaction regression phát sinh khi chuẩn hoá MxCard và hoàn thiện MxActionButton |
| **Scope** | Component specimens, production screens tiêu thụ card/button, light/dark/high-contrast, responsive/text-scale, focus/hover/press/loading, accessibility và gallery; không đổi nghiệp vụ |
| **Source of truth for** | Quy trình recursive UI/UX review của MxCard/MxActionButton hardening |
| **Depends on** | `implementation.md`, latest production tree, AD-14/design parity/wireframes, MemoX tokens, approved gallery baseline và architecture review output |
| **Updated by task** | MxCard/MxActionButton foundation prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là UI/UX reviewer độc lập. Audit-only có thể chạy song song với architecture
review, nhưng không sửa worktree đồng thời. Khi coordinator giao lượt fix, re-read
toàn bộ latest diff sau architecture fixes rồi mới áp UI fixes.

Golden mới là regression baseline, không phải bằng chứng implementation đúng.
Phải render production states, inspect pixels/geometry và so với design
contract/previous approved state trước khi accept.

## 5Why visual audit

| Why | Rủi ro cần chứng minh | Quyết định review |
|---|---|---|
| 1 | Closed recipe có thể làm hàng chục screen đổi shadow/padding/radius cùng lúc; đặc biệt constructor unnamed hiện là raised còn `flat` vừa được migrate trên main. | So before/after theo từng surface role và production screen, không đổi depth chỉ vì rename và không accept bulk golden churn. |
| 2 | Một card đẹp riêng lẻ có thể sai khi nested, nằm trên sheet hoặc chứa progress bar bám mép. | Render hierarchy pairs và đo shared edges/clipping. |
| 3 | Focus/hover/press chỉ xuất hiện trên web/keyboard nên ảnh Android resting không bắt được. | Dựng deterministic interaction specimens và geometry assertions. |
| 4 | Button state đọc được trên primary chưa chắc đọc được trên tonal/danger/high contrast. | Kiểm từng fill-ground pair bằng render và contrast evidence. |
| 5 | Responsive failure thường nằm ở Vietnamese/Korean, text scale 2.0 và 320dp chứ không ở gallery 393dp. | Stress matrix ngoài gallery và chỉ publish canonical 393×852 rows. |

## Approved design direction

Được phép thay đổi duy nhất:

- mọi card cùng semantic recipe hội tụ về một fill/border/radius/elevation/
  padding contract;
- M99.70 `flat` và tri-state selected giữ đúng edge/semantics đã owner-review;
  semantic treatment mới chỉ hội tụ khi cùng meaning, không ép mọi selection có
  cùng fill;
- missing focus-visible/touch-target/contrast/interaction cue được sửa;
- missing component specimen/golden được bổ sung.

Không được tự ý thay đổi:

- information hierarchy, screen region order hoặc navigation;
- content copy, business values hoặc visibility rules;
- card list density chỉ để “trông thoáng hơn”;
- font scale/rung ngoài component contract;
- product layout để chữa shared component bug;
- mọi concept divergence đã được owner chốt trong design parity/wireframe.

## Pass 1 — component specimen matrix

Render component thật từ production shared widgets, không mock CSS:

### MxCard family

- existing flat, named raised replacement của current default, và mọi
  focal/muted/accent/feedback recipe thực sự được implementation inventory chốt;
- padding none/compact/standard ở boundary representatives;
- informational vs interactive;
- rest, hover, pressed, keyboard focus-visible;
- tap-only, long-press-only, nested control;
- tri-state selection (`null/false/true`) trên representative flat/raised card,
  gồm edge-only và selected tint treatment nếu production thật có cả hai;
- feedback info/success/warning/danger chỉ khi recipe đó được tạo;
- flat nested surface, page → raised/focal và card → nested tile.

### MxActionButton

- primary, tonal, secondary, destructive;
- standard/compact;
- rest, hover, pressed, focused, disabled, loading;
- icon + label;
- short and long labels.
- secondary rest/loading edge parity, touch-mode vs keyboard autofocus, và
  MxButtonPair one-row/longest-word stacking boundary từ M99.75.

Cover light, dark, high-contrast light/dark. Use pairwise/boundary cases; không
tạo Cartesian golden vô ích. Widgetbook phải có dedicated surfaces/knobs để owner
quan sát legal API mà không cần mở từng feature.

## Pass 2 — geometry and hierarchy contract

Measure bằng `tester.getRect`/render geometry, không nhìn container vô hình.
Assert ít nhất:

- recipe radius/edge/clip nhất quán;
- focus ring không đổi rect hoặc dịch content;
- interactive hit rect ≥48×48;
- padding enum map đúng token và shared edges;
- progress bar/child seated on edge bị clip bởi card radius đúng cách;
- flat nested surface không có shadow-on-shadow;
- raised/focal không nested trong raised/focal ngoài approved exception;
- two-column/row card groups vẫn có width/gap/baseline đúng sau migration;
- action button standard/compact painted/hit geometry đúng;
- loading button không đổi width/height/alignment;
- icon-label gap và RTL ordering đúng.

Khi một screen/wireframe khai geometry contract, dùng chính finder production
của screen đó. Không đo `Row`/`Wrap` bao ngoài rồi kết luận child đúng width.

## Pass 3 — production screen sweep

Re-run inventory và render tối thiểu một representative state cho từng cụm:

- Library/deck hero và deck rows;
- card list normal/selection/empty/error;
- card detail summary/current progress/history;
- card editor action bar và destructive/feedback sections;
- import source/choice/preview/result/error;
- export choice/error/progress/action bar;
- study home and Browse/Guess/Recall/Fill/Match surfaces;
- Progress, Settings, Reminder, Search và Trash surfaces;
- dialogs/sheets containing primary/secondary/destructive buttons.

Với mỗi screen, so trước/sau bằng approved golden/gallery hoặc render từ
`origin/main`. Phân loại mỗi delta:

1. intended canonicalization;
2. required accessibility/state fix;
3. unintended regression;
4. blocker cần owner decision.

Auto-fix loại 3. Không tự accept loại 4. Ghi loại 1–2 bằng exact screen/state và
lý do, không dùng một dòng “all card changes expected”.

## Pass 4 — interaction quality

Kiểm trực tiếp:

- card hover/press đủ thấy nhưng không làm content đổi màu vô lý;
- keyboard focus ring rõ trên mọi actual ground, không bị child che;
- pointer/touch activation không để ring focus-visible sai;
- nested menu/icon button có riêng hover/focus/tap và không kích hoạt card;
- selected không dựa vào màu duy nhất và giữ tri-state semantics; feedback có
  icon/text cue thuộc product content thay vì chỉ đổi fill;
- disabled/loading action không trông actionable;
- destructive chỉ dùng cho destructive action;
- một interaction region không có nhiều strong primary CTA cạnh tranh ngoài
  contract đã duyệt;
- loading spinner/label đọc được trên đúng fill và không nhảy layout.

## Pass 5 — responsive, localization and accessibility

Stress test:

- 320×640, 393×852, 412×915;
- text scale 1.0 và 2.0;
- English, Vietnamese và Korean content;
- light/dark/high contrast;
- RTL component-level specimens khi icon/text order có ý nghĩa.

Fail và auto-fix nếu:

- overflow, clipping, accidental ellipsis hoặc horizontal scroll;
- surface column shared edges lệch;
- card/button target dưới 48;
- label không còn accessible name/role/state;
- selected/error meaning chỉ bằng color;
- text/body/icon contrast dưới repo threshold;
- long label làm compact button mất nghĩa hoặc card hierarchy vỡ.

Không giảm font, clamp text scale hoặc hardcode padding để chữa một viewport.

## Golden và gallery discipline

Regenerate bằng timezone bắt buộc:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Sau update:

1. Inspect diff PNG từng component/production state.
2. Chạy fresh golden comparison lại, không chỉ update command.
3. Kiểm gallery chỉ chứa canonical 393×852 rows; stress goldens khác width ở
   test nhưng không chen vào gallery.
4. Publish lại đúng existing Artifact URL trong `CLAUDE.md`.
5. Trả URL cho owner visual confirmation trước khi gọi PR ready.

## Recursive auto-fix loop

Cho mỗi finding:

1. Ghi exact screen/state/theme/viewport và evidence ảnh hoặc rect.
2. Xác định bug ở shared recipe, composed primitive hay feature layout.
3. Sửa tại owner thấp nhất đúng contract; không nudge từng screen nếu shared
   component sai.
4. Chạy targeted production test + relevant golden.
5. Re-render toàn bộ affected recipe consumers để bắt degradation dây chuyền.
6. Lặp đến khi hai sweep liên tiếp không có unapproved delta.

Nếu visual fix cần thay hierarchy/business visibility/copy, dừng và xin owner
decision; không tự mở rộng scope.

## Final verification và clean stop

Reviewer chạy changed gate sau UI fixes:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Coordinator chịu trách nhiệm full gate cuối sau khi hai review đã được áp tuần
tự. UI review chỉ clean khi:

- legal component matrix được render/inspect;
- every affected production cluster có state evidence;
- no unapproved shadow/padding/radius/width/baseline drift;
- focus/hover/press/loading và accessibility pass;
- responsive/localization/high-contrast boundary cases sạch;
- golden comparison xanh sau update;
- gallery existing URL được republish;
- report liệt kê approved divergences và auto-fixes cụ thể, không blanket pass.
