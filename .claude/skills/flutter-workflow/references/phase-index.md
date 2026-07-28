# Phase → skill index

Full mapping from `docs/checklist.md` to the skill that owns each section.
Load only the skill you need; they are written to stand alone.

| Phase | Section | Owning skill |
|---|---|---|
| 0.1 | Xác định bài toán | `flutter-product-spec` |
| 0.2 | Xác định phạm vi MVP | `flutter-product-spec` |
| 0.3 | Đặc tả nghiệp vụ (use cases, business rules) | `flutter-product-spec` |
| 1.1 | Xây dựng WBS | `flutter-product-spec` |
| 1.2 | Quản lý tài liệu | `flutter-product-spec` |
| 2.1 | Công cụ phát triển | `flutter-project-setup` |
| 2.2 | Khởi tạo repository | `flutter-project-setup` |
| 2.3 | Khởi tạo Flutter project | `flutter-project-setup` |
| 3.1 | Dependencies chính | `flutter-project-setup` |
| 3.2 | Dev dependencies | `flutter-project-setup` |
| 3.3 | Kiểm soát dependency | `flutter-project-setup` |
| 4.1 | Cấu trúc thư mục | `flutter-architecture` |
| 4.2 | Dependency rules | `flutter-architecture` |
| 4.3 | Quy tắc kiến trúc thực dụng | `flutter-architecture` |
| 5.1 | Cấu hình lint | `flutter-architecture` |
| 5.2 | Quy tắc viết code | `flutter-architecture` |
| 5.3 | Quy tắc đặt tên | `flutter-architecture` |
| 6.1 | Bootstrap | `flutter-project-setup` |
| 6.2 | Environment và flavor | `flutter-project-setup` |
| 6.3 | Error model | `flutter-project-setup` |
| 7.1 | Design tokens | `flutter-design-system` |
| 7.2 | Theme | `flutter-design-system` |
| 7.3 | Component library | `flutter-design-system` |
| 7.4 | Responsive design | `flutter-design-system` |
| 8.1 | Router foundation | `flutter-navigation` |
| 8.2 | Navigation rules | `flutter-navigation` |
| 9.1 | Provider design | `flutter-state-riverpod` |
| 9.2 | UI state | `flutter-state-riverpod` |
| 9.3 | Side effects | `flutter-state-riverpod` |
| 10.1 | Dio configuration | `flutter-data-layer` |
| 10.2 | API contract | `flutter-data-layer` |
| 10.3 | Network resilience | `flutter-data-layer` |
| 11.1 | Drift database | `flutter-data-layer` |
| 11.2 | Cache strategy | `flutter-data-layer` |
| 11.3 | Secure storage | `flutter-data-layer` |
| 12 | Localization | `flutter-design-system` |
| 13 | Accessibility | `flutter-design-system` |
| 14.1–14.5 | Xây dựng từng feature | `flutter-feature-slice` |
| 15.1 | Unit test | `flutter-testing` |
| 15.2 | Riverpod/controller test | `flutter-testing` |
| 15.3 | Widget test | `flutter-testing` |
| 15.4 | Golden test | `flutter-testing` |
| 15.5 | Integration/E2E test | `flutter-testing` |
| 16 | Security | `flutter-ship` |
| 17 | Performance | `flutter-ship` |
| 18 | Logging, analytics, monitoring | `flutter-ship` |
| 19 | CI/CD | `flutter-ship` |
| 20 | Chuẩn bị phát hành | `flutter-ship` |
| 21 | Release checklist | `flutter-ship` |
| 22 | Sau khi phát hành | `flutter-ship` |

## Why the grouping looks like this

Phases were grouped by *when you actually think about them together*, not by
their number:

- **6 (bootstrap/flavors/errors) sits with 2–3, not on its own.** Bootstrap,
  flavors and the error model are all decisions you make once while standing the
  project up, and they constrain each other — the flavor determines the log level
  that the bootstrap installs, and the error model determines what the error
  boundary reports.
- **12 (localization) and 13 (a11y) sit with 7 (design system).** Both are
  properties of how components are written. A component built without a semantic
  label or with a hardcoded string has to be reopened later; folding these into
  the design-system skill makes them part of building a component rather than a
  retrofit pass.
- **16–22 are one skill.** They share a trigger — the project is heading toward
  release — and in practice you touch several of them in the same session.
- **14 stays alone** because it is the loop you run dozens of times, and it
  composes the other skills rather than duplicating them.
