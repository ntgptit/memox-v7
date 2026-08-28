# Upgrade Study Home — Card Detail Visual Language

| | |
|---|---|
| **Status** | active |
| **Purpose** | Giao việc nâng cấp Study Home thành working surface hiện đại, compact và có phân tầng rõ theo style Card Detail |
| **Scope** | Presentation Study Home, responsive/semantics tests, golden và gallery; giữ nguyên workload/session/navigation hiện có |
| **Source of truth for** | Hướng dẫn thực thi Study Home visual hierarchy; nghiệp vụ chính thức vẫn thuộc BR-200…BR-202, UC-14 và wireframe M5 Study Home |
| **Depends on** | `CLAUDE.md`, `docs/document-conventions.md`, BR-200…BR-202, UC-14, `docs/wireframes/m5-study-home.md`, production Card Detail và MemoX design tokens |
| **Updated by task** | Study Home visual hierarchy prompt |
| **Last updated** | 2026-08-27 |

---

Triển khai **Study Home — Card Detail Visual Language** trên production screen
đã có. Không đổi resume validity, workload aggregation/order, session creation,
routes, repository, clock seam hoặc database.

## Pre-flight

Đọc contract repo, BR-200…BR-202, UC-14, M5 Study Home, code/test/golden hiện
tại, production Card Detail, `MxContentShell`, `MxCard`, `MxActionButton`,
`MxMetricWell` và responsive tokens. Lập reduced UI Contract/widget tree, kiểm
branch/base/dirty state. Không commit/push/PR trong implementation phase.

## 5Why

| Why | Nguyên nhân | Quyết định mở khoá |
|---|---|---|
| 1 | Resume và mọi deck hiện đều là khối lớn, khiến danh sách ngắn nhưng chiếm nhiều viewport. | Giữ resume focal, thu deck rows thành compact task cards theo density Card Detail. |
| 2 | Ba workload metric cạnh tranh bằng icon well lớn và chữ đậm. | Giữ đủ ba số theo BR-201 nhưng hạ metadata, dùng semantic tone tập trung. |
| 3 | CTA nằm trong từng card nhưng chưa gắn chặt với workload. | Neo action vào hàng cuối ổn định, một primary resume và secondary deck study. |
| 4 | Restyle dễ vô tình làm cả card tappable hoặc auto-start. | Chỉ button là action; giữ double-tap guard và explicit user intent. |
| 5 | Tên dài/text scale dễ phá hàng metric. | Dùng Wrap/grid adaptive và pin geometry trên production tree. |

## Visual thesis và widget tree

```text
MxContentShell
└─ one scroll owner
   └─ centered column (max AppBreakpoints.medium)
      ├─ compact supporting copy
      ├─ optional focal Resume MxCard
      ├─ section label STUDY NEXT + optional all-zero note
      └─ compact StudyHomeDeckCard × N
```

- Dùng nền trang + `MxCard` flat/subtle như Card Detail; không shadow stack.
- Resume là surface focal duy nhất, dùng accent/secondary container có kiểm soát.
- Deck cards là standard surface; không mỗi metric thành một card con.
- Typography compact: title `titleMedium`, metadata `bodySmall`, button label
  token; không dùng display typography cho tên deck/count.
- Section label dùng shared `sectionLabel`; content edges đồng nhất theo gutter.

## Resume card

- Giữ heading, deck name, stage/mode và Resume action thật. Không thêm tiến độ,
  percentage hoặc thời gian giả.
- Layout identity ở trên, context phụ kế tiếp, CTA dưới; CTA không full-card tap.
- Primary Resume có thể full-width ở compact viewport, nhưng không được làm card
  cao bất hợp lý ở 393/412. Dùng `MxActionButton` và canonical geometry.
- Khi không có resume, surface biến mất hoàn toàn và spacing co lại đúng token.

## Deck cards

- Giữ deck name, scheduler label khi biết, Overdue, Due today, New luôn hiện kể
  cả 0, và Study action chỉ khi subtree có card.
- Workload dùng ba compact metric items có icon well + label + tabular count.
  Overdue danger, due warning, new info chỉ khi count >0; zero dùng neutral.
- Màu không thay chữ/icon. Không dùng saturated card background theo workload.
- Metric items wrap theo nhóm nguyên vẹn; không để count/icon tách khỏi label.
- Action row cùng baseline với phần summary khi đủ rộng; stack dưới workload khi
  hẹp/text scale lớn. Không ép một Row gây overflow.
- Deck hết workload vẫn có Study; deck không card không được render action/hàng
  theo BR-201/BR-202 hiện hành.

## States

Giữ đủ loading, resume+list, no-resume, all-zero, no-root-deck, roots-without-
cards và read-error. Refresh/re-measure giữ snapshot và scroll position, không
route-wide spinner. Empty CTA vẫn đi đúng Library/Starter Library branch.

## Files dự kiến

- `lib/features/study/presentation/screens/study_home_screen.dart`
- `presentation/widgets/sections/study_home_body_section_widget.dart`
- `presentation/widgets/sections/study_home_resume_section_widget.dart`
- `presentation/widgets/items/study_home_deck_item_widget.dart`
- `presentation/widgets/items/study_home_workload_item_widget.dart`
- M5 wireframe append visual revision, `docs/wbs.md`, ARB chỉ khi semantic key
  thật sự thiếu, tests/goldens/Widgetbook/visual audit.

## Không được thay đổi

- Resume eligibility/newest-session rule, root-only aggregation/order/ties.
- Explicit Resume/Study navigation, double-tap protection và branch behavior.
- Session/materialization writes, clock/midnight refresh, controller/provider.
- Ba metric hoặc zero visibility; không thêm analytics/goal/celebration.
- Domain/data/SQL/schema, global typography/tokens.

## Tests bắt buộc

- Regression mọi state/action và read-only-before-tap behavior.
- `getRect`: resume/deck cards chung edges; card gaps; title/meta/workload/action
  rhythm; metric item không tách; action ≥48dp; last row clear bottom nav.
- 320dp @2.0, 393dp, 412dp, EN/VI, light/dark; long name, 4-digit counts,
  all-zero, resume/no-resume, refresh giữ scroll.
- Semantics gộp workload thành câu có nhãn; action chứa deck name; heading đúng;
  color không là tín hiệu duy nhất.
- Render/inspect loaded mixed, resume, no resume, all zero, both empties, error.

## Verification và clean stop

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base origin/main
```

Không emulator IT: `not run — presentation-only restyle`. Clean stop khi gate
xanh, không business/navigation/data drift, geometry + responsive + semantics
pass và worktree sẵn sàng cho reviews. Golden/gallery/PR do coordinator xử lý.
