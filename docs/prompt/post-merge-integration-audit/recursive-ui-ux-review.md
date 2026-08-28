# Recursive UI/UX review — post-merge integration

| | |
|---|---|
| **Status** | active |
| **Purpose** | Render và tái kiểm trải nghiệm hợp thành của các feature sau merge |
| **Scope** | Navigation nối feature, production states, shared shell, accessibility, responsiveness và gallery |
| **Source of truth for** | Hướng dẫn recursive UI/UX review; visual contract vẫn thuộc wireframe/token/canonical behavior |
| **Depends on** | `docs/prompt/post-merge-integration-audit/implementation.md`, relevant wireframes, latest production tree và gallery |
| **Updated by task** | Eight follow-up prompt campaign |
| **Last updated** | 2026-08-28 |

---

First pass **audit-only**. Render production routes/widgets bằng repository fake ở
boundary hiện có; golden mới không phải bằng chứng parity.

## Matrix và geometry

Render light/dark, EN/VI, 320dp@2.0, 393dp và 412dp cho loaded/loading/empty/error/
submitting/disabled và destructive/restore/resume states đại diện. Dùng `getRect` pin:

- shared screen gutter và leading/trailing edges giữa hero, list, panel, CTA;
- bottom navigation/safe area không che content;
- toolbar/filter/selection state không nhảy baseline;
- CTA destination và back giữ đúng branch/query/scroll;
- long Vietnamese/Korean không overflow, touch target và semantics đạt guideline.

So từng region với wireframe tương ứng. Lập bảng `concept intent / production evidence /
approved divergence / result`; danh sách approved divergence phải có trước khi nhìn fix.
Unapproved divergence, false affordance, color-only state hoặc stale gallery là finding.

Sau report, coordinator auto-fix UI tuần tự trên latest tree, thêm geometry/semantics/
interaction assertion, chạy changed gate và render lại. Lặp tới clean stop: không còn
P0/P1/P2, không overflow/clipping, production state matrix có evidence, goldens `TZ=UTC`
được inspect và gallery URL hiện hữu được cập nhật. Reviewer không commit/push/merge.
