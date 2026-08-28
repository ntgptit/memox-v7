# Recursive Architecture and Logic Review — Strict Widget Boundary

| | |
|---|---|
| **Status** | active |
| **Purpose** | Độc lập phá thử strict classifier/admission guard, auto-fix bypass và xác nhận không còn migration escape hatch |
| **Scope** | Strict guard, registry, shared admission, CI/local parity, docs và final raw-widget inventory |
| **Source of truth for** | Hướng dẫn recursive architecture/logic audit strict boundary; AD accepted vẫn là source of truth |
| **Depends on** | `docs/prompt/design-system-widget-boundary-enforcement/implementation.md`, merged foundation/migration, latest guard/tests/docs |
| **Updated by task** | Design-system widget boundary prompt set |
| **Last updated** | 2026-08-27 |

---

Review như adversarial maintainer. Không tin “0 findings” trước khi chứng minh
scanner thấy đủ target và fault injection làm nó đỏ.

## Audit-only first pass

Vòng đầu là **audit-only**: không sửa guard, registry, tests hoặc docs. Thu raw
inventory, chạy bypass probes và ghi finding trước khi auto-fix.

## Recursive audit

Lặp inventory → fault injection → root-cause fix → targeted/changed gate →
re-read latest tree cho tới sạch.

Tìm và auto-fix:

- baseline/ignore/disable flag còn sót;
- registry wildcard hoặc disposition chung chung;
- alias/named/generic/top-level call bypass;
- owner-library resolution fallback về tên text;
- generated/test/shared/app scope nhầm hoặc feature scope bỏ sót;
- new Material/Cupertino symbol được phép vì chưa có trong hard-coded list;
- `themeOwnedRaw` có local style override hoặc thiếu ThemeData states;
- Mx entry khai policy nhưng evidence không kiểm policy đó;
- trivial wrapper forward raw style API;
- rule port từ ruleset cũ dùng path v4 nên scan 0 file;
- local/CI strict mode khác nhau;
- docs/WBS counts khác resolved inventory.

Strict tooling MUST NOT thay đổi persistence, database, query, mutation hoặc
failure handling. Bất kỳ dependency path nào mới từ UI tới repository là scope
leak và phải auto-fix về kiến trúc trước đó.

Fault inject đầy đủ matrix implementation prompt và một probe cố tình đổi tên
import alias. Mọi probe phải fail đúng diagnostic, không chỉ exit 1 vì lỗi khác.

Chạy full gate cuối, không emulator. Chỉ clean khi zero baseline, zero raw
`mxRequired`/Cupertino, all targets non-zero, admission evidence thật và CI/local
parity. Không dùng ignore, severity downgrade hoặc test deletion.

## Clean stop

Clean stop chỉ đạt sau một recursive rerun hoàn chỉnh không còn finding, toàn bộ
fault probe đỏ đúng rule, valid probe xanh và full gate pass trên latest tree.
