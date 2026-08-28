# Recursive UI/UX Review — Card Import Visual Hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập render, so sánh và auto-fix Card Import cho tới khi đạt visual hierarchy của Card Detail mà vẫn đúng wizard concept và responsive contract |
| **Scope** | Shell, context, stepper, source, mapping, preview, confirm, submitting, outcomes, footer, light/dark, responsive, text scale, accessibility, goldens và gallery |
| **Source of truth for** | Quy trình recursive UI/UX review của Card Import visual hierarchy |
| **Depends on** | `implementation.md`, latest production tree, M4.12, Card Detail production goldens, Card Import baseline goldens, MemoX tokens và architecture review output |
| **Updated by task** | Card Import visual hierarchy prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là UI/UX reviewer độc lập. Audit-only có thể chạy song song với architecture
review; không sửa worktree đồng thời. Khi đến lượt fix, re-read latest tree sau
architecture fixes.

Card Detail là style reference về hierarchy/surface/type, không phải pixel
overlay. Wireframe M4.12 quyết visible regions, order, states và interactions.
Golden mới chỉ là baseline; phải inspect render thật trước khi accept.

## 5Why visual audit

| Why | Rủi ro | Quyết định review |
|---|---|---|
| 1 | Thêm card quanh mọi group có thể tạo “card soup” thay vì hierarchy giống Card Detail. | Mỗi surface phải có đúng một semantic job; row bên trong dùng spacing/divider. |
| 2 | Shell migration dễ sinh gutter kép hoặc context/body/footer lệch shared edge. | Đo rect production của material children, không đo wrapper vô hình. |
| 3 | Preview đẹp ở 393dp có thể vỡ mapping, status chips và action labels ở 320dp/textScale 2.0. | Stress toàn state matrix ở narrow/large text/long localization. |
| 4 | Success/warning/error tint có thể thành mảng màu lớn gây rối như Match feedback cũ. | Tone tập trung ở icon/chip/edge; surface giữ calm và có non-color cue. |
| 5 | Update 12+ goldens cùng lúc dễ che một phase sai skeleton. | Compare từng phase với baseline, Card Detail grammar và geometry contract trước update. |

## Approved visual direction

Được phép:

- dùng `MxContentShell`, shared responsive gutter/max-width và footer seam;
- chuyển floating groups thành flat semantic panels;
- áp Card Detail section label, compact typography, icon well, status chip,
  muted/supporting surface và spacing rhythm;
- dùng `MxButtonPair` cho paired actions;
- thêm deterministic parsing/submitting visual coverage.

Không được:

- đổi region order, copy meaning, field/control visibility hoặc action flow;
- thêm breadcrumb/help/filter/progress/metric không có trong M4.12;
- bỏ Confirm hoặc gộp Preview với Import;
- đổi source option thành saturated selected fill;
- làm card list preview thành editor;
- giảm font riêng một viewport, clamp text scale hoặc hardcode magic padding;
- dùng màu là tín hiệu duy nhất;
- chấp nhận bulk golden churn bằng câu “new design”.

## Pass 1 — visual grammar comparison

Mở cạnh nhau:

- `card_detail_light/dark` production goldens;
- tất cả Card Import baseline goldens;
- latest rendered Card Import states.

Lập bảng evidence cho mỗi import region:

| Region | Card Detail grammar kế thừa | Import-specific divergence |
|---|---|---|
| Context | shared gutter, quiet hierarchy | stepper/breadcrumb được ghim, không hero card |
| Work panel | flat surface, subtle edge, compact type | interactive fields/options, not read-only |
| Metrics/status | icon well, tabular count, semantic ink | import readiness/validation, not scheduler |
| Outcome | summary hero + fact panel | success/skips/failure action footer |
| Footer | canonical buttons and seam | wizard progression and reassurance copy |

Fail nếu implementation sao chép scheduler/timeline visuals hoặc tạo new style
không có token/shared precedent.

## Pass 2 — geometry contract

Dùng `tester.getRect` trên production finders và assert:

- app bar/context/body/footer material edges dùng cùng resolved screen gutter;
- body max-width đúng shared breakpoint và centered trên wide viewport;
- source cards cùng top/bottom/width ở row mode; left/right edges trùng content;
- source cards stack full-width với đúng gap ở narrow/large text;
- every main/support panel full-width, không inboard indentation;
- Mapping label/value columns dùng stable edges; stacked mode không cắt text;
- Preview heading/count baseline khi side-by-side, intentional wrap khi hẹp;
- preview rows và reason text nằm trong card clip;
- Confirm/result icon wells, labels và trailing counts thẳng cột;
- footer width trùng body column, action pair equal-height;
- footer top nằm trên IME và row cuối scroll tới được;
- transition source→parsing và confirm→submitting không đổi context/footer rect;
- focus/selected border không làm surface hoặc content shift.

Đừng đo `Row`, `Padding` hay full-screen wrapper rồi kết luận child đúng. Finder
phải trỏ tới element người dùng thực sự nhìn thấy.

## Pass 3 — render matrix

Render production tree cho tối thiểu:

1. source upload empty light/dark;
2. source file ready, long filename;
3. paste empty/filled, keyboard open;
4. parsing;
5. parse error giữ source;
6. preview all-valid;
7. preview mixed invalid/duplicate/blank;
8. XLSX sheet + long mapping headers;
9. confirm với zero và non-zero reason counts;
10. submitting;
11. completed;
12. completedWithSkips;
13. noCardsAdded;
14. commitFailure.

Với mỗi state, phân loại delta:

1. intended hierarchy improvement;
2. required shared-component/accessible-state fix;
3. unintended regression;
4. owner decision needed.

Auto-fix loại 3. Không tự accept loại 4. Ghi exact PNG/state/region, không báo
“all import screens aligned”.

## Pass 4 — hierarchy và interaction quality

Kiểm trực tiếp:

- người dùng scan ra current step, current decision và next action trong một
  viewport;
- không có hai strong primary CTA cạnh tranh trong cùng interaction region;
- source option pair nhìn là một choice set, selected rõ bằng glyph/edge;
- guidance yên hơn work panel;
- mapping/preview groups rõ nhưng không card từng row;
- invalid reason gắn đúng row;
- status chips có icon/text/count và wrap ổn;
- semantic result tone chỉ nhấn icon/chip/edge, không nhuộm block lớn;
- loading chỉ có một spinner và không làm skeleton nhảy;
- secondary/primary/destructive hierarchy đúng;
- Close/remove/dropdown/toggle/button hover/focus/tap states đọc được;
- sticky footer không che data hoặc trở thành một bottom-nav giả.

## Pass 5 — responsive, localization, accessibility

Stress:

- 320×640, 393×852, 412×915 và wide constrained surface;
- text scale 1.0/2.0;
- English/Vietnamese/Korean;
- light/dark và high contrast nếu harness hiện có;
- long deck name, filename, column header, Front/Back và failure reason;
- keyboard-open paste and focus traversal.

Fail và auto-fix nếu:

- overflow, clipping, accidental ellipsis of required decision copy;
- shared edges lệch hoặc width hụt;
- option/action target <48;
- footer biến mất sau keyboard;
- focus order không theo visible order;
- stepper/status/selection chỉ dựa màu;
- screen reader mất step/state/action name;
- disabled/loading action trông armed;
- footer action labels mất nghĩa khi wrap/stack.

Không chữa bằng giảm font, local breakpoint magic hoặc per-screen raw color.

## Golden và gallery discipline

Regenerate bằng:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Sau update:

1. Inspect từng changed `card_import_*.png`.
2. Chạy fresh golden comparison.
3. Stress goldens khác 393×852 không thêm vào gallery canonical.
4. Build/publish lại đúng existing Artifact URL trong `CLAUDE.md`.
5. Trả URL cho owner confirm trước khi PR được gọi ready.

## Recursive auto-fix loop

Với mỗi finding:

1. Ghi state/theme/viewport/file và screenshot/rect evidence.
2. Xác định owner: shell, shared primitive, import section hay item.
3. Sửa ở owner thấp nhất; không nudge từng state nếu shared geometry sai.
4. Chạy targeted test + relevant golden.
5. Re-render mọi state dùng owner đó để bắt degradation dây chuyền.
6. Lặp đến hai full sweeps liên tiếp không có unapproved delta.

Nếu fix cần đổi business behavior/copy/visibility, dừng và xin owner decision.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Coordinator chạy full gate sau khi áp UI fixes. UI reviewer chỉ trả clean khi:

- visual grammar kế thừa Card Detail có evidence theo region;
- đủ render matrix của wizard/outcomes;
- no gutter/width/baseline/footer/keyboard regression;
- responsive/localization/accessibility sạch;
- every golden delta được phân loại và fresh comparison xanh;
- existing gallery URL được cập nhật;
- report liệt kê auto-fix và approved divergence cụ thể, không blanket pass.
