# Danh mục thực thi kịch bản IT cho AI agent

| | |
|---|---|
| **Status** | đang áp dụng |
| **Purpose** | Lập chỉ mục từng kịch bản cùng mức sẵn sàng, hồ sơ thực thi, chuẩn bị, dọn dẹp và truy vết để agent chọn phép kiểm thử mà không suy đoán |
| **Scope** | Toàn bộ kịch bản IT hiện có trong `docs/it-scenarios`; không lặp lại các bước thao tác |
| **Source of truth for** | Mức sẵn sàng, hồ sơ thực thi, chuẩn bị, dọn dẹp và truy vết theo từng ID kịch bản IT |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, mười một tệp kịch bản theo nhóm chức năng |
| **Updated by task** | Bổ sung kịch bản điều hướng cho chức năng học ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

Agent MUST tìm ID ở danh mục này trước khi chạy. Cột tệp chỉ tới tài liệu chứa
các bước gốc. Ý nghĩa mức sẵn sàng, hồ sơ thực thi, chuẩn bị và dọn dẹp nằm trong
[`00-agent-execution-guide.md`](00-agent-execution-guide.md).

## Điều hướng và tiếp tục

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-NAV-001 | `01-navigation-and-continuity.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-06 |
| IT-NAV-002 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-UNSET | CLEAN-RESET | BR-101, M4.10a, M5.7 |
| IT-NAV-003 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 |
| IT-NAV-004 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 |
| IT-NAV-005 | `01-navigation-and-continuity.md` | READY | DEV-LINK | SETUP-EMPTY | CLEAN-RESET | M4.1 |
| IT-NAV-006 | `01-navigation-and-continuity.md` | READY | UI-RESTART | SETUP-EMPTY | CLEAN-RESET | UC-02, UC-03, UC-04, UC-08, M4.12 |
| IT-NAV-007 | `01-navigation-and-continuity.md` | READY | UI-DEVICE | SETUP-TREE-CARD | CLEAN-RESET | M5, AD-01 |
| IT-NAV-008 | `01-navigation-and-continuity.md` | READY | UI | SETUP-STUDY-SCOPE | CLEAN-RESET | UC-05, BR-101, M5.15 |
| IT-NAV-009 | `01-navigation-and-continuity.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-05, BR-101, BR-146, M5.15 |
| IT-NAV-010 | `01-navigation-and-continuity.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05 A3, BR-82, docs/wireframes/m5-study-modes.md |

## Vòng đời bộ thẻ gốc

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-DECK-001 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-11 |
| IT-DECK-002 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-D-SM2 | CLEAN-RESET | UC-02, BR-02 |
| IT-DECK-003 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-01, BR-11 |
| IT-DECK-004 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-01 |
| IT-DECK-005 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02 A1 |
| IT-DECK-006 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-D-EB | CLEAN-RESET | UC-03, BR-01 |
| IT-DECK-007 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-03 A4, BR-04 |
| IT-DECK-008 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-TREE-CARD | CLEAN-RESET | UC-03, BR-03, BR-04 |

## Cây bộ thẻ và loại nội dung

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-TREE-001 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-D-EB | CLEAN-RESET | UC-08, BR-58, BR-59 |
| IT-TREE-002 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-TREE-UNSET | CLEAN-RESET | UC-08, BR-60, BR-61 |
| IT-TREE-003 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-TREE-UNSET | CLEAN-RESET | UC-08, BR-62, BR-63 |
| IT-TREE-004 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-UNSET-CHILD:Grammar | CLEAN-RESET | UC-08, BR-62, BR-64 |
| IT-TREE-005 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-UNSET-CHILD:Unclassified | CLEAN-RESET | UC-08 E1, BR-62 |
| IT-TREE-006 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-DECK-TYPED-WITH-CHILD | CLEAN-RESET | UC-08 A3, BR-67 |
| IT-TREE-007 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-DECK-TYPED-EMPTY | CLEAN-RESET | UC-03 A3, BR-68 |
| IT-TREE-008 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-TREE-UNSET | CLEAN-RESET | UC-03 E3, BR-68 |
| IT-TREE-009 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-MOVE-TREE | CLEAN-RESET | UC-09, BR-71 |
| IT-TREE-010 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-CYCLE-TREE | CLEAN-RESET | UC-09 E1, BR-69, BR-70 |
| IT-TREE-011 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-MOVE-TREE | CLEAN-RESET | UC-09 E2, BR-64 |
| IT-TREE-012 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-CROSS-SCHEDULER-MOVE | CLEAN-RESET | UC-09 E3, BR-73, BR-74 |
| IT-TREE-013 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-DEEP-10 | CLEAN-RESET | UC-08 E4, UC-09 E5, BR-55 |
| IT-TREE-014 | `03-deck-tree-and-content-type.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-03 A3, BR-67, BR-68 |

## Khám phá bộ thẻ và tiến độ

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-DISC-001 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-142, BR-150 |
| IT-DISC-002 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06 A1, BR-29 |
| IT-DISC-003 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-142, BR-150 |
| IT-DISC-004 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-29 |
| IT-DISC-005 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-ROOT-TRIO | CLEAN-RESET | UC-06 |
| IT-DISC-006 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-SEARCH-TREES | CLEAN-RESET | UC-06 A3, BR-56, BR-57 |
| IT-DISC-007 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-D-EB | CLEAN-RESET | UC-06 |
| IT-DISC-008 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 A2, BR-22 |

## Vòng đời thẻ

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-CARD-001 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04 A3 |
| IT-CARD-002 | `05-card-lifecycle.md` | READY | UI-RESTART | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04, BR-07, BR-09 |
| IT-CARD-003 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04 E1, BR-07 |
| IT-CARD-004 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04, BR-08 |
| IT-CARD-005 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04, BR-95 |
| IT-CARD-006 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | BR-95 |
| IT-CARD-007 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-04 A4 |
| IT-CARD-008 | `05-card-lifecycle.md` | READY | UI-RESTART | SETUP-CARD-BASIC | CLEAN-RESET | UC-04 A1, BR-10 |
| IT-CARD-009 | `05-card-lifecycle.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-PROGRESS | CLEAN-RESET | UC-04 A1, BR-10, BR-92 |
| IT-CARD-010 | `05-card-lifecycle.md` | READY | UI-RESTART | SETUP-CARD-BASIC | CLEAN-RESET | UC-04 A2 |
| IT-CARD-011 | `05-card-lifecycle.md` | READY | UI | SETUP-CARD-SINGLE | CLEAN-RESET | UC-04 A2, BR-67 |

## Khám phá và tổ chức thẻ

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-ORG-001 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-BASIC | CLEAN-RESET | UC-04, S1 |
| IT-ORG-002 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-BASIC | CLEAN-RESET | UC-04, S1 |
| IT-ORG-003 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-04, BR-142, BR-151 |
| IT-ORG-004 | `06-card-discovery-and-organization.md` | READY | UI-RESTART | SETUP-CARD-PLAIN | CLEAN-RESET | BR-92 |
| IT-ORG-005 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | BR-90, BR-92, BR-142, BR-151 |
| IT-ORG-006 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | BR-92 |
| IT-ORG-007 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-PLAIN | CLEAN-RESET | BR-93 |
| IT-ORG-008 | `06-card-discovery-and-organization.md` | READY | UI-RESTART | SETUP-CARD-TAGS | CLEAN-RESET | BR-93 |
| IT-ORG-009 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-SINGLE | CLEAN-RESET | BR-93, BR-94 |
| IT-ORG-010 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-PROGRESS | CLEAN-RESET | BR-89, BR-90, BR-91 |
| IT-ORG-011 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-04, UC-06 |
| IT-ORG-012 | `06-card-discovery-and-organization.md` | READY | UI-LARGE | S-LARGE | CLEAN-RESET | M4.11 W1b |

## Điểm vào chức năng học và tùy chọn

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-STUDY-001 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-05, BR-142, BR-150, BR-151 |
| IT-STUDY-002 | `07-study-entry-and-options.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05, BR-101 |
| IT-STUDY-003 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-CLOCK | S-STUDY-FUTURE-EB-V2 | CLEAN-RESET | UC-05 E1, BR-29, BR-145 |
| IT-STUDY-004 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-05, BR-99, BR-146, BR-154 |
| IT-STUDY-005 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | UC-05, BR-30, BR-146 |
| IT-STUDY-006 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-MINIMAL-V2 | CLEAN-RESET | UC-05, BR-99, BR-100, BR-121, BR-153 |
| IT-STUDY-007 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-05, BR-114, BR-154 |
| IT-STUDY-008 | `07-study-entry-and-options.md` | READY | UI-RESTART | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-147, BR-148 |
| IT-STUDY-009 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-MULTI | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-06, BR-139, BR-147 |
| IT-STUDY-010 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-MULTI | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-24, BR-139 |
| IT-STUDY-011 | `07-study-entry-and-options.md` | READY | UI | SETUP-STUDY-SCOPE | CLEAN-RESET | UC-05, BR-23, BR-142 |
| IT-STUDY-012 | `07-study-entry-and-options.md` | READY | UI-RESTART | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-102, BR-139, BR-148 |
| IT-STUDY-013 | `07-study-entry-and-options.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-BROKEN-OPTIONS-V2 | CLEAN-RESET | BR-24, BR-147, BR-148, M5.11 |

## Phiên học thẻ mới

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-LEARN-001 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05, BR-97, BR-108, BR-109, BR-110 |
| IT-LEARN-002 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-SM2-4 | CLEAN-RESET | UC-05, BR-109, BR-110 |
| IT-LEARN-003 | `08-study-learning-session.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-111, BR-112 |
| IT-LEARN-004 | `08-study-learning-session.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-102, BR-113, BR-117, BR-127 |
| IT-LEARN-005 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-5-PLAIN | CLEAN-RESET | UC-05 A0b, BR-114, BR-140, BR-144 |
| IT-LEARN-006 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-4 | CLEAN-RESET | BR-99, BR-121, BR-124, BR-140 |
| IT-LEARN-007 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-1 | CLEAN-RESET | BR-99, BR-153 |
| IT-LEARN-008 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-115, BR-116, BR-119 |
| IT-LEARN-009 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-SM2-4 | CLEAN-RESET | UC-05 A2b, BR-26, BR-28, BR-92, BR-104 |
| IT-LEARN-010 | `08-study-learning-session.md` | READY | UI-CLOCK | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-13, BR-27, BR-105, BR-144, BR-145, BR-149 |
| IT-LEARN-011 | `08-study-learning-session.md` | READY | UI | SETUP-STUDY-EB-21 | CLEAN-RESET | BR-24, BR-139 |
| IT-LEARN-012 | `08-study-learning-session.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05 A3, BR-82, BR-86, BR-144 |

## Phiên ôn tập

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-REVIEW-001 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-05, BR-142 |
| IT-REVIEW-002 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-109, BR-146 |
| IT-REVIEW-003 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | BR-30, BR-106, BR-146 |
| IT-REVIEW-004 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-23, BR-24, BR-102, BR-139 |
| IT-REVIEW-005 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-20, BR-21, BR-75, BR-76, BR-77, BR-78, BR-141, BR-143 |
| IT-REVIEW-006 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-CLOCK | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-15, BR-16, BR-105 |
| IT-REVIEW-007 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-CLOCK | S-STUDY-REVIEW-SM2-V2 | CLEAN-RESET | BR-17, BR-18, BR-19, BR-105 |
| IT-REVIEW-008 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-CLOCK | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-105, BR-145 |
| IT-REVIEW-009 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | UC-05 A4, BR-24 |
| IT-REVIEW-010 | `09-study-review-session.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-REVIEW-EB-V2 | CLEAN-RESET | BR-99, BR-114, BR-154 |

## Các chế độ học

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-MODE-001 | `10-study-modes.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-05, BR-98, BR-142 |
| IT-MODE-002 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-111, BR-112 |
| IT-MODE-003 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-115, docs/wireframes/m5-study-modes.md |
| IT-MODE-004 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-107, BR-116, BR-118, BR-120 |
| IT-MODE-005 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-121, BR-125, BR-126 |
| IT-MODE-006 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-4 | CLEAN-RESET | BR-99, BR-121, BR-124 |
| IT-MODE-007 | `10-study-modes.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-117, BR-127 |
| IT-MODE-008 | `10-study-modes.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-128, BR-129 |
| IT-MODE-009 | `10-study-modes.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-128, BR-130, BR-131, BR-133 |
| IT-MODE-010 | `10-study-modes.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-FILL-V2 | CLEAN-RESET | BR-134, BR-137, BR-138 |
| IT-MODE-011 | `10-study-modes.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-FILL-V2 | CLEAN-RESET | BR-135, BR-136, BR-137, BR-138 |
| IT-MODE-012 | `10-study-modes.md` | READY | UI | SETUP-STUDY-ALL-MODES | CLEAN-RESET | BR-30, BR-106, BR-112, BR-146 |
| IT-MODE-013 | `10-study-modes.md` | READY | UI-DEVICE | SETUP-STUDY-ALL-MODES | CLEAN-RESET | M5.16, docs/wireframes/m5-study-modes.md |
| IT-MODE-014 | `10-study-modes.md` | FIXTURE-BLOCKED | UI-FAULT | S-STUDY-GUESS-BLOCKED-V2 | CLEAN-RESET | BR-121, BR-124 |
| IT-MODE-015 | `10-study-modes.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-STUDY-GUESS-SOURCE-V2 | CLEAN-RESET | BR-121, BR-122, BR-123 |

## Tiếp tục phiên học và lỗi

| ID | Tệp | Mức sẵn sàng | Hồ sơ | Chuẩn bị | Dọn dẹp | Truy vết |
|---|---|---|---|---|---|---|
| IT-CONT-001 | `11-study-continuity-and-failures.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05 A3b, BR-79, BR-102, BR-103 |
| IT-CONT-002 | `11-study-continuity-and-failures.md` | READY | UI-RESTART | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-82, BR-103 |
| IT-CONT-003 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-CLOCK | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05 A3b, BR-80, BR-86, BR-103 |
| IT-CONT-004 | `11-study-continuity-and-failures.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-05 A3, BR-82, BR-86 |
| IT-CONT-005 | `11-study-continuity-and-failures.md` | READY | UI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | BR-81, M5.10 |
| IT-CONT-006 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-MULTI | S-STUDY-RESUME-V2 | CLEAN-RESET | BR-102, BR-139 |
| IT-CONT-007 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-MULTI | S-STUDY-RESUME-V2 | CLEAN-RESET | UC-05 A5 |
| IT-CONT-008 | `11-study-continuity-and-failures.md` | READY | UI-DEVICE | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | AD-01, UC-05 |
| IT-CONT-009 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-MULTI | SETUP-STUDY-EB-5-FULL | CLEAN-RESET | UC-07, BR-83, BR-152, M5.14 |
| IT-CONT-010 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-MULTI | S-STUDY-RESUME-V2 | CLEAN-RESET | UC-05 E4, BR-46, BR-84 |
| IT-CONT-011 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-FAULT | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-05 E2, BR-25 |
| IT-CONT-012 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-FAULT | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-05 E3, BR-85, BR-86 |
| IT-CONT-013 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-FAULT | S-STUDY-FAILURE-V2 | CLEAN-RESET | UC-05 E5 |
| IT-CONT-014 | `11-study-continuity-and-failures.md` | FIXTURE-BLOCKED | UI-RESTART | S-STUDY-MIXED-EB-V2 | CLEAN-RESET | UC-05, BR-82, BR-103 |

## Bất biến của danh mục

- Mỗi tiêu đề `## IT-...` trong mười một tệp kịch bản MUST có đúng một dòng trong danh mục.
- Danh mục MUST NOT chứa ID không có kịch bản gốc.
- Mức sẵn sàng, hồ sơ thực thi, chuẩn bị và dọn dẹp MUST dùng giá trị được định nghĩa
  trong hướng dẫn thực thi.
- Cột truy vết MUST có ít nhất một UC, BR, AD, nhiệm vụ WBS hoặc ID phạm vi đã chốt.
- Khi thêm kịch bản, agent MUST cập nhật danh mục trong cùng thay đổi.
