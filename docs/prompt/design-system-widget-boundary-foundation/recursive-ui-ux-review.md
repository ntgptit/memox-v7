# Recursive UI/UX Review — Widget Boundary Foundation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Xác nhận foundation guard không tạo visual delta, không ép wrapper noise và policy phân loại vẫn bảo vệ design-system semantics |
| **Scope** | No-visual-delta audit, Level A/B/C classification, shared-component admission và gallery decision |
| **Source of truth for** | Hướng dẫn UI/UX audit foundation; visual contract vẫn thuộc MemoX tokens, shared components, wireframes và approved gallery |
| **Depends on** | `docs/prompt/design-system-widget-boundary-foundation/implementation.md`, AD-14, design parity checklist, shared-widget catalog/tests và production diff |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Đây là UI/UX review độc lập cho một tooling-only phase. Không tạo screenshot mới
để giả vờ có visual evidence khi production tree không đổi.

## Audit-only first pass

Vòng đầu là **audit-only**: chưa sửa code/golden/registry. Inventory mọi render
file trong diff, xác nhận production tree không đổi và ghi approved divergence /
unapproved divergence bằng chứng trước khi auto-fix.

## Review loop

1. Re-read latest diff và liệt kê mọi file có thể ảnh hưởng render.
2. Nếu có production UI/theme/shared implementation change, coi đó là scope
   leak; tái hiện visual effect, auto-fix bằng cách đưa migration sang phase sau.
3. Đối chiếu registry classification với component policy thật, không với tên
   class.
4. Sửa classification/admission sai rồi chạy lại tests và gate.
5. Lặp tới khi no visual delta và không còn wrapper-noise incentive.

## UX assertions

- Layout/render primitives không bị buộc qua `Mx*` và không có đề xuất
  `MxRow`/`MxPadding`.
- `Text`, `Icon`, `Image`, `Container` vẫn dùng trực tiếp; token guard bảo vệ
  decision source thay vì cấm primitive.
- `themeOwnedRaw` chỉ dành cho control mà app theme đã sở hữu visual states và
  feature không override; nếu component cần app-specific behavior/a11y/variant,
  classification phải là `mxRequired`.
- Raw Cupertino không được lọt vào Android-first feature UI.
- Admission registry nêu policy observable: states, semantics, geometry,
  variants, behavior hoặc theme mapping; câu “wraps Material widget” không đủ.
- Không component/golden/Widgetbook production specimen bị đổi trong foundation.

Không có concept image cho phase này. Geometry contract là **no delta**: mọi
production rect, shared component state và golden phải giữ nguyên. Nếu một golden
thay đổi, điều tra root cause; không update baseline để làm xanh.

Nếu production state bị chạm ngoài dự kiến, thêm `tester.getRect(...)` assertions
cho shared edges, widths và baselines đã có; no-delta phase không được bỏ qua
`getRect` chỉ vì không có concept mới.

## Verification và delivery

Chạy changed gate sau auto-fix và full gate cuối. Gallery được **intentionally not
regenerated** nếu no visual delta; PR phải dẫn existing Artifact URL và nói rõ
lý do. Nếu phát hiện visual delta cần thiết, dừng và chuyển nó sang migration
prompt thay vì âm thầm duyệt.

## Clean stop

Chỉ clean khi diff tooling/docs-only, classification hợp lý theo policy ownership,
không wrapper noise, không golden drift và full gate xanh.
