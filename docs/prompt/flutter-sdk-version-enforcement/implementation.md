# Flutter SDK version enforcement

| | |
|---|---|
| **Status** | active |
| **Purpose** | Làm local gate fail sớm khi Flutter SDK thực tế lệch `.fvmrc`, không làm prompt/docs-only verification chậm |
| **Scope** | `dod_check.sh`, verification plan/cache integration, tooling tests và WBS technical debt |
| **Source of truth for** | Hướng dẫn enforcement local Flutter version; `.fvmrc` và CI workflow vẫn là version sources |
| **Depends on** | `CLAUDE.md`, `.fvmrc`, verification impact planner, `test_ci_tooling.py`, CI workflows, WBS |
| **Updated by task** | Terra verification campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là implementation coordinator trên latest `origin/main`. Không thay Flutter version,
dependencies, app code hoặc CI runner version trong task này.

Tạo worktree/branch sạch, ghi baseline SHA và `git status`; không reset,
force-push hoặc sửa worktree của session khác. Sync latest main trước final gate
và PR.

## 5Why bắt buộc

1. CI pin `.fvmrc` nhưng local PATH có thể trỏ SDK khác mà không cảnh báo.
2. Analyze/test xanh trên SDK sai không phải evidence cho CI/release SDK.
3. Check chạy ở mọi prompt-only/doc-only gate sẽ phá optimization vừa xây.
4. Parse output người đọc dễ lệch locale; machine-readable output phải là seam.
5. Gate không có fake-tool tests có thể pass rỗng hoặc gọi Flutter nhiều lần.

Mỗi Why phải có evidence, cost và decision.

## Contract

- Đọc expected version từ `.fvmrc` bằng parser đúng format, fail actionable khi missing,
  malformed hoặc thiếu key; không regex mơ hồ trên JSON.
- Khi immutable verification plan chọn bất kỳ step thật sự cần Flutter/Dart toolchain,
  gọi SDK trên PATH bằng machine-readable version output và so exact normalized version.
- Prompt/docs-only, repository-furniture và picture-only plan không được boot Flutter chỉ
  để version check; pin bằng test invocation count.
- Mismatch fail trước format/analyze/codegen/tests với message gồm expected, actual,
  resolved executable/path và cách sửa; không tiếp tục rồi đổ hàng trăm lỗi thứ cấp.
- Một invocation gate không gọi version command lặp. Cache/stamp không được che việc SDK
  trên PATH đổi khi `.fvmrc` không đổi.
- Hỗ trợ Windows/Git Bash và CI shell hiện hữu; không thêm Node verifier song song.
- Giữ single-entry verification contract. Không bảo user chạy loose Flutter command.
- Allocate fresh WBS ID và đóng đúng technical debt, không sửa frozen checklist.

## Tests bắt buộc

Dùng temp fixture/fake executable thật:

- exact match; mismatch; malformed/missing `.fvmrc`; machine output invalid;
- Flutter executable missing/non-zero;
- docs/prompt-only plan gọi version 0 lần;
- toolchain plan gọi đúng 1 lần kể cả nhiều selected steps;
- SDK đổi giữa hai gate invocation bị phát hiện dù source tree không đổi;
- failure xảy ra trước fake analyze/test và message actionable;
- paths có space và Windows separator.

Fault-inject skip check, human-output parser và unconditional invocation; tests phải đỏ.

## Verification và delivery

- Chạy tooling tests, changed gate và final gate theo repo. Đo thời gian prompt/docs-only
  trước/sau để chứng minh không regression có ý nghĩa.
- Không emulator/golden/gallery regeneration; no visual delta.
- Sync main trước final; commit/push/non-draft PR với invocation matrix và timings.
  Không merge nếu user chưa yêu cầu session này.

## Clean stop

SDK lệch fail sớm, SDK đúng không tốn lặp, non-toolchain plan không boot Flutter,
cache không che PATH drift, tests fault-injection xanh và final gate pass.
