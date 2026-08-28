# Deck create, edit and move UX hardening

| | |
|---|---|
| **Status** | active |
| **Purpose** | Làm rõ và hoàn thiện các form/sheet tạo, sửa, chuyển deck mà giữ nguyên invariant cây và scheduler |
| **Scope** | Root/sub-deck create, rename, kind choice, move picker, scheduler change/reset prompts và failure states liên quan |
| **Source of truth for** | Hướng dẫn triển khai UX hardening; deck business rules vẫn thuộc BR-55/59/61/66/163 và scheduler/move rules canonical |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, `lib/features/deck/README.md`, relevant BR/AD/UC, current deck wireframes/goldens |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

## 5Why

Trước sửa, trace từng entry point và viết 5Why: form/sheet nào thiếu hierarchy hoặc
feedback; invariant nào có nguy cơ bị UI diễn đạt sai; vì sao validation vẫn thuộc value
object/repository transaction; shared overlay/action pattern nào dùng được; evidence nào
chứng minh không regress.

## Nghiệp vụ đóng băng

- Root chỉ tạo deck; sub-deck `unset` cho chọn card/deck; typed deck chỉ cho loại tương ứng.
- Depth tối đa, descendant/cycle, target content type, root scheduler/generation compatibility
  và reset-to-unset sau move last child phải do transaction/repository enforce.
- Scheduler root khóa sau first scheduled review; change/reset copy phải phản ánh đúng impact.
- Rename/move/delete failure không được làm mất form input hoặc mutate một phần.

## UX contract

- Dùng shared sheet/dialog/form field/button; không raw policy widget, hardcoded token hoặc
  wrapper mới nếu component hiện có đáp ứng.
- Title/context, field/validation, impact message và action bar có hierarchy rõ. Primary
  action disabled khi invalid/unchanged/submitting; cancel/back nhất quán.
- Move picker phân biệt current, descendant, incompatible, unavailable và empty target;
  disabled reason bằng text/semantics, không chỉ màu.
- Loading không làm action bar nhảy; destructive/reset action không ngang cấp primary edit.
- Back/gesture khi dirty phải theo behavior canonical đang có; không tự thêm guard mới nếu
  docs chưa chốt.

## Tests, verification và delivery

Pin main/alternative/error flows, repository failures, double submit, target stale, move
last child, scheduler mismatch và generation stale. Render root create, child kind, rename,
move loaded/empty/error/disabled, scheduler change/reset ở light/dark EN/VI, 320@2.0/393/412.
Thêm `getRect`, semantics và tap-target assertions.

Worktree sạch; docs thắng code. Nếu phát hiện business drift, auto-fix chỉ khi canonical
unambiguous; nếu không dừng hỏi owner. Changed gate rồi full gate. Chỉ chạy emulator nếu
logic/route/device contract thực sự đổi và `CLAUDE.md` bắt buộc; UI-only ghi not run.
Regenerate goldens `TZ=UTC`, publish gallery URL cũ, commit/push, tạo non-draft PR, không merge.

Clean stop khi invariant tests thật xanh, UX state matrix sạch, full gate xanh và không
còn P0/P1/P2.
