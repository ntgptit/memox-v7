# Local prompt handoff tooling

| | |
|---|---|
| **Status** | active |
| **Purpose** | Hoàn thiện đường bàn giao prompt local giữa các Git worktree bằng validation dùng chung, có test và contract cho mọi AI agent |
| **Scope** | `AGENTS.md`, local prompt reader PowerShell, test tooling trực tiếp và WBS entry của task |
| **Source of truth for** | Cách một execution session đọc ba prompt chưa commit từ worktree nguồn; không phải nguồn nghiệp vụ sản phẩm |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, prompt delivery contract và Git worktree semantics |
| **Updated by task** | Terra tooling campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là implementation coordinator trong một worktree sạch tạo từ `origin/main`.
Task này chỉ hoàn thiện developer tooling; không sửa code sản phẩm, schema, UI,
golden hoặc business documents.

## 5Why bắt buộc

Trước khi edit, viết 5Why có evidence file/line:

1. Path `docs/prompt/...` trong chat không giúp worktree khác thấy file chưa commit.
2. Copy validation vào từng trigger tạo nhiều implementation security khác nhau.
3. Hash prompt mà không hash reader vẫn cho phép logic reader bị đổi sau khi handoff.
4. Một script chỉ có happy-path test có thể đọc nhầm worktree hoặc in partial content.
5. Contract không commit cùng script sẽ trỏ tới một capability không tồn tại trên clone mới.

Mỗi Why phải ghi trade-off và quyết định nó mở khóa.

## Preflight và ownership

- Fetch `origin/main`, ghi baseline SHA, trạng thái worktree và current prompt contract.
- Không lấy nguyên file từ worktree khác rồi ghi đè. Dùng prompt này làm contract,
  inventory implementation hiện có trên branch và áp thay đổi tối thiểu.
- Giữ `AGENTS.md` là pointer/agent-only contract; không sao chép luật nghiệp vụ từ
  `CLAUDE.md`.
- Allocate WBS ID sau khi sync latest main; re-check ID trước PR vì các worktree khác
  có thể merge trong lúc task chạy.

## Contract phải triển khai

Tạo hoặc hoàn thiện
`.claude/skills/flutter-workflow/scripts/read_local_prompt_set.ps1` với API ổn định:

- input gồm source worktree root, target worktree root, feature name, SHA-256 của
  ba prompt và optional `-VerifyOnly`;
- xác nhận source và target là **exact Git worktree roots** bằng Git, không chỉ là
  directory tồn tại; resolve/canonicalize trước khi so;
- từ chối source = target, target nằm trong source, feature rỗng hoặc feature có
  separator, `..`, wildcard hay ký tự cho phép thoát `docs/prompt/`;
- chỉ chấp nhận đúng ba stable file: `implementation.md`,
  `recursive-architecture-logic-review.md`, `recursive-ui-ux-review.md`;
- kiểm tra đủ file và cả ba hash trước khi phát bất kỳ nội dung nào; failure phải
  non-zero và không in partial prompt;
- content mode in đầy đủ theo thứ tự implementation → architecture/logic → UI/UX,
  có boundary label rõ; `-VerifyOnly` chỉ xác minh và không in prompt body;
- source là read-only input; script không copy/edit/stage file ở source hoặc target;
- error không tiết lộ nội dung prompt, không chạy string-built shell command và dùng
  literal path an toàn trên Windows.

Trigger contract trong `AGENTS.md` phải ghi:

- trigger xác minh hash của chính reader trước khi gọi;
- execution edits chỉ ở target worktree;
- missing/hash mismatch là blocker, không fallback sang file cùng tên;
- remote session không đọc được filesystem chung thì prompt phải được commit/push
  hoặc inline theo yêu cầu user;
- sau prompt delivery phải có model-allocation table; Claude Code Max x5 là primary
  capacity, Codex Plus là constrained second opinion cho tới khi user đổi subscription;
- delivery phase, gallery/no-visual-delta evidence và non-draft PR giữ đúng contract
  hiện có; không tự merge nếu user chưa yêu cầu execution session.

## Tests bắt buộc

Test script thật qua PowerShell, không reimplement algorithm trong Python:

- happy path content mode và `-VerifyOnly`;
- wrong hash cho từng file, missing file và reader input invalid;
- source = target, nested/non-root source hoặc target;
- traversal/separator/wildcard/absolute feature names;
- failure trước emission: stdout không chứa body của prompt đầu;
- paths có space và Unicode;
- thứ tự ba body ổn định và mỗi body chỉ xuất hiện một lần;
- source/target status và file bytes không đổi sau invocation.

Test phải fail khi fault-inject bỏ từng validation quan trọng; không chỉ assert exit 0.

## Verification và delivery

- Chạy test tooling trực tiếp và prompt-contract guard.
- Chạy changed gate rồi final gate theo `CLAUDE.md`; nếu Bash/PowerShell thiếu thì
  báo blocker cụ thể, không thay bằng blanket pass.
- Không emulator, golden hoặc gallery regeneration: diff không có user-visible effect.
- Commit `AGENTS.md`, script và tests atomically; push branch, tạo non-draft PR kèm
  test/gate/no-visual-delta evidence. Không merge nếu user chưa yêu cầu session này.

## Clean stop

Clean khi mọi negative case fail kín trước emission, happy path đọc đúng ba prompt,
contract không trỏ file thiếu, changed/final gate xanh và PR sẵn sàng review.
