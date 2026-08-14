# Integrate ten parallel feature PRs sequentially

| | |
|---|---|
| **Status** | active |
| **Purpose** | Điều phối tích hợp tuần tự mười feature PR song song, recursive-review và auto-fix sau từng stage trước khi merge `main` |
| **Scope** | PR #301–#310; conflict resolution, migration sequencing, recursive architecture/logic và UI/UX review, verification, integration PR và hậu kiểm |
| **Source of truth for** | Hướng dẫn thực thi batch integration PR #301–#310; nghiệp vụ chính thức vẫn thuộc canonical BR, AD, UC, data model và wireframe trên nhánh tích hợp |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, canonical product/architecture/business/data/use-case documents, mười bộ prompt feature và mười PR được liệt kê dưới đây |
| **Updated by task** | M99.23 ten-PR sequential integration prompt |
| **Last updated** | 2026-08-14 |

---

Bạn là coordinator chịu trách nhiệm tích hợp **đúng mười PR #301–#310** của
`memox-v7`. Đây là một integration task, không phải cơ hội phát triển thêm
feature. Hãy merge từng PR vào một integration branch theo thứ tự được khóa ở
prompt này; sau mỗi merge phải recursive-review merged state, auto-fix mọi
finding trong scope, chạy gate và chỉ khi stage sạch mới đi tiếp.

`implementation.md` là **entrypoint duy nhất owner cần chạy**. Hai companion
review contract trong cùng thư mục không phải entrypoint độc lập của batch;
coordinator MUST giao chúng cho hai subagent audit-only sau từng merge với các
biến stage cụ thể như mô tả bên dưới.

## 5Why bắt buộc

Trước khi chạy lệnh thay đổi trạng thái, ghi một 5Why thực chất vào work log
của session:

| Why | Root cause cần chứng minh | Quyết định mở khóa |
|---|---|---|
| 1 | Mười PR cùng xuất phát từ một `main`, nên CI xanh riêng lẻ không chứng minh hợp thành xanh. | Tích hợp tuần tự trên một branch riêng và kiểm tra delta sau từng stage. |
| 2 | Router, DI, ARB, canonical docs, Widgetbook và database cùng bị nhiều PR sửa. | Không dùng ours/theirs nguyên file; merge theo semantic ownership và audit shared surfaces. |
| 3 | Reverse Self-assess, Settings, Reminder và Trash đều có thể tự nhận migration kế tiếp từ cùng schema base. | Xây một migration chain đơn điệu theo merged state; giữ snapshot và upgrade test cho từng version. |
| 4 | Review nằm trong từng feature branch chỉ quan sát code trước khi feature khác tồn tại. | Sau mỗi merge, hai audit độc lập phải đọc production tree đã hợp thành và auto-fix tuần tự. |
| 5 | Merge trực tiếp từng PR vào `main` có thể để default branch ở trạng thái degraded giữa hai PR. | Merge các head PR bằng merge commit vào integration branch; chỉ merge một integration PR vào `main` sau final gate. |

5Why không được chỉ chép lại bảng. Mỗi Why phải nêu bằng chứng ở repo/PR hiện
tại, trade-off và tiêu chí khiến quyết định tương ứng được coi là đúng.

## 1. Preflight và worktree safety

1. Đọc đầy đủ `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md` và reading
   order mà repo yêu cầu. Dùng guard/gate được **checkout hiện tại** quy định;
   không dùng command từ memory nếu file đó không tồn tại.
2. Làm việc trong một **worktree sạch mới** tạo từ `origin/main`, branch
   `codex/integrate-prs-301-310`. Không dùng worktree đang có thay đổi chưa
   commit; không mang theo attachment hoặc confirmation campaign chưa merge.
3. Chạy `git fetch --all --prune`, ghi baseline SHA của `origin/main`, head SHA,
   title, base branch, draft state, mergeability và required checks của từng PR.
4. Xác nhận tập PR chính xác:

   | Stage | PR | Expected head | Feature |
   |---:|---:|---|---|
   | 1 | #301 | `claude/implementation-parallel-audit-b7267b` | Progress Overview v1 |
   | 2 | #302 | `claude/progress-by-deck-v1-impl-f01b39` | Progress by Deck v1 |
   | 3 | #307 | `claude/study-home-v1-impl-audit-13d4c6` | Study Home v1 |
   | 4 | #304 | `claude/reverse-self-assess-impl-967abe` | Reverse Self-assess v1 |
   | 5 | #308 | `claude/settings-v1-implementation-audit-c6ee3e` | Settings v1 |
   | 6 | #303 | `claude/daily-reminders-v1-impl-d7da4b` | Daily Reminder v1 |
   | 7 | #309 | `claude/tag-management-v1-impl-13389c` | Tag Management v1 |
   | 8 | #306 | `claude/card-detail-history-impl-e52640` | Card Detail and History v1 |
   | 9 | #305 | `claude/global-library-search-v1-2d1733` | Global Library Search v1 |
   | 10 | #310 | `claude/trash-restore-v1-impl-41e740` | Trash and Restore v1 |

5. Nếu PR number, head SHA/ref, base hoặc scope khác bảng, dừng trước merge và
   báo owner. Head ref đúng nhưng SHA mới hơn là thay đổi cần đọc lại toàn diff,
   không phải blocker tự động; ghi SHA thực tế vào report.
6. Snapshot khi prompt được viết: #303 đang `BLOCKED` ở
   `format · analyze · guards · docs`; #310 đang `BLOCKED` ở cùng gate và
   Widgetbook. Phải re-fetch trạng thái mới. Không được đổi `BLOCKED` thành
   “pass” chỉ vì lỗi được kỳ vọng sẽ biến mất sau integration; phải đọc log,
   tái hiện hoặc giải thích, rồi đóng lỗi trên integration branch.
7. Không `git reset --hard`, không force-push source branch, không rewrite head
   PR, không squash/cherry-pick làm mất head commit. Không merge từng PR trực
   tiếp vào `main`.

## 2. Vì sao thứ tự này là bắt buộc

- #301 tạo Progress repository/query/screen; #302 mở rộng chính các contract đó.
- #307 thay Study placeholder bằng Study Home thật; #304 phải hòa direction
  chooser vào lifecycle/session thật đã tồn tại.
- #308 tạo Settings thật; #303 phải thêm Reminder vào screen thật thay vì giữ
  thay đổi trên `settings_placeholder_screen.dart`.
- #309 canonicalize tag catalog/filter trước; #306 bổ sung card detail/tag chips;
  #305 đến sau để điều hướng search result tới surface thật và dùng TagName duy
  nhất.
- #310 đến cuối vì soft-delete làm thay đổi ý nghĩa mọi query vừa thêm. Trash
  review phải kiểm Progress, Study Home, Reminder workload, Tag, Card Detail và
  Global Search cùng loại tombstone đúng cách.

Không đổi thứ tự chỉ để né conflict. Nếu dependency thực tế mới chứng minh thứ
tự sai, dừng và báo bằng file/contract cụ thể trước khi tiếp tục.

## 3. Vòng lặp bắt buộc cho mỗi stage

Với stage `N` và PR `P`, thực hiện đúng chu kỳ sau.

### 3.1. Freeze đầu vào

- Fetch PR head và xác nhận SHA không đổi từ preflight.
- Đọc PR body, toàn file list/diff, ba prompt ở
  `docs/prompt/<feature>/`, canonical docs và known debt/review findings của PR.
- Ghi `stage_base = HEAD` trước merge. Lập coverage checklist gồm behavior,
  persistence, routes, DI, ARB, shared widgets, docs, tests và UI states mà PR
  mang vào.
- Với source PR có required check đỏ, đọc failure log trước merge và thêm root
  cause vào checklist. Không bỏ qua vì stage sau sẽ chạy gate.

### 3.2. Merge vào integration branch

- Merge **head commit đầy đủ** bằng `git merge --no-ff --no-commit` để bảo toàn
  ancestry của source PR.
- Resolve conflict theo semantic contract; inspect cả base/ours/theirs và call
  sites. Không chọn nguyên file bằng ours/theirs cho docs, ARB, router, DI,
  database, Widgetbook hoặc shared tests.
- Trước khi tạo merge commit, chạy generated-code bootstrap mà `CLAUDE.md` yêu
  cầu và ít nhất compile/analyze/targeted checks đủ bắt conflict resolution sai.
- Tạo một merge commit có message `merge: integrate PR #P <feature>`; source
  head SHA phải là ancestor của commit này.
- Không sửa behavior ngoài scope để “làm conflict biến mất”. Semantic conflict
  giữa hai BR/UC đã frozen là blocker cần owner, không được tự chọn bên thắng.

### 3.3. Quy tắc resolve shared surfaces

**Canonical docs và ID**

- Docs thắng code/test. Preserve cả hai feature khi không mâu thuẫn.
- Nếu hai PR độc lập dùng cùng BR/AD/UC/WBS ID cho hai nghĩa khác nhau, ID đã có
  trên integration branch giữ nguyên; item từ PR merge sau nhận ID mới ở cuối
  namespace. Update toàn bộ docs, comments, tests và PR traceability liên quan.
- Không xóa hoặc ghi đè rule để làm guard xanh. Nội dung thật sự mâu thuẫn phải
  dừng hỏi owner. Một fact chỉ có một canonical location.

**Router, DI và startup composition**

- Hợp nhất route constants, builders, branch index, repository bindings và
  provider override list; không làm mất entry từ stage trước.
- Deep link, back stack, tab preservation và destination CTA phải dùng production
  route, không raw path.
- Khi #303 và #310 cùng sửa bootstrap/startup, Reminder reconciler và Trash
  sweeper phải cùng tồn tại với lifecycle/dispose đúng; không bọc cái này thay
  cái kia.

**Localization và Widgetbook**

- ARB là union theo semantic key; EN/VI phải parity. Same key/same meaning được
  hợp nhất; same key/different meaning phải rename key merge-sau và update mọi
  usage/test, không chọn một translation tùy ý.
- Widgetbook phải giữ toàn bộ use case đã merge; placeholder entry phải bị xóa
  đúng lúc production screen thay thế, không xóa catalog của feature khác.

**Database và migration chain**

- Baseline hiện dự kiến schema v7. Bốn schema-changing stages phải trở thành
  một chuỗi đơn điệu theo merged state, dự kiến:

  | Stage | Feature | Expected integrated version |
  |---:|---|---:|
  | 4 | Reverse Self-assess | v8 |
  | 5 | Settings | v9 |
  | 6 | Daily Reminder | v10 |
  | 10 | Trash and Restore | v11 |

- Bảng trên là expectation, không phải lý do bỏ inspect. Nếu `origin/main` đã
  đổi schema, lấy version kế tiếp thực tế nhưng giữ đúng relative order.
- Không để nhiều migration cùng tên/version, không sửa snapshot cũ thành schema
  mới, không gộp bốn migration thành một bước, không đổi trực tiếp
  `schemaVersion` mà thiếu migrator/snapshot/fixture/test.
- Renumber class/file/function/test từ PR merge sau khi cần; tạo và verify Drift
  snapshot cho **mỗi** version; test upgrade từ baseline qua từng bước và trực
  tiếp từ mọi version được repo support tới latest.
- Data/backfill/check constraints/index/foreign-key semantics của từng feature
  phải còn nguyên sau renumber. Generated files không commit nếu repo ignore.

**Trash-last cross-feature rule**

- Sau #310, audit mọi named query thêm từ #301–#309. Active views/workloads phải
  loại soft-deleted cards/decks; Trash queries là exception có chủ đích.
- Verify ít nhất Progress overview/by-deck, Study Home/resume/session queue,
  Reminder workload, Tag catalog/filter/count, Card Detail/history, Global
  Search, selection/move targets và deck/card aggregates.
- Soft-delete giữ identity, study state, tag links và history cho Restore nhưng
  content đã trash không được rò vào active UI. Purge mới cascade vĩnh viễn.
- Cập nhật query-inventory semantic tests cho query mới; không thêm blanket
  exemption để guard xanh.

### 3.4. Hai recursive audit độc lập

Sau merge commit, spawn hai subagent **audit-only** chạy song song. Cả hai đọc
merged production tree ở `HEAD`, không đọc source branch như trạng thái cuối và
không edit shared worktree.

**Subagent A — architecture/logic**

Subagent MUST đọc và thực thi
`docs/prompt/ten-pr-sequential-integration/recursive-architecture-logic-review.md`
với exact delta `stage_base..HEAD`, feature prompt architecture review, PR body
và canonical docs. Bắt buộc audit:

- BR/UC/AD/data-model parity và ID/reference collision;
- state transition, lifecycle, retry/idempotency/atomicity, local-day/timezone;
- Riverpod/DI boundaries, repository/use-case/DAO flow, no business logic UI;
- schema/migration/snapshot/backfill/invariant/query plan và stream invalidation;
- failure, rollback, concurrency-looking sequence, stale entity/deep link;
- integration với tất cả stage trước và regression tests bị thiếu.

Phải trả finding có severity, reproduction, exact file/line, violated contract,
fix proposal và test pin. Không được trả blanket `pass` chỉ từ analyzer/test.

**Subagent B — UI/UX**

Subagent MUST đọc và thực thi
`docs/prompt/ten-pr-sequential-integration/recursive-ui-ux-review.md` với exact
delta, feature UI review prompt, wireframe/concept, production routes,
Widgetbook và existing golden/geometry tests. Bắt buộc:

- render production loading/loaded/empty/error/submitting/disabled/success và
  feature-specific states, không chỉ harness giả;
- compare state-by-state với approved wireframe/concept; liệt kê approved
  divergence, không coi golden mới là bằng chứng parity;
- inspect gutters/shared edges/width/baseline/gap/scroll/safe area/bottom nav;
- EN/VI, light/dark, 320dp text scale 2.0, 390dp và 412dp;
- semantics, focus, touch target, non-color cues, destructive hierarchy;
- interaction thật tới route/action sau khi các stage trước đã thay screen.

Phải trả finding cùng reproduction/screenshot hoặc geometry evidence, exact
file, fix và regression assertion.

### 3.5. Auto-fix tuần tự, không cho hai reviewer cùng sửa

1. Coordinator tổng hợp finding; duplicate được gộp, conflict giữa reviewer
   được giải theo docs hoặc dừng hỏi owner.
2. Apply architecture/logic fixes trước. Thêm hoặc sửa tests pin reproduction.
3. Rerun targeted verification. Commit
   `fix(integration): reconcile logic after PR #P` nếu có thay đổi.
4. UI/UX phase phải re-read latest worktree sau logic fixes. Apply visual/
   interaction/accessibility fixes, thêm geometry/semantics/golden assertions và
   inspect output thật. Commit
   `fix(integration): reconcile UI after PR #P` nếu có thay đổi.
5. Spawn lại audit tương ứng trên delta mới và lặp đến clean-stop. Không giới
   hạn cứng số vòng; nếu cùng blocker lặp ba vòng, dừng với root-cause report,
   không tự hạ severity.

**Stage clean-stop** chỉ đạt khi:

- không còn P0/P1/P2 chưa xử lý; P3/debt có owner, lý do và WBS entry;
- mọi explicit requirement của source PR được implemented/deferred/block rõ;
- không regression với toàn bộ stage trước;
- docs/ARB/DI/router/schema/Widgetbook composition nhất quán;
- targeted reproduction tests và full repository mechanical gate đều xanh.

### 3.6. Gate sau từng stage

- Dùng đúng consolidated gate trong `CLAUDE.md` của merged checkout. Tại thời
  điểm prompt được viết, repo dùng
  `.claude/skills/flutter-workflow/scripts/dod_check.sh`; nếu contract mới đổi,
  dùng entry mới được repo chỉ định và ghi rõ.
- Không gọi một verifier không tồn tại. Không thay full gate bằng các lệnh rời
  rồi tuyên bố tương đương.
- Regenerate code theo bootstrap contract trước gate. Không commit generated
  artifacts mà repo ignore.
- Full host gate phải chạy sau **mỗi stage**. Emulator/device IT không cần chạy
  sau từng stage; nó bắt buộc ở final integrated state.
- Record stage number, PR/head SHA, merge commit, fix commits, reviewer verdict,
  gate command/result/duration và remaining debt trong integration PR body.
- Chỉ bắt đầu stage kế tiếp sau khi stage hiện tại đạt clean-stop.

## 4. Cross-feature scenarios phải pin trong quá trình tích hợp

Ngoài tests riêng của từng PR, final tree phải có regression coverage cho các
đường nối sau:

1. Progress Overview mở Progress by Deck, range/drill-down dùng cùng activity
   semantics và local-day snapshot.
2. Study Home Start/Resume đi qua session lifecycle thật; Reverse Self-assess
   direction được tạo, lưu, resume và render đúng.
3. Settings thật chứa global study defaults/theme/language; Reminder entry là
   section/route thật, không làm sống lại placeholder.
4. Reminder build workload tại fire time từ active content và dùng settings/
   locale/timezone mới nhất.
5. Tag rename/merge/delete cập nhật Card List, Card Detail và Global Search
   nhất quán; chỉ có một `TagName` validation owner.
6. Global Search card result mở Card Detail thật, deck result mở đúng tree
   context, tag result áp filter thật; back quay lại query/scroll state hợp lệ.
7. Soft-delete từ Card Detail/Card List/Deck giữ history/tag/state để restore;
   active Progress/Search/Tag/Study/Reminder không thấy tombstone; restore làm
   dữ liệu xuất hiện lại; purge mới xóa vĩnh viễn.
8. App startup compose Settings, Reminder và Trash dependencies mà không thiếu
   provider override hoặc chạy mutation hai lần.
9. Mọi migration path v7→latest và từng intermediate→latest giữ data của
   direction, settings, reminders và trash; fresh install bằng latest schema
   giống upgraded schema.
10. Bốn bottom-nav branch, deep link, reselect, back stack và placeholder removal
    không regress sau router merge.

Không bịa expected behavior nếu canonical docs giữa hai feature mâu thuẫn.
Đó là blocker cần owner, không phải conflict để auto-fix.

## 5. Final recursive review và merge `main`

Sau stage 10:

1. Fetch `origin/main`. Nếu main tiến lên từ baseline, merge main vào integration
   branch, resolve theo cùng workflow và chạy lại **hai final audit độc lập** trên
   toàn `baseline..HEAD`.
2. Chạy full consolidated gate một lần cuối.
3. Chạy emulator/device integration suite mà mười feature PR đã defer, trên một
   emulator/device được repo support. Không ghi “pass” nếu chưa chạy; nếu môi
   trường không có emulator hoặc permission thì dừng trước merge và báo blocker
   cụ thể cho owner.
4. Kiểm tra repo-wide architecture, docs, invariants trên database thật,
   migrations, l10n parity, Widgetbook smoke, visual audit/goldens và generated
   freshness. Không còn placeholder production của Progress/Study/Settings.
5. Push integration branch, mở một PR vào `main`. PR body phải có:
   - baseline và final SHA;
   - bảng 10 stage/head/merge/fix commits;
   - conflict decisions, đặc biệt ID renumber và migration version map;
   - findings/fixes của từng recursive audit;
   - gate và emulator evidence;
   - remaining P3/debt/approved UI divergence;
   - explicit statement rằng source head của #301–#310 là ancestor của branch.
6. Chờ required GitHub checks xanh trên integration PR. Failure phải được sửa
   trên integration branch, review lại affected stage/cross-feature delta và
   rerun local gate trước push mới.
7. Final integration PR MUST dùng **merge commit**, không squash/rebase, để head
   commits của mười source PR trở thành ancestors của `main`. Nếu branch policy
   không cho merge commit, dừng hỏi owner; không đổi strategy âm thầm.
8. Merge integration PR vào `main`, fetch lại và xác nhận:
   - final integration commit reachable từ `origin/main`;
   - head SHA của cả #301–#310 reachable từ `origin/main`;
   - GitHub nhận cả mười PR là merged. Nếu GitHub không đánh dấu một PR dù head
     reachable, báo rõ; không đóng PR thủ công rồi gọi đó là merged.

## 6. Stop conditions

Dừng ngay, giữ branch recoverable và báo owner khi gặp một trong các trường hợp:

- canonical BR/UC/AD thật sự mâu thuẫn và không thể preserve đồng thời;
- source PR/head/scope không đúng inventory;
- migration không thể renumber mà giữ backward compatibility/data;
- P0/P1/P2 lặp lại sau ba vòng fix-review;
- required host gate, CI hoặc final emulator suite không xanh;
- merge strategy của repo không thể bảo toàn source head ancestry;
- cần destructive git/database action ngoài scope.

Không dùng “expected failure”, “flaky”, “pre-existing” hoặc “pass locally” để
bỏ stop condition nếu chưa có reproduction và bằng chứng. Không merge một cây
source degraded chỉ vì từng PR từng xanh riêng lẻ.

## 7. Definition of Done

- Mười PR được tích hợp đúng thứ tự, mỗi source head còn trong ancestry.
- Sau từng stage có hai audit độc lập, fix tuần tự, recursive re-review và full
  host gate xanh.
- Canonical docs/IDs, ARB, router, DI, startup, Widgetbook và shared widgets là
  semantic union, không phải ours/theirs winner.
- Migration chain có version riêng cho từng schema change, snapshots và upgrade
  tests đầy đủ; fresh/upgraded schema tương đương.
- Cross-feature scenarios ở mục 4 có executable regression coverage.
- Final host gate, final two-audit pass, emulator/device suite và GitHub checks
  đều xanh.
- Integration PR merge-commit đã vào `main`; #301–#310 được GitHub xác nhận
  merged; report không có blanket pass hoặc finding bị giấu.
