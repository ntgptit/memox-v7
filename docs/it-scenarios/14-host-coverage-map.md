# Bản đồ coverage host cho từng kịch bản

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Nói rõ kịch bản nào đã có test host chứng minh, kịch bản nào chưa, để bước 5–7 chỉ viết cái còn thiếu |
| **Scope** | 133 kịch bản của `scenario-catalog.md`. Ngoài phạm vi: đánh giá chất lượng của test đã có |
| **Source of truth for** | Danh sách việc còn phải viết ở `HOST-FLOW`/`HOST-WIDGET` |
| **Depends on** | `scenario-catalog.md`, `12-testing-pyramid-audit.md` |
| **Updated by task** | Refactor IT theo Testing Pyramid — bước 5 |
| **Last updated** | 2026-08-09 |

**Bản đồ này là danh sách việc, không phải giấy chứng nhận.** Nó nối kịch bản
với test *nhắc tới cùng một ID luật*. Một test nhắc BR-62 gần như chắc chắn
đang kiểm BR-62, nhưng nó không tự động kiểm **đúng cái khẳng định** mà kịch
bản muốn. Vì vậy cột trạng thái đọc là:

- `đã có` — mọi luật của kịch bản đều đã được một test host nhắc tới. Việc
  còn lại là **đọc** test ấy và xác nhận nó khẳng định đúng thứ kịch bản cần;
  nếu đúng thì không viết gì thêm (§5 cấm lặp coverage).
- `một phần` — có luật đã có, có luật chưa.
- `chưa có` — không luật nào của kịch bản xuất hiện trong test host nào.

## Tổng kết

| Trạng thái | Số kịch bản |
|---|---|
| đã có | **107** |
| một phần | **23** |
| chưa có | **3** |

17 tệp test chạy trên SQLite thật (`openTestDatabase` hoặc
`NativeDatabase.memory`), nên nền `HOST-FLOW` không phải dựng từ đầu.

## Kịch bản còn thiếu luật chưa được test nào nhắc tới

Đây là danh sách việc thật sự của bước 5.

| ID | Profile | Luật chưa có test nào nhắc |
|---|---|---|
| IT-NAV-005 | `HOST-WIDGET` | — |
| IT-ORG-012 | `HOST-WIDGET` | — |
| IT-MODE-013 | `HOST-WIDGET` | — |
| IT-DECK-002 | `HOST-WIDGET` | BR-02 |
| IT-STUDY-006 | `HOST-WIDGET + HOST-FLOW` | BR-100 |
| IT-STUDY-010 | `HOST-FLOW` | BR-24 |
| IT-STUDY-011 | `HOST-FLOW` | BR-23 |
| IT-STUDY-012 | `HOST-FLOW` | BR-102 |
| IT-STUDY-013 | `HOST-FLOW` | BR-24 |
| IT-LEARN-004 | `HOST-FLOW` | BR-102 |
| IT-LEARN-005 | `HOST-FLOW` | BR-140 |
| IT-LEARN-006 | `HOST-FLOW` | BR-140 |
| IT-LEARN-009 | `HOST-FLOW` | BR-28 |
| IT-LEARN-010 | `HOST-FLOW` | BR-27 |
| IT-LEARN-011 | `HOST-FLOW` | BR-24 |
| IT-REVIEW-004 | `HOST-FLOW` | BR-23, BR-24, BR-102 |
| IT-REVIEW-005 | `HOST-FLOW` | BR-21, BR-75, BR-143 |
| IT-REVIEW-009 | `HOST-FLOW` | BR-24 |
| IT-MODE-001 | `HOST-WIDGET` | BR-98 |
| IT-MODE-009 | `HOST-WIDGET + HOST-FLOW` | BR-131 |
| IT-MODE-015 | `HOST-FLOW` | BR-122 |
| IT-CONT-001 | `HOST-FLOW` | BR-102 |
| IT-CONT-003 | `HOST-FLOW` | BR-80 |
| IT-CONT-006 | `HOST-FLOW` | BR-102 |
| IT-CONT-010 | `HOST-FLOW` | BR-46 |
| IT-PLAT-003 | `DEVICE-E2E` | BR-102 |

## Kịch bản đã có test host nhắc tới mọi luật

| ID | Profile | Luật | Test nhắc tới (một ví dụ) |
|---|---|---|---|
| IT-NAV-001 | `HOST-WIDGET` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-NAV-002 | `HOST-WIDGET` | BR-101 | `test/features/study/data/study_session_test.dart` |
| IT-NAV-003 | `HOST-WIDGET` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-NAV-004 | `HOST-WIDGET` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-NAV-006 | `HOST-FLOW` | UC-02, UC-03, UC-04, UC-08 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-NAV-007 | `DEVICE-E2E` | AD-01 | `test/app/architecture_boundary_test.dart` |
| IT-NAV-008 | `HOST-WIDGET` | UC-05, BR-101 | `test/features/study/data/study_flow_test.dart` |
| IT-NAV-009 | `HOST-WIDGET` | UC-05, BR-101, BR-146 | `test/features/study/data/study_flow_test.dart` |
| IT-NAV-010 | `HOST-WIDGET` | UC-05, BR-82 | `test/features/study/data/study_flow_test.dart` |
| IT-DECK-001 | `HOST-WIDGET + HOST-FLOW` | UC-02, BR-11 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-DECK-003 | `HOST-WIDGET` | UC-02, BR-01, BR-11 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-DECK-004 | `HOST-WIDGET` | UC-02, BR-01 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-DECK-005 | `HOST-WIDGET` | UC-02 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-DECK-006 | `HOST-WIDGET + HOST-FLOW` | UC-03, BR-01 | `test/app/router/deck_route_test.dart` |
| IT-DECK-007 | `HOST-WIDGET` | UC-03, BR-04 | `test/app/router/deck_route_test.dart` |
| IT-DECK-008 | `HOST-WIDGET + HOST-FLOW` | UC-03, BR-03, BR-04 | `test/app/router/deck_route_test.dart` |
| IT-TREE-001 | `HOST-WIDGET + HOST-FLOW` | UC-08, BR-58, BR-59 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-002 | `HOST-WIDGET` | UC-08, BR-60, BR-61 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-003 | `HOST-WIDGET + HOST-FLOW` | UC-08, BR-62, BR-63 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-004 | `HOST-WIDGET + HOST-FLOW` | UC-08, BR-62, BR-64 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-005 | `HOST-FLOW` | UC-08, BR-62 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-006 | `HOST-FLOW` | UC-08, BR-67 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-007 | `HOST-WIDGET + HOST-FLOW` | UC-03, BR-68 | `test/app/router/deck_route_test.dart` |
| IT-TREE-008 | `HOST-FLOW` | UC-03, BR-68 | `test/app/router/deck_route_test.dart` |
| IT-TREE-009 | `HOST-WIDGET + HOST-FLOW` | UC-09, BR-71 | `test/features/deck/data/deck_repository_move_test.dart` |
| IT-TREE-010 | `HOST-FLOW` | UC-09, BR-69, BR-70 | `test/features/deck/data/deck_repository_move_test.dart` |
| IT-TREE-011 | `HOST-FLOW` | UC-09, BR-64 | `test/features/deck/data/deck_repository_move_test.dart` |
| IT-TREE-012 | `HOST-FLOW` | UC-09, BR-73, BR-74 | `test/features/deck/data/deck_repository_move_test.dart` |
| IT-TREE-013 | `HOST-FLOW` | UC-08, UC-09, BR-55 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-TREE-014 | `HOST-FLOW` | UC-03, BR-67, BR-68 | `test/app/router/deck_route_test.dart` |
| IT-DISC-001 | `HOST-WIDGET + HOST-FLOW` | UC-06, BR-142, BR-150 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-002 | `HOST-WIDGET` | UC-06, BR-29 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-003 | `HOST-WIDGET + HOST-FLOW` | UC-06, BR-142, BR-150 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-004 | `HOST-WIDGET` | UC-06, BR-29 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-005 | `HOST-WIDGET + HOST-FLOW` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-006 | `HOST-WIDGET + HOST-FLOW` | UC-06, BR-56, BR-57 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-007 | `HOST-WIDGET` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-DISC-008 | `HOST-WIDGET` | UC-06, BR-22 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-CARD-001 | `HOST-WIDGET` | UC-04 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-002 | `HOST-WIDGET + HOST-FLOW` | UC-04, BR-07, BR-09 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-003 | `HOST-WIDGET` | UC-04, BR-07 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-004 | `HOST-WIDGET` | UC-04, BR-08 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-005 | `HOST-WIDGET` | UC-04, BR-95 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-006 | `HOST-WIDGET` | BR-95 | `test/features/card/data/card_repository_test.dart` |
| IT-CARD-007 | `HOST-WIDGET` | UC-04 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-008 | `HOST-WIDGET + HOST-FLOW` | UC-04, BR-10 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-009 | `HOST-FLOW` | UC-04, BR-10, BR-92 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-010 | `HOST-WIDGET + HOST-FLOW` | UC-04 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-CARD-011 | `HOST-FLOW` | UC-04, BR-67 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-001 | `HOST-WIDGET + HOST-FLOW` | UC-04 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-002 | `HOST-WIDGET` | UC-04 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-003 | `HOST-FLOW` | UC-04, BR-142, BR-151 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-004 | `HOST-WIDGET + HOST-FLOW` | BR-92 | `test/database/invariants_after_flow_test.dart` |
| IT-ORG-005 | `HOST-FLOW` | BR-90, BR-92, BR-142, BR-151 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-006 | `HOST-WIDGET` | BR-92 | `test/database/invariants_after_flow_test.dart` |
| IT-ORG-007 | `HOST-WIDGET + HOST-FLOW` | BR-93 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-008 | `HOST-FLOW` | BR-93 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-009 | `HOST-WIDGET` | BR-93, BR-94 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-ORG-010 | `HOST-WIDGET + HOST-FLOW` | BR-89, BR-90, BR-91 | `test/features/card/data/card_tag_dao_test.dart` |
| IT-ORG-011 | `HOST-WIDGET` | UC-04, UC-06 | `test/features/card/data/card_filter_repository_test.dart` |
| IT-STUDY-001 | `HOST-WIDGET + HOST-FLOW` | UC-05, BR-142, BR-150, BR-151 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-002 | `HOST-FLOW` | UC-05, BR-101 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-003 | `HOST-FLOW` | UC-05, BR-29, BR-145 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-004 | `HOST-WIDGET + HOST-FLOW` | UC-05, BR-99, BR-146, BR-154 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-005 | `HOST-FLOW` | UC-05, BR-30, BR-146 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-007 | `HOST-FLOW` | UC-05, BR-114, BR-154 | `test/features/study/data/study_flow_test.dart` |
| IT-STUDY-008 | `HOST-FLOW` | BR-147, BR-148 | `test/features/study/data/study_options_flow_test.dart` |
| IT-STUDY-009 | `HOST-FLOW` | BR-06, BR-139, BR-147 | `test/database/fixture_db_test.dart` |
| IT-LEARN-001 | `HOST-FLOW + HOST-WIDGET` | UC-05, BR-97, BR-108, BR-109, BR-110 | `test/features/study/data/study_flow_test.dart` |
| IT-LEARN-002 | `HOST-FLOW` | UC-05, BR-109, BR-110 | `test/features/study/data/study_flow_test.dart` |
| IT-LEARN-003 | `HOST-WIDGET` | BR-111, BR-112 | `test/database/migration_v5_test.dart` |
| IT-LEARN-007 | `HOST-FLOW` | BR-99, BR-153 | `test/features/study/data/study_skipped_stage_flow_test.dart` |
| IT-LEARN-008 | `HOST-FLOW` | BR-115, BR-116, BR-119 | `test/features/study/data/study_queue_test.dart` |
| IT-LEARN-012 | `HOST-FLOW` | UC-05, BR-82, BR-86, BR-144 | `test/features/study/data/study_flow_test.dart` |
| IT-REVIEW-001 | `HOST-FLOW` | UC-05, BR-142 | `test/features/study/data/study_flow_test.dart` |
| IT-REVIEW-002 | `HOST-FLOW + HOST-WIDGET` | BR-109, BR-146 | `test/features/study/domain/study_start_session_test.dart` |
| IT-REVIEW-003 | `HOST-WIDGET` | BR-30, BR-106, BR-146 | `test/app/fixture_seeder_widget_test.dart` |
| IT-REVIEW-006 | `HOST-FLOW` | BR-15, BR-16, BR-105 | `test/features/study/domain/eight_box_scheduler_test.dart` |
| IT-REVIEW-007 | `HOST-FLOW` | BR-17, BR-18, BR-19, BR-105 | `test/features/study/domain/sm2_scheduler_test.dart` |
| IT-REVIEW-008 | `HOST-FLOW` | BR-105, BR-145 | `test/features/study/domain/study_day_test.dart` |
| IT-REVIEW-010 | `HOST-FLOW` | BR-99, BR-114, BR-154 | `test/features/study/data/study_skipped_stage_flow_test.dart` |
| IT-MODE-002 | `HOST-WIDGET` | BR-111, BR-112 | `test/database/migration_v5_test.dart` |
| IT-MODE-003 | `HOST-WIDGET` | BR-115 | `test/features/study/data/study_queue_test.dart` |
| IT-MODE-004 | `HOST-WIDGET + HOST-FLOW` | BR-107, BR-116, BR-118, BR-120 | `test/features/study/domain/eight_box_scheduler_test.dart` |
| IT-MODE-005 | `HOST-WIDGET + HOST-FLOW` | BR-121, BR-125, BR-126 | `test/features/study/data/study_session_test.dart` |
| IT-MODE-006 | `HOST-FLOW` | BR-99, BR-121, BR-124 | `test/features/study/data/study_skipped_stage_flow_test.dart` |
| IT-MODE-007 | `HOST-FLOW` | BR-117, BR-127 | `test/features/study/domain/match_board_deal_test.dart` |
| IT-MODE-008 | `HOST-WIDGET + HOST-FLOW` | BR-128, BR-129 | `test/features/study/domain/recall_fill_mode_test.dart` |
| IT-MODE-010 | `HOST-FLOW` | BR-134, BR-137, BR-138 | `test/features/study/domain/recall_fill_mode_test.dart` |
| IT-MODE-011 | `HOST-FLOW` | BR-135, BR-136, BR-137, BR-138 | `test/features/study/domain/recall_fill_mode_test.dart` |
| IT-MODE-012 | `HOST-WIDGET` | BR-30, BR-106, BR-112, BR-146 | `test/app/fixture_seeder_widget_test.dart` |
| IT-MODE-014 | `HOST-FLOW` | BR-121, BR-124 | `test/features/study/data/study_session_test.dart` |
| IT-CONT-002 | `HOST-FLOW` | BR-82, BR-103 | `test/features/study/data/study_lifecycle_test.dart` |
| IT-CONT-004 | `HOST-WIDGET` | UC-05, BR-82, BR-86 | `test/features/study/data/study_flow_test.dart` |
| IT-CONT-005 | `HOST-FLOW` | BR-81 | `test/features/study/data/study_lifecycle_test.dart` |
| IT-CONT-007 | `HOST-FLOW + HOST-WIDGET` | UC-05 | `test/features/study/data/study_flow_test.dart` |
| IT-CONT-008 | `DEVICE-E2E` | AD-01, UC-05 | `test/app/architecture_boundary_test.dart` |
| IT-CONT-009 | `HOST-FLOW` | UC-07, BR-83, BR-152 | `test/app/bootstrap_test.dart` |
| IT-CONT-011 | `HOST-FLOW` | UC-05, BR-25 | `test/features/study/data/study_flow_test.dart` |
| IT-CONT-012 | `HOST-FLOW` | UC-05, BR-85, BR-86 | `test/features/study/data/study_flow_test.dart` |
| IT-CONT-013 | `HOST-FLOW + HOST-WIDGET` | UC-05 | `test/features/study/data/study_flow_test.dart` |
| IT-CONT-014 | `HOST-FLOW` | UC-05, BR-82, BR-103 | `test/features/study/data/study_flow_test.dart` |
| IT-PLAT-001 | `DEVICE-E2E` | UC-06, AD-04 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-PLAT-002 | `DEVICE-E2E` | UC-02, UC-04, AD-01, AD-04 | `test/features/deck/data/deck_repository_impl_test.dart` |
| IT-PLAT-004 | `DEVICE-E2E` | UC-06 | `test/features/deck/data/deck_level_read_test.dart` |
| IT-PLAT-005 | `DEVICE-E2E` | UC-05, BR-82 | `test/features/study/data/study_flow_test.dart` |
| IT-PLAT-006 | `DEVICE-E2E` | UC-02, UC-04, UC-05, AD-04 | `test/features/deck/data/deck_repository_impl_test.dart` |

