# Catalog thực thi IT scenario cho AI agent

| | |
|---|---|
| **Status** | active |
| **Purpose** | Lập chỉ mục từng scenario với readiness, execution profile, setup, cleanup và traceability để agent chọn test không suy đoán |
| **Scope** | Toàn bộ IT scenario hiện có trong `docs/it-scenarios`; không chứa lại các bước thao tác |
| **Source of truth for** | Readiness, profile, setup, cleanup và traceability theo từng IT scenario ID |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, sáu file scenario theo capability |
| **Updated by task** | Yêu cầu làm tài liệu thân thiện với AI agent ngày 2026-08-05 |
| **Last updated** | 2026-08-05 |

Agent MUST tìm ID ở catalog này trước khi chạy. `File` chỉ tới tài liệu chứa các
bước gốc. Ý nghĩa status/profile/setup/cleanup nằm trong
[`00-agent-execution-guide.md`](00-agent-execution-guide.md).

## Navigation và continuity

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
|---|---|---|---|---|---|---|
| IT-NAV-001 | `01-navigation-and-continuity.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-06 |
| IT-NAV-002 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-UNSET | CLEAN-RESET | M4.10a |
| IT-NAV-003 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 |
| IT-NAV-004 | `01-navigation-and-continuity.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 |
| IT-NAV-005 | `01-navigation-and-continuity.md` | READY | DEV-LINK | SETUP-EMPTY | CLEAN-RESET | M4.1 |
| IT-NAV-006 | `01-navigation-and-continuity.md` | READY | UI-RESTART | SETUP-EMPTY | CLEAN-RESET | UC-02, UC-03, UC-04, UC-08, M4.12 |
| IT-NAV-007 | `01-navigation-and-continuity.md` | READY | UI-DEVICE | SETUP-TREE-CARD | CLEAN-RESET | M5, AD-01 |

## Root deck lifecycle

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
|---|---|---|---|---|---|---|
| IT-DECK-001 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-11 |
| IT-DECK-002 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-D-SM2 | CLEAN-RESET | UC-02, BR-02 |
| IT-DECK-003 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-01, BR-11 |
| IT-DECK-004 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02, BR-01 |
| IT-DECK-005 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-EMPTY | CLEAN-RESET | UC-02 A1 |
| IT-DECK-006 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-D-EB | CLEAN-RESET | UC-03, BR-01 |
| IT-DECK-007 | `02-root-deck-lifecycle.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-03 A4, BR-04 |
| IT-DECK-008 | `02-root-deck-lifecycle.md` | READY | UI-RESTART | SETUP-TREE-CARD | CLEAN-RESET | UC-03, BR-03, BR-04 |

## Deck tree và content type

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
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
| IT-TREE-014 | `03-deck-tree-and-content-type.md` | KNOWN-GAP | UI | SETUP-CARD-EMPTY-TYPED | CLEAN-RESET | UC-03 A3, BR-67, BR-68 |

## Deck discovery và progress

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
|---|---|---|---|---|---|---|
| IT-DISC-001 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-22 |
| IT-DISC-002 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06 A1, BR-29 |
| IT-DISC-003 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-22 |
| IT-DISC-004 | `04-deck-discovery-and-progress.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-06, BR-29 |
| IT-DISC-005 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-ROOT-TRIO | CLEAN-RESET | UC-06 |
| IT-DISC-006 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-SEARCH-TREES | CLEAN-RESET | UC-06 A3, BR-56, BR-57 |
| IT-DISC-007 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-D-EB | CLEAN-RESET | UC-06 |
| IT-DISC-008 | `04-deck-discovery-and-progress.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-06 A2, BR-22 |

## Card lifecycle

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
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

## Card discovery và organization

| ID | File | Readiness | Profile | Setup | Cleanup | Trace |
|---|---|---|---|---|---|---|
| IT-ORG-001 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-BASIC | CLEAN-RESET | UC-04, S1 |
| IT-ORG-002 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-BASIC | CLEAN-RESET | UC-04, S1 |
| IT-ORG-003 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | UC-04, BR-22 |
| IT-ORG-004 | `06-card-discovery-and-organization.md` | READY | UI-RESTART | SETUP-CARD-PLAIN | CLEAN-RESET | BR-92 |
| IT-ORG-005 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-DUE | CLEAN-RESET | BR-22, BR-90, BR-92 |
| IT-ORG-006 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | BR-92 |
| IT-ORG-007 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-PLAIN | CLEAN-RESET | BR-93 |
| IT-ORG-008 | `06-card-discovery-and-organization.md` | READY | UI-RESTART | SETUP-CARD-TAGS | CLEAN-RESET | BR-93 |
| IT-ORG-009 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-CARD-SINGLE | CLEAN-RESET | BR-93, BR-94 |
| IT-ORG-010 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-FIXTURE | S-PROGRESS | CLEAN-RESET | BR-89, BR-90, BR-91 |
| IT-ORG-011 | `06-card-discovery-and-organization.md` | READY | UI | SETUP-TREE-CARD | CLEAN-RESET | UC-04, UC-06 |
| IT-ORG-012 | `06-card-discovery-and-organization.md` | FIXTURE-BLOCKED | UI-LARGE | S-LARGE | CLEAN-RESET | M4.11 W1b |

## Catalog invariants

- Mỗi heading `## IT-...` trong sáu file scenario MUST có đúng một dòng catalog.
- Catalog MUST NOT chứa ID không có scenario gốc.
- `Readiness`, `Profile`, `Setup` và `Cleanup` MUST dùng giá trị được định nghĩa
  trong execution guide.
- `Trace` MUST có ít nhất một UC, BR, AD, WBS task hoặc scope ID đã chốt.
- Khi thêm scenario, agent MUST cập nhật catalog trong cùng thay đổi.
