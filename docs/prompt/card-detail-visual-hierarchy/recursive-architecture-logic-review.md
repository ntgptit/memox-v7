# Recursive Architecture and Logic Review — Card Detail Compact History

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và tự sửa mọi regression nghiệp vụ, state, dependency, persistence hoặc semantics sau khi đổi Card Detail theo concept mới |
| **Scope** | Diff Card Detail compact history, typed shared-button variant, presentation mapping, docs và tests liên quan; không thiết kế lại feature khác |
| **Source of truth for** | Quy trình recursive architecture/logic review cho Card Detail compact history layout |
| **Depends on** | `docs/prompt/card-detail-visual-hierarchy/implementation.md`, BR-239…BR-246, UC-19, wireframe M4.15 |
| **Updated by task** | Card Detail compact history layout prompt |
| **Last updated** | 2026-08-26 |

---

Chạy trên latest worktree sau implementation. Đọc lại đầy đủ `CLAUDE.md`,
`docs/document-conventions.md`, implementation prompt, BR-239…BR-246, UC-19,
wireframe M4.15, code hiện tại và **latest diff**. Không dựa vào báo cáo phase
trước. Prompt/ảnh ở source worktree là read-only; mọi test/fix ở target worktree.

## Cách chạy recursive review

### Pass A — `AUDIT_ONLY`

Trong lượt subagent song song đầu tiên, chỉ tái hiện và trả findings cho
coordinator; không sửa shared worktree. Mỗi finding phải có severity, scenario,
expected/actual, file:line và test/bằng chứng tái hiện. Không ghi `pass` chỉ vì
analyzer hoặc golden xanh.

### Pass B — `APPLY_FIXES`

Sau khi coordinator nhận cả architecture và UI audit, áp dụng fixes **tuần tự**:
architecture/logic trước. Với mỗi finding P0 → P1 → P2:

1. thêm/sửa test để tái hiện failure;
2. sửa nhỏ nhất tại layer sở hữu;
3. chạy targeted/changed verification;
4. đọc lại latest tree;
5. audit lại toàn scope, không chỉ dòng vừa sửa.

Lặp đến khi một pass mới từ đầu không còn P0/P1/P2. Không commit/push/PR trong
review phase; coordinator delivery sau cùng.

## Audit matrix bắt buộc

### 1. Read-only và data integrity

- Mở, scroll, load-more, render segment, đổi màu, semantics và relative time
  MUST không ghi card, `updated_at`, content type, study state, history, session,
  flag hoặc tag; không đánh dấu learned và không tạo review (BR-239).
- Không thêm mutation method vào Card Detail repository/controller/use case.
- Không đổi SQL, DAO, query count, keyset ordering hoặc page size 50 chỉ để phục
  vụ layout.

### 2. Đủ dữ liệu BR-240

Chứng minh trên production tree:

- Front/Back đầy đủ, không ellipsis/clamp.
- Example/Hint/Pronunciation chỉ hiện khi non-null.
- Flag và tags không mất, không thành editable/actionable.
- Display state, Due, Learned, Last answered, Reviews, Lapses luôn theo contract.
- Eight-box chỉ có current Box và 8-segment representation; SM-2 chỉ có Ease,
  Interval, Repetitions. Không field của scheduler kia bị leak.
- Không thêm `Since added`, recall rate, accuracy, streak, score hoặc history
  total dưới danh nghĩa “derived display value”.

### 3. Scheduler mapping

- Eight-box max-box không là literal rải rác; lấy từ owner hiện có hoặc một
  named presentation constant có test gắn với scheduler contract.
- Segment state chỉ ánh xạ `currentBox`; không mutate state và không suy lịch.
- SM-2 không bị ép vào Box UI. Unknown/future scheduler value fail visibly hoặc
  theo typed exhaustive switch; không âm thầm mặc định Eight-box.
- Presentation metadata có kiểu; không match localized label/substrings để chọn
  icon, tone, numeric format hoặc scheduler row.

### 4. History truthfulness

- History vẫn `answered_at DESC, id DESC`, keyset, đúng card và không N+1
  (BR-241).
- Event dùng stored `mode`, `kind`, `action`, `outcomeReason`, `usedHint`,
  scheduler type/generation và before/after fields (BR-242).
- Tone lấy trực tiếp từ stored `StudyAction`; không infer correct/forgot/recovered
  từ box/ease/interval delta.
- Learning turn không đổi lịch vẫn có canonical no-change copy; không bị event
  card bỏ mất vì không có transition.
- Generation heading còn nguyên, kể cả generation cũ sau reset. Không màu-only
  grouping và không aggregate vi phạm BR-243.
- Empty, load-more, loading-more, page-error, retry, complete và stale-result
  behavior giữ nguyên BR-241/BR-244.

### 5. Navigation và state lifecycle

- Tap từ card list vẫn mở detail; multi-select vẫn toggle, không điều hướng.
- Edit tonal action dùng callback hiện có và `pushNamed`, Save/Back quay đúng
  detail/list context (BR-246).
- Edit chỉ hiện với `AsyncData<CardDetailModel>`; top-level error/not-found không
  giữ stale action.
- Back/system gesture không reset filter/search/sort/window/selection của list.
- Không thêm breadcrumb/filter control hoặc route/state giả để giống concept.

### 6. Shared component safety

Nếu implementation thêm `MxActionButtonVariant.tonal`:

- API là typed enum, dùng `buildFilledTonalStyle`; không raw `Color?`, arbitrary
  `ButtonStyle?`, local Theme hoặc raw Material call trong feature.
- Primary/secondary/destructive, loading, disabled, semantics và focus behavior
  cũ giữ nguyên. Tonal có enabled/pressed/hovered/focused/disabled states đúng.
- Minimum touch target, visible label, icon/label state color và variable-font
  weight đúng shared contract.
- Shared component tests và catalog có variant mới; không drive-by repaint call
  site khác.

### 7. Boundary, localization và privacy

- Presentation không import data/app; domain không import Flutter; không widget
  đọc repository/DB.
- Không business logic trong widget `build`; typed mapping nằm presentation
  support/domain đúng trách nhiệm hiện có.
- Không hardcode user-visible string, raw color, font size, radius, spacing,
  duration hoặc route.
- Nếu thêm ARB key, đủ EN/VI + description, không lặp key có sẵn.
- Không log Front/Back/optional fields/history ở bất kỳ level nào.

### 8. Docs parity

- M4.15 append quyết định mới, không xoá lịch sử V1…V12.
- W2/W4/G contract mô tả production tree mới nhưng không thay BR/UC.
- Approved divergences với concept được ghi rõ; breadcrumb/filter/aggregate không
  vô tình xuất hiện như planned behavior.
- WBS chỉ nói việc đã có bằng chứng; emulator ghi `not run`, không ghi pass.

## Negative scenarios phải tái hiện

1. Eight-box Box 1 và Box 8.
2. SM-2 có/không đủ optional numeric fields.
3. Card mới chưa learned/answered và history empty.
4. Long multilingual content + 10 tags + flag.
5. Remembered, forgotten, again, hard, good, easy và learning no-change.
6. Reset tạo nhiều scheduler generation.
7. Page 2 thất bại rồi retry; stale page result tới muộn.
8. Card bị xoá khi detail đang mở.
9. Edit action trên loaded rồi detail chuyển sang error/not-found.

## Verification và clean stop

Inner loop:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Nếu shared component hoặc cross-feature consumer bị sửa, chạy targeted tests của
mọi reverse consumer mà changed planner chọn. Không chạy emulator trong task UI
này; báo `not run — presentation-only restyle`.

Clean stop chỉ khi:

- một audit mới không còn P0/P1/P2;
- mọi negative scenario có test/bằng chứng;
- changed gate xanh;
- không mutation, query, scheduler, paging, navigation, semantics hoặc docs drift;
- không aggregate/filter/breadcrumb giả;
- findings/fixes/remaining risk được trả riêng, không blanket `pass`.
