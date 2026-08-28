# Recursive Architecture and Logic Review — Widget Boundary Foundation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập kiểm tra resolved-AST classifier, ratchet, admission registry và gate wiring của design-system boundary foundation rồi auto-fix tới khi sạch |
| **Scope** | Architecture decision, tool/registry/baseline, tooling tests, local/CI gate parity và no-production-change invariant |
| **Source of truth for** | Hướng dẫn audit foundation; quyết định chính thức vẫn thuộc AD mới và contract hiện hành của repo |
| **Depends on** | `docs/prompt/design-system-widget-boundary-foundation/implementation.md`, `CLAUDE.md`, AD-14, `.claude/skills/flutter-design-system/SKILL.md`, guard scripts và diff mới nhất |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Bạn là reviewer độc lập. Re-read worktree mới nhất sau implementation; không tin
report hoặc test mới chỉ vì chúng xanh. Review này là audit + auto-fix, không chỉ
viết nhận xét.

## Audit-only first pass

Vòng đầu là **audit-only**: không sửa file, không update registry/baseline và
không đổi test. Chỉ lập inventory, chạy fault probes và ghi finding có bằng
chứng. Chỉ bước sang auto-fix sau khi first-pass report đã hoàn chỉnh.

## Audit loop

Lặp tới khi không còn finding in-scope:

1. inventory diff và chạy scanner trên production tree;
2. tái tạo một failure cụ thể cho mỗi lớp finding;
3. sửa nguyên nhân nhỏ nhất đúng owner;
4. chạy targeted tooling tests và changed gate;
5. re-read toàn bộ file vừa đổi rồi quét lại từ đầu.

## Những điều phải chứng minh

- Classifier dùng resolved elements thật, không fallback regex khi resolution
  fail.
- Alias, named constructor, generic và top-level function đều có fixture đỏ.
- Local symbol/comment/string/import-only không false-positive.
- Scope chỉ là handwritten feature presentation, nhưng target count không thể về
  0 mà pass.
- Unknown Material/Cupertino symbol fail; base widget không bị coi là Material
  chỉ vì import qua barrel `material.dart`.
- Registry disposition đóng, có rationale, shared owner và forbidden visual args
  khi cần.
- Baseline là exact ratchet, không wildcard, không tăng nợ, không stale, không
  che `themeOwnedRaw`, không chứa Cupertino vô cớ.
- Shared admission entry không thể pass với `owns: []`, evidence giả hoặc path
  không tồn tại.
- Heuristic trivial-wrapper không được biến thành regex blocker đầy false
  positive; reviewer phải mở các Mx wrapper đáng ngờ và xác nhận policy thật.
- `dod_check.sh --changed`, full gate và CI gọi cùng guard/config, không có một
  đường local lỏng hơn CI.
- Planner chọn static/tool tests khi tool/registry/guard thay đổi.
- AD không chép danh sách symbol dễ stale; registry mới là machine contract.
- `docs/wbs.md` phản ánh đúng foundation, migration và enforcement còn lại.
- `lib/features/**`, `lib/shared/widgets/**`, `lib/core/theme/**` không có visual
  implementation change trong foundation diff.

## Fault injection bắt buộc

Chủ động thử tối thiểu:

- `m.FilledButton.icon`, `SegmentedButton<Enum>`, `showTimePicker`;
- `CupertinoButton`;
- một Material symbol chưa đăng ký;
- một theme-owned symbol có visual override bị cấm;
- một local class trùng tên Material;
- baseline count tăng và baseline stale;
- Mx entry thiếu policy/evidence;
- path separator Windows và POSIX;
- scanner root sai hoặc resolution diagnostic.

Mỗi probe phải fail đúng rule và message; probe hợp lệ tương ứng phải pass.

## Verification

Chạy targeted tests trong inner loop qua changed gate, rồi full
`.claude/skills/flutter-workflow/scripts/dod_check.sh` ở cuối. Không chạy emulator
vì không đổi app runtime.

## Clean stop

Chỉ báo clean khi không còn finding, mọi fault injection đúng hai chiều, full
gate xanh và diff không đổi production UI. Nếu tự sửa, commit cùng branch và ghi
rõ root cause + test khoá regression; không dùng ignore, broad allowlist hoặc nới
severity để pass.
