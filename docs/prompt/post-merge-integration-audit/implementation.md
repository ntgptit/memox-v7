# Post-merge integration audit

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và auto-fix trạng thái hợp thành sau khi nhóm feature song song đã merge, không phát triển thêm nghiệp vụ |
| **Scope** | Progress, Study Home, reverse self-assess, Settings, Reminder, Tag, Card Detail, Search, Trash và các surface dùng chung mà chúng chạm tới |
| **Source of truth for** | Hướng dẫn thực thi post-merge audit; nghiệp vụ chính thức vẫn thuộc BR/AD/UC/data model/wireframe canonical |
| **Depends on** | `CLAUDE.md`, `AGENTS.md`, `docs/document-conventions.md`, `docs/architecture.md`, `docs/business-rules.md`, `docs/use-cases.md`, `docs/master-flow.md`, `docs/wbs.md`, `docs/wbs-study.md` |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

Bạn là coordinator audit trạng thái **đã merge** trên `origin/main`. Không merge lại
source PR và không thêm feature mới. Mục tiêu là chứng minh các feature hoạt động
đúng khi cùng tồn tại, tái hiện regression cụ thể, auto-fix trong scope và mở một
PR nhỏ, sẵn sàng để owner merge.

## 5Why bắt buộc

Trước khi sửa, viết 5Why dựa trên bằng chứng repo:

1. PR xanh riêng lẻ không chứng minh router, DI, schema, ARB và query hợp thành.
2. Feature active phải cùng loại tombstone, cùng local-day/clock và cùng scheduler generation.
3. Golden riêng màn không chứng minh navigation và state preservation giữa màn.
4. Test có thể cùng kế thừa một giả định sai; cần trace từ canonical rule tới observable outcome.
5. Audit rộng dễ thành refactor vô hạn; chỉ finding tái hiện được mới mở khóa sửa.

Mỗi Why phải nêu file/evidence, trade-off và quyết định mở khóa.

## Preflight và worktree safety

- Tạo worktree sạch từ `origin/main`; ghi baseline SHA, `git status`, schema version,
  route catalog và danh sách feature thực sự đã merge.
- Đọc contract theo reading order. Docs thắng code/test. Không sửa frozen docs nếu
  chưa được task/WBS cho phép; mâu thuẫn nghiệp vụ là blocker, không tự chọn.
- Không reset/force-push, không sửa source branch của PR cũ, không mang prompt local
  vào feature PR.

## Audit và auto-fix

Lập matrix có evidence cho các đường nối:

1. Progress Overview → Progress by Deck dùng cùng local-day snapshot và active-content semantics.
2. Study Home Start/Resume → Study Entry/Session/Result giữ scheduler, generation,
   direction và persisted review kind.
3. Settings → Reminder dùng preference, locale, timezone và workload mới nhất.
4. Tag rename/merge/delete phản ánh ở Card List, Detail và Search.
5. Search result mở đúng Deck/Card/Tag destination và back giữ query/filter/scroll hợp lệ.
6. Trash loại tombstone khỏi Library, counts, Study, Progress, Search, Tag, Reminder,
   move target, import duplicate và export; restore trả lại identity/history/state.
7. Startup compose đủ repository/provider; không chạy reconciler/sweeper hai lần.
8. Migration từ mọi version còn support tới latest giữ dữ liệu và invariant.

Audit-only trước: ghi severity, reproduction, file/line, violated contract và test
cần pin. Sau đó sửa architecture/logic trước, UI/accessibility sau. Mỗi fix phải có
regression test quan sát hành vi, không chỉ đổi mock/finder. Không tạo abstraction
hoặc migration mới nếu không cần.

## Verification và delivery

- Inner loop: `.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main`.
- Final: full consolidated gate theo `CLAUDE.md` hiện tại.
- Chỉ chạy emulator nếu final diff thêm/thay device-only flow hoặc contract hiện tại
  bắt buộc; nếu không, ghi rõ `not run` và lý do, không gọi là pass.
- Nếu có visual delta: regenerate golden với `TZ=UTC`, build gallery và publish đúng
  Artifact URL hiện hữu trong `CLAUDE.md`.
- Commit, push và mở non-draft PR; body gồm baseline, matrix, findings/fixes, gate,
  emulator status và gallery URL. Không merge PR nếu owner chưa yêu cầu session này.

## Clean stop

Không còn P0/P1/P2; mọi cross-feature scenario trên có evidence; schema/route/DI/ARB/docs
nhất quán; full gate xanh; P3 còn lại có owner và WBS entry; PR sẵn sàng để owner review.
