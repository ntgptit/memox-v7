# Recursive UI/UX review — Card Export

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập kiểm toán và auto-fix UI/UX, responsiveness, accessibility và visual fidelity của Card Export |
| **Scope** | Production Card List, selection entry và Card Export overlay; không kiểm toán persistence/algorithm ngoài tác động UI |
| **Source of truth for** | Prompt recursive UI/UX review Card Export |
| **Depends on** | `docs/prompt/card-export/implementation.md`, wireframe Card Export, MemoX design tokens và behavior contract |
| **Updated by task** | User-requested prompt workflow update |
| **Last updated** | 2026-08-13 |

---

Hãy recursive UI/UX review và auto-fix Card Export trong
`D:\workspace\memox-v7`. Logic tests xanh và golden mới sinh không phải bằng
chứng visual parity.

## Chế độ chạy dưới coordinator

Nếu coordinator chạy prompt này song song với Architecture/Logic reviewer, lượt
đầu tiên là **audit-only**:

- render/inspect production states và lập findings;
- được chạy read-only diagnostics, screenshots và tests không cập nhật baseline;
- không sửa file, không format, không accept/regenerate golden;
- gửi state-by-state findings, geometry mismatches và reproduction cho
  coordinator rồi pause.

Chỉ auto-fix khi coordinator gửi follow-up sau khi Architecture/Logic reviewer
đã hoàn tất fixes và targeted verification. Trước khi sửa, đọc lại latest
worktree, controllers, states, copy và widget tree; findings cũ phải được xác
nhận lại vì logic fixes có thể đã thay đổi UI. Nếu không chạy dưới coordinator
hoặc không có reviewer song song, thực hiện toàn bộ audit → auto-fix loop bình
thường.

## Worktree và source of truth

- Đọc `CLAUDE.md`, `AGENTS.md`, design-system skill, wireframe Card Export,
  `m4-11-card-management.md`, MemoX tokens/Mx components và UC/BR Export.
- Kiểm tra `git status`/diff; không ghi đè thay đổi ngoài scope.
- Mount production CardListScreen, selection bar và export overlay; không dùng
  replica/demo thay production làm bằng chứng.

## State matrix phải render

1. Card List bình thường với Export trong overflow.
2. Selection mode có N card với Export selected.
3. Sheet CSV selected/Recommended.
4. TSV selected.
5. XLSX selected.
6. Generating/encoding.
7. Platform/share unavailable.
8. Repository/encoder failure với Retry.
9. User dismiss share sheet.
10. Empty deck không có action Export.
11. Long deck name/count lớn.
12. EN/VI, light/dark.
13. 320dp @ text scale 2.0.
14. 390dp và 412dp bình thường.

## Geometry contract

Trước review, ghi rõ content gutters, alignment groups, shared edges,
format-option width/height, grid gaps, stack threshold, icon/title/subtitle/check
alignment, section rhythm, sticky action/safe area và touch targets.

Dùng `tester.getRect` trên production tree để pin:

- format row bắt đầu/kết thúc đúng content column;
- options bằng width/height khi cùng hàng;
- options stack full-width ở 320dp/large text;
- scope summary/info/action area chung alignment group;
- không có parent full-width nhưng children intrinsic-width như lỗi Card Import;
- action không bị bottom inset che.

Không tạo static guard cấm `Wrap`; chỉ enforce geometry wireframe tuyên bố.

## Recursive loop

Với từng state:

1. Render production state tại viewport yêu cầu.
2. So state-by-state với wireframe và visual language hiện có.
3. Kiểm hierarchy, copy, visual weight, grouping, whitespace, alignment,
   interaction affordance, feedback, responsive behavior, semantics/focus/touch.
4. Ghi mismatch với file/line/state.
5. Auto-fix mismatch chưa được phê duyệt.
6. Chạy widget test, geometry test và visual audit.
7. Render lại và lặp đến một pass sạch.

## Golden rule

- Golden mới chỉ là regression baseline.
- Không regenerate rồi dùng chính nó làm bằng chứng parity.
- Phải side-by-side/overlay với wireframe và ghi approved divergences.
- Không tự phát minh generic Material sheet nếu repo đã có visual language.

## UX checks

- Scope All/Selected luôn rõ, không có dropdown đổi ngầm.
- CSV Recommended nhưng TSV/XLSX vẫn enabled.
- Copy nói rõ content/tags có trong file và progress/history không có.
- Primary chứa đúng N.
- Generating khóa double submit; Cancel/Back rõ ràng.
- Dismiss share không báo error; error giữ scope/format để Retry.
- Không nói Saved nếu OS không xác nhận.
- Selection không biến mất sau export.
- Không dùng màu làm tín hiệu duy nhất.
- Icon có semantic label; touch target ≥48dp.
- Count/format không ellipsis mất nghĩa ở 200% scale.
- Light/dark đủ contrast; không hardcode color/spacing/type/radius/duration.

## Verification

Chạy targeted Export widget/geometry/Card List/selection tests, production
visual audit, approved goldens và
`.claude/skills/flutter-workflow/scripts/dod_check.sh`.

Manual device smoke: normal/selected entry, từng format, Android share sheet,
dismiss, share Files/Drive và quay lại app kiểm state/selection.

## Clean stop và báo cáo

Chỉ dừng khi toàn state matrix đã render, không còn mismatch chưa phê duyệt,
geometry xanh ở 320/390/412dp, EN/VI/light/dark/2.0x không overflow, golden đã
đối chiếu reference và vòng cuối không sinh finding mới.

Báo cáo bảng:

| State | Rendered | Compared | Auto-fixed | Remaining approved divergence |
|---|---:|---:|---:|---|

Sau bảng liệt kê tests/gates, screenshots/goldens và device steps chưa chạy.
