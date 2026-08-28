# Recursive Architecture and Logic Review — Policy Widget Migration

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit migration raw policy widgets về đúng Mx/shared boundary mà không đổi business behavior hoặc tạo trivial wrappers |
| **Scope** | Resolved inventory, feature call-sites, shared APIs, registry/baseline, behavior tests và dependency boundaries |
| **Source of truth for** | Hướng dẫn recursive architecture/logic audit migration; nghiệp vụ vẫn thuộc BR/UC và AD đã accepted |
| **Depends on** | `docs/prompt/design-system-widget-migration/implementation.md`, foundation AD/guard/registry, latest worktree và affected feature contracts |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là independent reviewer. Ba implementation workstream đã có thể thay đổi
cùng worktree; re-read mọi file ở HEAD hiện tại trước review. Chỉ audit song song;
mọi auto-fix áp tuần tự sau khi tổng hợp finding.

## Audit-only first pass

Vòng đầu là **audit-only**: không sửa source, test, registry hoặc baseline. Trace
toàn bộ event/callback và lập finding report trước; chỉ sau đó mới apply auto-fix
tuần tự trên latest tree.

## Recursive loop

1. Chạy resolved inventory và so với baseline trước migration.
2. Trace từng migrated control từ user event tới callback/controller; tái hiện
   ít nhất một main và một cancel/error/disabled state.
3. Review shared API ownership và tìm wrapper rename/forward.
4. Auto-fix architecture/logic findings trước.
5. Chạy changed gate, re-read latest tree và lặp tới sạch.

## Findings bắt buộc tìm

- Raw `mxRequired` còn sót qua alias/named/generic/function call.
- Baseline bị tăng, broad allow hoặc xóa entry trong khi raw call còn đó.
- `themeOwnedRaw` bị lạm dụng cho control có local style/state/semantics.
- Mx wrapper expose raw `ButtonStyle`, `InputDecoration`, `Color`, `TextStyle`,
  radius/padding/elevation thay vì semantic variant.
- Wrapper chỉ rename và forward mà không sở hữu policy/evidence.
- Feature composition/domain model/provider bị đẩy vào shared.
- Callback, enablement, focus, controller lifecycle, menu result, dialog cancel,
  picker cancel hoặc snackbar undo thay đổi.
- Loading indicator migration làm mất cancel/double-submit/repaint isolation.
- Ink/surface migration làm parent tap ăn nested action hoặc mất keyboard/focus.
- Tests chỉ đổi finder cho xanh mà không assert observable behavior.
- Registry, stress suite, Widgetbook và golden coverage không đồng bộ.

Migration presentation MUST NOT đổi persistence, database, query, mutation hoặc
failure handling. Nếu callback mới bypass controller/use case hay chạm repository,
đó là architecture regression phải auto-fix về dependency path cũ.

## Fault injection

Thêm fixture tạm cho một raw call mới trong mỗi family và chứng minh guard fail.
Trong production tests, chủ động thử disabled action, picker cancel, menu dismiss,
nested trailing control và focus keyboard activation. Xoá probe sau khi chứng minh.

## Verification và clean stop

Chạy targeted/changed gate trong loop và full gate ở cuối. Không chạy emulator vì
không có device-only flow mới. Chỉ clean khi raw debt đúng bằng registry kỳ vọng,
business behavior không đổi, shared APIs có policy thật, full gate xanh. Auto-fix
phải được commit và report theo root cause; cấm ignore/nới rule/xóa test.
