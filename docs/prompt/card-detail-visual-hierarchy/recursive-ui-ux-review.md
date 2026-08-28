# Recursive UI/UX Review — Card Detail Compact History

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa triệt để fidelity, hierarchy, density, geometry, responsive và accessibility của Card Detail theo concept đã duyệt |
| **Scope** | Production Card Detail ở mọi state, tonal Edit action, widget catalog, geometry tests, visual audit, goldens và gallery |
| **Source of truth for** | Quy trình recursive UI/UX review cho Card Detail compact history layout |
| **Depends on** | `docs/prompt/card-detail-visual-hierarchy/implementation.md`, concept ảnh owner, wireframe M4.15, MemoX design tokens và production Card Detail |
| **Updated by task** | Card Detail compact history layout prompt |
| **Last updated** | 2026-08-26 |

---

Chạy trên latest worktree **sau khi architecture/logic fixes đã được áp dụng**.
Đọc lại `CLAUDE.md`, implementation prompt, M4.15, theme/shared widgets, current
goldens/tests và latest diff. Mở concept bằng công cụ xem ảnh:

`D:/workspace/memox-v7/.codex-remote-attachments/019fe924-47e4-7741-9143-21cc8a21ddc9/9283098c-8784-4613-90c6-28c1edc3adfa/1-Photo-1.jpg`

Chỉ UI trong khung điện thoại là reference. Editor chrome, carousel, frame số và
viền thiết bị không thuộc app.

## Cách chạy recursive review

### Pass A — `AUDIT_ONLY`

Subagent UI chạy độc lập song song với architecture audit, chỉ render/đo/so sánh
và trả findings; không sửa shared worktree. Mỗi finding phải có severity,
viewport/state/theme/locale, expected/actual, screenshot hoặc `getRect` evidence,
file:line và proposed smallest fix.

### Pass B — `APPLY_FIXES`

Sau architecture fixes, đọc lại latest tree rồi áp dụng UI fixes tuần tự. Với
mỗi P0 → P1 → P2:

1. thêm geometry/widget test hoặc state render tái hiện;
2. sửa nhỏ nhất bằng token/shared API;
3. render lại đúng state;
4. so lại concept và các approved divergences;
5. chạy changed verification;
6. audit lại toàn màn từ đầu.

Không update golden để “làm xanh” trước khi comparison pass. Không commit/push/PR
trong review phase; coordinator delivery sau cùng.

## Approved differences — không được báo lại thành bug

- Giữ canonical title, không bắt buộc `Card history`.
- Không breadcrumb vì read model không có deck path.
- Không Recall rate, Correct streak, score, accuracy, event total hoặc Since
  added nếu canonical contract chưa có.
- Không `All events` filter/chevron.
- Eight-box là `/8`; SM-2 không có Box segments.
- Event dùng stored vocabulary, không dùng taxonomy `Correct/Recovered` mới.
- Optional fields, flag, tags và generation headings vẫn hiện.
- Edit target tối thiểu 48dp dù visual fill có thể lớn hơn concept.

Mọi khác biệt khác phải được sửa hoặc xin owner duyệt; không thêm vào approved
list sau khi đã nhìn thấy implementation.

## Geometry contract cần đo

Đo trên production tree bằng `getRect`; số tuyệt đối chỉ dùng khi đã là token.
Contract chính là quan hệ:

1. Summary hero, current-progress card và mọi event card có cùng outer leading/
   trailing edges theo `mxScreenGutter(context)`.
2. App-bar title, body reading column và bottom safe area theo shared shell;
   tonal Edit không ép title ellipsis sớm ở 320dp.
3. Summary internal inset đồng nhất. Front là điểm nhấn lớn nhất nhưng chỉ ở
   `headlineSmall`; Back và metadata nhỏ hơn rõ một/rồi hai bậc.
4. Scheduler badge không overlap Front/Back; ở hẹp/large text nó wrap hoặc stack
   thành hàng mới với spacing token, không thu nhỏ font.
5. Eight-box có đúng 8 segment, equal width/equal gap. Current segment nổi hơn
   completed/future; first/last segment cùng mép progress track.
6. Metric grid có hai equal columns ở 390/412. Icon, label và value của các item
   cùng baseline/indent; row gaps đều. Ở 320@2.0 grid stack có trật tự đọc đúng.
7. `Study history` và generation heading thẳng với outer card edge, không tạo
   mép thứ ba.
8. Marker centre neo vào first-row band của event, connector liên tục qua các
   event cao khác nhau. Event card text edge bằng nhau.
9. Action badge và timestamp cùng top row; timestamp right-aligned nhưng không
   làm badge/copy overflow. Long locale wrap xuống có chủ đích.
10. Khoảng giữa event cùng generation nhỏ hơn khoảng ngăn generation. Tail nằm
    đúng slot và event cuối không dịch khi load-more → loading/error/complete.
11. Không content bị bottom navigation/safe area che.

Geometry tests phải chạy ít nhất ở 320×568 @2.0, 390×844 @1.0 và 412×915 @1.0;
EN + VI; light + dark ở các state đại diện.

## Typography review

Owner đã chấp thuận density nhỏ như concept. Điều đó có nghĩa dùng đúng scale
hiện có, không có nghĩa ép mọi text về một cỡ:

- section/metadata labels: `labelSmall` hoặc `bodySmall` (11–12sp);
- event/support copy: `bodySmall`/`bodyMedium` (12–14sp);
- metric values: `bodyMedium` w600;
- Back: 14–16sp tuỳ measured hierarchy;
- Front: `headlineSmall` 24sp;
- app-bar title theo shared theme 22sp/20sp compact.

Audit fail nếu feature dùng `cardPrompt` 30sp, raw `fontSize`, tự scale font theo
width, giảm global typography token, vô hiệu `textScaler`, hoặc dùng weight mà
không đồng bộ variable-font axis. Ở 320@2.0 được phép cao hơn và scroll nhiều
hơn; không được giảm text để nhét concept vào một viewport.

## Visual hierarchy và surfaces

### Summary hero

- Đọc ngay được Front → Back → scheduler/state → metadata.
- Hero là surface rõ nhưng không thành một card khổng lồ do optional fields tạo
  khoảng rỗng. Field null không để lại divider/gap.
- Flag/tag không nặng hơn Front/Back và không trông tappable nếu read-only.
- Long Korean/Vietnamese/English wrap tự nhiên, không ellipsis.

### Current progress

- Section label nhỏ, tracked, quiet; panel mới là grouping chính.
- Eight-box progress hiểu được cả khi grayscale: segment + `Box N / 8` bằng chữ.
- SM-2 nhìn có chủ đích, không giống panel bị mất thanh progress.
- Metric icon wells, labels và values có visual weight nhất quán; màu chỉ nhấn
  semantic state, không tô cả panel.
- Không density quá chật: touch target chỉ áp dụng control; read-only metric có
  thể compact nhưng line-height/spacing vẫn đọc được.

### Timeline

- Event cards tạo rhythm giống concept nhưng không làm màn thành “card trong
  card” hoặc shadow stack. Dùng flat event card nếu surface ladder yêu cầu.
- Positive/warning/negative action khác nhau bằng icon/label/tone, không chỉ màu.
- Timestamp quiet và right aligned; stored facts vẫn đọc trước decoration.
- Connector/dot đủ contrast để nhận biết cấu trúc. Nếu `borderSubtle` không đạt
  non-text contrast khi mang thông tin, dùng existing `borderControl`, không mint
  màu và không blanket allowance.
- Multiple-generation boundary phải rõ bằng heading + spacing.

## Interaction và accessibility

- Edit tonal action là button, không selected chip; label/icon/tooltip/semantics
  không lặp. Target đạt `androidTapTargetGuideline`.
- Summary/progress/event cards read-only không mang button/tap semantics.
- Mỗi event là một merged semantics node với spoken timestamp, mode, kind,
  action và schedule changes; visual arrows có spoken equivalent.
- Screen traversal order đúng thứ tự visible: app bar → summary → progress →
  history groups → tail.
- Color contrast: body/label text theo WCAG; semantic mark/border mang thông tin
  đạt non-text contrast. High-contrast theme không regress.
- Không horizontal scroll, clipped ink, off-screen focus hoặc overflow ở large
  text.

## State-by-state render matrix

Render bằng real `CardDetailScreen`, real production widgets và repository fake
ở boundary hiện có:

| Scheduler/state | Light | Dark | 320@2 VI | 390 | 412 |
|---|---:|---:|---:|---:|---:|
| Eight-box loaded + mixed actions | ✓ | ✓ | ✓ | ✓ | ✓ |
| SM-2 loaded | ✓ | ✓ | ✓ | ✓ | ✓ |
| Long content + optional + 10 tags + flag | ✓ | ✓ | ✓ | ✓ | ✓ |
| Multiple generations | ✓ | ✓ | — | ✓ | ✓ |
| No history | ✓ | ✓ | ✓ | ✓ | — |
| Load more / loading-more | ✓ | ✓ | — | ✓ | ✓ |
| Page error | ✓ | ✓ | ✓ | ✓ | — |
| Top-level error / not-found | ✓ | ✓ | ✓ | ✓ | — |

`—` chỉ tránh duplicate render; behavior vẫn phải có test.

## Concept comparison report

Trước khi cập nhật golden, lập bảng cho từng region:

| Region | Concept intent | Production evidence | Approved difference | Result |
|---|---|---|---|---|
| App bar | compact title + explicit Edit | screenshot + rect | canonical title, 48dp target | pass/fail |
| Hero | summary at a glance | screenshot + rect | full optional content retained | pass/fail |
| Progress | segmented + 2-column metrics | both scheduler renders | `/8`, SM-2 metric-only | pass/fail |
| Timeline | connected event cards | mixed action render | stored vocabulary, generation headings | pass/fail |
| Typography | compact 11–24 hierarchy | resolved TextStyles | accessibility scaling retained | pass/fail |

Không được dùng “trông gần giống” làm result. Fail phải có measured or visible
reason; pass phải trỏ tới render/geometry evidence.

## Verification, golden và clean stop

Trong loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Chỉ sau khi clean visual pass, coordinator mới chạy delivery:

```bash
TZ=UTC flutter test --tags golden --update-goldens
python .claude/skills/flutter-testing/scripts/build_screen_gallery.py
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Clean stop chỉ khi:

- audit mới từ đầu không còn P0/P1/P2;
- mọi unapproved concept divergence đã sửa;
- geometry contract và state matrix có evidence;
- light/dark, EN/VI, 320@2/390/412, both schedulers đều sạch;
- không overflow, clipped content, false affordance hoặc a11y regression;
- changed gate xanh;
- report liệt kê approved differences, fixes và remaining risk riêng rẽ.

Không chạy emulator trong review UI-only này; báo `not run — presentation-only
restyle`, không ghi pass.
