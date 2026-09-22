# Verification — gate nào có thật, chạy ở đâu

| | |
|---|---|
| **Status** | active |
| **Purpose** | Trả lời "cái gì đang thật sự canh code này, và cái gì chỉ chạy khi có người bấm" — vì hai câu đó không giống nhau ở repo này |
| **Scope** | Gate đã commit: workflow CI, script guard, bộ test và baseline của chúng. Ngoài phạm vi: cách viết test (`.claude/skills/flutter-testing/`), quy trình 22 phase (`checklist.md`), Definition of Done (`CLAUDE.md`) |
| **Source of truth for** | Bản đồ gate → nơi chạy (PR CI / thủ công / chỉ local) · baseline đã đo và nguồn của nó |
| **Depends on** | `document-conventions.md`, `checklist.md` |
| **Updated by task** | project-documentation FULL_SYNC (no WBS id) |
| **Last updated** | 2026-09-23 |

---

## 1 · Điều quan trọng nhất: ba workflow, chỉ một chạy tự động

| Workflow | Trigger | Nghĩa là |
|---|---|---|
| `ci.yml` | `pull_request` → `main`, và `workflow_dispatch` | **Gate thật.** Mọi PR đi qua đây |
| `ci-full.yml` | `workflow_dispatch` **only** | Không bao giờ tự chạy. Có người bấm mới chạy |
| `ci-device.yml` | `workflow_dispatch`, và `push` tag `v*` | Không chạy trên PR |
| `build-apk.yml` | `workflow_dispatch` | Thủ công, APK debug-signed |

Đọc sai chỗ này là cách người ta tin rằng một thứ đang được canh trong khi nó
không. `ci-full.yml` chứa full non-golden suite, clean-rebuild reproducibility và
Playwright E2E — **không thứ nào trong đó chặn một PR.**

## 2 · Các job trong `ci.yml`

Tất cả đều có điều kiện: job `classify` chạy `build_verification_plan.py` để phân
loại tập file đã đổi, rồi các job sau chỉ chạy nếu cờ tương ứng bật.

| Job | Tên hiển thị | Chạy gì |
|---|---|---|
| `classify` | classify change set | Dựng kế hoạch xác minh từ tập path đã đổi |
| `contracts` | tooling · docs · prompt contracts | `check_docs.py --quiet`, unit test của tooling, prompt contract |
| `static` | format · analyze · guards · docs | `check_format.sh`, `flutter analyze`, `check_architecture.sh`, code-verification guard |
| `host_tests` | host tests · shard N/M | `flutter test --exclude-tags golden`, chia shard |
| `widgetbook` | Widgetbook smoke test | `flutter test` trong `widgetbook/` |
| `goldens` | goldens (linux) | `flutter test --tags golden` trên `ubuntu-latest` |
| `memox_api` | memox-api · verify | `./mvnw -B -ntp verify` + `git diff --exit-code -- openapi.json`, hai leg `testcontainers` và `local` |
| `gate` | CI gate | Tổng hợp — đây là required check duy nhất |

**Golden chỉ có một nền tảng tác giả, và từ M100.24 nó là Linux.** Cùng widget,
cùng font, cùng SDK nhưng khác OS thì antialiasing khác 1–3% pixel, và
`matchesGoldenFile` so từng byte. Một checkout Windows chạy `--update-goldens` sẽ
ghi ra PNG mà CI từ chối — **và nó im lặng**, vì một nền tảng luôn tự đồng ý với
chính nó. Dùng WSL, hoặc để một phiên cloud sinh lại.

## 3 · Chạy trên máy trước khi push

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

Đó là nửa cơ học của Definition of Done. Nửa phán đoán vẫn là của người.

Hai check đáng chạy thẳng khi đụng tài liệu hoặc schema:

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py
python .claude/skills/flutter-workflow/scripts/verify_invariants.py
```

Vòng trong, chỉ chạy phần liên quan:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Nó dựng đúng kế hoạch xác minh mà PR CI dùng. **Nhưng vòng local loại trừ tag
golden** — so pixel là việc của PR CI (`goldens (linux)`), không phải của máy bạn.

## 4 · Bộ test trên thiết bị — CI cố ý không chạy

```bash
flutter test integration_test/ -d emulator-5554 --flavor development
```

Flavor là bắt buộc: app có ba flavor và Gradle không sinh APK nếu thiếu.

**Baseline: 9 pass, 0 fail.** Chín, không phải sáu mươi bảy — đúng nghĩa của
testing pyramid sau lần refactor: phần đúng-sai nghiệp vụ đã chuyển sang
`flutter test` (CI chạy mỗi PR), còn lại trên thiết bị là thứ host không chạm
tới được: bootstrap của engine, file thật trên bộ nhớ máy, deep link của OS, cử
chỉ Back của Android, một bản release build, và **bộ font hệ thống** — cái thứ
chín, thêm vào khi app thôi bundle font Nhật và Trung giản thể.

Emulator trên GitHub runner tốn 30–45 phút một lần chạy và là thứ dễ flaky nhất
trong pipeline. Nên đây là gate **local**, và nó thuộc về người thêm feature.

## 5 · Baseline đã đo trong lần FULL_SYNC này

Chạy thật tại revision `5b83bfd8`, không phải trích từ tài liệu:

| Lệnh | Kết quả |
|---|---|
| `check_docs.py` | exit 0 — "specification is internally consistent"; 142 IT scenario hợp lệ; 37 invariant query parse được, **mỗi câu tự bắn khi có vi phạm của riêng nó**; 9 data invariant có query |
| `verify_invariants.py` | exit 0 — 37/37, "TẤT CẢ ĐẠT" |
| `check_architecture.py` | exit 0 — "architecture boundaries clean"; 756 file dưới `lib` (features 595: domain 227, data 83, presentation 267, di 19) |

**Không chạy** trong lần này, và nói rõ vì sao: `flutter analyze` và
`flutter test` cần generated code, mà worktree này thiếu `.drift.dart`
(có 89 `.g.dart`, 0 `.drift.dart`). Thay đổi của lần sync này là tài liệu và
comment — không có thay đổi nào chạm vào ngữ nghĩa Dart — nên hai gate đó không
phải là bằng chứng cho nó. Một thay đổi có chạm code thì **phải** chạy.

## 6 · Hai cơ chế dễ hiểu nhầm

**`invariant_queries.dart` chạy 24 trong 37 câu, và đó là cố ý.** File tự khai:
"the ones here are the ones with an executable fixture". Q16–Q28 không có fixture
chạy được nên không nằm trong `flutter test`; chúng vẫn được `verify_invariants.py`
kiểm bằng cách khác — sinh vi phạm tổng hợp rồi xác nhận câu query bắn. Hai cơ chế
khác nhau cho cùng một tập luật, không phải một lỗ hổng bị giấu.

**`check_docs.py` không đọc được điều kiện viết bằng prose.** Hàm
`_check_not_written_yet()` chỉ kiểm file `docs/<name>` có tồn tại hay không. Một
dòng trong bảng "Not written yet" mà điều kiện của nó đã xảy ra rồi thì check vẫn
xanh — xem `interfaces.md` §8 cho trường hợp đang mở.
