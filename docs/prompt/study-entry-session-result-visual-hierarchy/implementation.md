# Study Entry and Session Result visual hierarchy

| | |
|---|---|
| **Status** | active |
| **Purpose** | Đồng bộ Study Entry và Session Result với visual language hiện tại mà không đổi lifecycle hoặc scheduler behavior |
| **Scope** | `StudyEntryScreen`, session summary/result surface, entry/options/resume/finish actions và các state liên quan |
| **Source of truth for** | Hướng dẫn presentation restyle; nghiệp vụ Study vẫn thuộc `docs/wbs-study.md`, BR/UC và scheduler contracts |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `docs/wireframes/m5-study-home.md`, `docs/wireframes/m5-study-modes.md`, `docs/wbs-study.md`, relevant BR/UC |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Chỉ thay semantic layout, hierarchy, surfaces, typography và feedback presentation.
Không đổi workload count, stage order, answer actions, direction, resume/end reason,
review/history commit hoặc eight-box/SM-2 scheduling.

## 5Why

Viết 5Why từ production renders: điểm nào chưa nối trực quan từ workload → action →
session outcome; shared pattern nào tái sử dụng được; state nào dễ bị restyle làm mất;
vì sao scheduler parity là constraint; tests/golden nào sẽ chứng minh không regression.

## Layout và behavior contract

- Study Entry phải đọc theo thứ tự deck/context → due/new workload → mode/options →
  Start/Resume. Một interaction region chỉ có một strong primary CTA.
- Session Result phải đọc theo thứ tự completion/end reason → remembered/forgotten hoặc
  scheduler-specific metrics → next actions. Không gán nhãn “correct/incorrect” nếu
  stored action không có semantics đó.
- Dùng `MxCard`, `MxActionButton`, token/type scale hiện có; không raw styles/widgets,
  không thay global font, không tạo card-shadow stack.
- State loading, blocked, empty/no due, resumable, submitting, completed, abandoned,
  stale generation và failure giữ copy/action canonical.
- Back/cancel/double tap không được tạo thêm session hoặc ghi answer hai lần.

## Verification và delivery

Thêm production widget/geometry tests tại 320@2.0, 393, 412; light/dark, EN/VI;
eight-box và SM-2; short/long deck name; zero/mixed workload; resume/result variants.
Pin shared edges, CTA baseline, safe area và no overflow bằng `getRect`; test semantics,
focus và tap targets.

Worktree sạch từ `origin/main`; không sửa scheduler/domain trừ khi finding chứng minh bug
ngoài scope thì dừng báo. Changed gate trong loop, full gate cuối. Presentation-only:
không emulator, ghi rõ. Regenerate goldens `TZ=UTC`, publish gallery URL cũ, commit/push,
mở non-draft PR và không merge.

Clean stop khi cả hai scheduler giữ behavior, mọi state có evidence, full gate/golden
xanh, không P0/P1/P2 và owner có gallery để xác nhận.
