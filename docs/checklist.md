# 🚀 Flutter Project Development Checklist

> **Architecture:** Pragmatic Clean Architecture — Feature First
> **State Management & DI:** Riverpod 3.x + Code Generation
> **Navigation:** GoRouter
> **HTTP Client:** Dio
> **Local Database:** Drift + SQLite
> **UI:** Material 3 + Design Tokens
> **Code Style:** Guard Clauses, Early Return, Fail Fast, hạn chế `else`

Đây là tài liệu gốc (source of truth) cho toàn bộ quá trình phát triển.
Tiến độ thực tế được theo dõi ở [`wbs.md`](wbs.md).
Mỗi phase có một skill tương ứng trong `.claude/skills/` — xem
[`.claude/skills/flutter-workflow/references/phase-index.md`](../.claude/skills/flutter-workflow/references/phase-index.md).

---

## Phase 0: Phân tích sản phẩm

### 0.1. Xác định bài toán
- [ ] Xác định vấn đề ứng dụng cần giải quyết.
- [ ] Xác định nhóm người dùng chính.
- [ ] Xác định giá trị cốt lõi của ứng dụng.
- [ ] Xác định nền tảng hỗ trợ: Android / iOS / Web / Windows / macOS.
- [ ] Xác định ứng dụng: Online-first / Offline-first / Hybrid.
- [ ] Xác định yêu cầu đăng nhập và phân quyền.
- [ ] Xác định dữ liệu nhạy cảm cần bảo vệ.

### 0.2. Xác định phạm vi MVP
- [ ] Liệt kê toàn bộ tính năng dự kiến.
- [ ] Phân loại: Must-have / Should-have / Nice-to-have / Không thuộc MVP.
- [ ] Xác định luồng nghiệp vụ chính.
- [ ] Xác định điều kiện hoàn thành cho từng tính năng.
- [ ] Không đưa tính năng chưa cần thiết vào MVP.

### 0.3. Đặc tả nghiệp vụ
- [ ] Viết danh sách use case.
- [ ] Mỗi use case có: Actor, Trigger, Preconditions, Main flow, Alternative flow, Error flow, Postconditions.
- [ ] Xác định business rules.
- [ ] Xác định validation rules.
- [ ] Xác định trạng thái của từng entity.
- [ ] Xác định các trường hợp biên.

---

## Phase 1: Lập kế hoạch dự án

### 1.1. Xây dựng WBS
- [ ] Chia dự án thành milestone → feature → task nhỏ.
- [ ] Mỗi task có: Mục tiêu, Phạm vi, Output, Acceptance criteria, Dependency, Test yêu cầu.
- [ ] Xác định thứ tự triển khai.
- [ ] Không triển khai UI trước khi business flow được chốt.

### 1.2. Quản lý tài liệu
- [ ] Tạo thư mục `docs/`.
- [ ] Chuẩn bị: Product requirements, Use cases, Business rules, Architecture overview,
      Data model, API specification, Design system, Testing strategy, WBS, Release checklist.
- [ ] Tài liệu và source code phải được cập nhật đồng bộ.

---

## Phase 2: Thiết lập môi trường

### 2.1. Công cụ phát triển
- [ ] Cài Flutter stable, Dart SDK tương thích.
- [ ] Chạy `flutter doctor`.
- [ ] Cài Android Studio + Android SDK; Xcode nếu build iOS.
- [ ] Cấu hình emulator và thiết bị thật.
- [ ] Kiểm tra build: Android / iOS / Web.

### 2.2. Khởi tạo repository
- [ ] Tạo Git repository, cấu hình `.gitignore`.
- [ ] Chọn branching strategy: Trunk-based / Git Flow.
- [ ] Quy tắc đặt tên branch. Conventional Commits.
- [ ] Pull request template, issue template.
- [ ] Bật branch protection. Không merge trực tiếp vào branch chính.

### 2.3. Khởi tạo Flutter project
- [ ] Tạo project với organization đúng; kiểm tra package name / application ID.
- [ ] Đặt tên app cho từng môi trường; cấu hình minimum SDK.
- [ ] Xóa code demo mặc định. `main.dart` chỉ bootstrap.
- [ ] Đảm bảo project build sạch trước khi phát triển tiếp.

---

## Phase 3: Dependencies và cấu hình nền tảng

### 3.1. Dependencies chính
- [ ] State: `flutter_riverpod`, `riverpod_annotation`.
- [ ] Navigation: `go_router`.
- [ ] Networking: `dio`.
- [ ] Local DB: `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`.
- [ ] Model: `freezed_annotation`, `json_annotation`.
- [ ] Utilities: `intl`, `collection`, `uuid`.
- [ ] Secure data: `flutter_secure_storage` khi cần.

### 3.2. Dev dependencies
- [ ] `build_runner`, `riverpod_generator`, `riverpod_lint`, `drift_dev`,
      `freezed`, `json_serializable`, `custom_lint`, `mocktail`, golden test utilities nếu cần.

### 3.3. Kiểm soát dependency
- [ ] Không thêm package khi chưa xác định rõ lý do.
- [ ] Không dùng nhiều thư viện cho cùng một nhiệm vụ.
- [ ] Kiểm tra license và mức độ duy trì của package.
- [ ] Không dùng package đã ngừng phát triển.
- [ ] Cố định phiên bản phù hợp; kiểm tra định kỳ; loại bỏ dependency không dùng.

---

## Phase 4: Kiến trúc dự án

### 4.1. Cấu trúc thư mục

```
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── router/
│   └── config/
├── core/
│   ├── error/
│   ├── network/
│   ├── database/
│   ├── storage/
│   ├── logging/
│   ├── theme/
│   ├── localization/
│   └── utils/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── extensions/
├── features/
│   └── feature_name/
│       ├── data/
│       │   ├── local/
│       │   ├── remote/
│       │   ├── model/
│       │   └── repository/
│       ├── domain/
│       │   ├── entity/
│       │   ├── repository/
│       │   └── usecase/
│       └── presentation/
│           ├── screen/
│           ├── widget/
│           ├── state/
│           └── controller/
└── main.dart
```

### 4.2. Dependency rules
- [ ] Presentation chỉ gọi use case hoặc repository contract phù hợp.
- [ ] Domain không import Flutter.
- [ ] Domain không phụ thuộc Dio, Drift hoặc framework.
- [ ] Data triển khai repository contract.
- [ ] Feature không truy cập trực tiếp implementation của feature khác.
- [ ] `core/` không chứa logic riêng của một feature.
- [ ] `shared/` chỉ chứa thành phần thực sự tái sử dụng.
- [ ] Không tạo shared widget chỉ vì hai đoạn UI trông gần giống nhau.
- [ ] Không tạo circular dependency.

### 4.3. Quy tắc kiến trúc thực dụng
- [ ] Feature đơn giản không bắt buộc phải có mọi layer.
- [ ] Chỉ tạo use case khi có business logic hoặc khả năng tái sử dụng.
- [ ] Không tạo interface chỉ để bọc một implementation không có nhu cầu thay thế.
- [ ] Không over-engineering từ đầu.
- [ ] Ưu tiên khả năng mở rộng nhưng giữ code dễ đọc.

---

## Phase 5: Code conventions và lint

### 5.1. Cấu hình lint
- [ ] Tạo `analysis_options.yaml`.
- [ ] Bật `strict-casts`, `strict-inference`, `strict-raw-types`.
- [ ] Tích hợp `riverpod_lint`.
- [ ] Bật kiểm tra async: `unawaited_futures`, `discarded_futures`, `avoid_void_async`.
- [ ] Bật quy tắc immutability và `prefer_const_*`.
- [ ] Coi các lỗi quan trọng là error thay vì warning.
- [ ] Không merge khi còn analyzer error.

### 5.2. Quy tắc viết code
- [ ] Guard clauses, return sớm, throw sớm, hạn chế/loại bỏ `else`.
- [ ] Không magic string / magic number.
- [ ] Dùng enum hoặc sealed class cho trạng thái hữu hạn.
- [ ] Ưu tiên immutable state. Một class một trách nhiệm.
- [ ] Không file hàng nghìn dòng; không widget quá lớn.
- [ ] Không business logic trong `build()`.
- [ ] Không gọi API trực tiếp trong widget; không thao tác database từ UI.
- [ ] Không lạm dụng extension.
- [ ] Không che giấu lỗi bằng `catch (_) {}`.
- [ ] Không dùng `dynamic` nếu có thể xác định kiểu.

### 5.3. Quy tắc đặt tên
- [ ] Tên class thể hiện đúng trách nhiệm.
- [ ] Boolean bắt đầu bằng `is`, `has`, `can`, `should`.
- [ ] Suffix nhất quán: `*_screen.dart`, `*_widget.dart`, `*_controller.dart`, `*_state.dart`,
      `*_repository.dart`, `*_repository_impl.dart`, `*_use_case.dart`, `*_model.dart`, `*_entity.dart`.
- [ ] Không dùng tên chung chung như `Utils`, `Manager`, `Helper` nếu trách nhiệm không rõ.

---

## Phase 6: App foundation

### 6.1. Bootstrap
- [ ] Tạo hàm bootstrap riêng.
- [ ] Khởi tạo logging, database, local storage, environment config.
- [ ] Thiết lập `ProviderScope` và error boundary.
- [ ] Bắt uncaught Flutter errors và uncaught async errors.
- [ ] Không thực hiện logic khởi tạo phức tạp trực tiếp trong `main()`.

### 6.2. Environment và flavor
- [ ] Tạo Development / Staging / Production.
- [ ] Mỗi flavor có: App name, Application ID, API base URL, Logging level, Feature flags, Analytics config.
- [ ] Không hardcode environment trong source code.
- [ ] Không commit secret. Không dùng production credentials trong development.

### 6.3. Error model
- [ ] Chuẩn hóa loại lỗi: Network, Unauthorized, Forbidden, Validation, Not found, Conflict, Database, Unknown.
- [ ] Tạo `Failure` hoặc sealed result type.
- [ ] Mapping exception tầng data sang failure tầng ứng dụng.
- [ ] UI không phụ thuộc trực tiếp vào Dio exception.
- [ ] Error message cho người dùng không lộ thông tin kỹ thuật.

---

## Phase 7: Design system

### 7.1. Design tokens
- [ ] Token cho: Colors, Typography, Spacing, Radius, Border, Elevation, Icon size, Animation duration, Breakpoints.
- [ ] Nhịp spacing nhất quán: 4 / 8 / 12 / 16 / 24 / 32.
- [ ] Không hardcode màu trong feature widget.
- [ ] Không hardcode `TextStyle`. Không padding ngẫu nhiên.
- [ ] Token phải có semantic name, không chỉ tên màu vật lý.

### 7.2. Theme
- [ ] Bật Material 3. Tạo light theme, dark theme, `ColorScheme`.
- [ ] Cấu hình: AppBar, Navigation bar, Card, Dialog, Bottom sheet, Input, Button, Chip, Snackbar.
- [ ] Kiểm tra contrast.
- [ ] Kiểm tra trạng thái disabled, pressed, focused, selected.

### 7.3. Component library
- [ ] App scaffold, App bar, Primary button, Secondary button, Icon button, Text field,
      Search field, Card, List item, Empty state, Error state, Loading state,
      Confirmation dialog, Bottom sheet.
- [ ] Mỗi component có: Light mode, Dark mode, Enabled, Disabled, Loading, Error state nếu phù hợp.
- [ ] Không biến component thành widget "vạn năng" với quá nhiều tham số.

### 7.4. Responsive design
- [ ] Mobile-first. Không dựa vào một kích thước màn hình cố định.
- [ ] Kiểm tra màn hình nhỏ, text scale lớn, bàn phím mở, landscape.
- [ ] Dùng `LayoutBuilder`, constraints và breakpoint hợp lý.
- [ ] Không dùng `MediaQuery` tràn lan.
- [ ] Không để button/text bị bottom navigation che.
- [ ] Không để action nằm sát mép màn hình.

---

## Phase 8: Navigation

### 8.1. Router foundation
- [ ] Dùng `MaterialApp.router`. Khai báo route tập trung.
- [ ] Dùng route path constant hoặc typed route.
- [ ] Cấu hình navigation shell, nested navigation, redirect, trang 404.
- [ ] Cấu hình authentication guard, deep link, restoration khi cần.

### 8.2. Navigation rules
- [ ] Widget không hardcode path string.
- [ ] Không truyền object lớn qua route extras nếu có thể dùng ID.
- [ ] Back behavior đúng trên Android và iOS.
- [ ] Không tạo navigation stack trùng.
- [ ] Bottom navigation giữ state hợp lý.
- [ ] Dialog và bottom sheet không phá luồng back.
- [ ] Deep link mở đúng màn hình ngay cả khi app cold start.

---

## Phase 9: State management với Riverpod

### 9.1. Provider design
- [ ] Ưu tiên `@riverpod`. Mỗi provider có trách nhiệm rõ ràng.
- [ ] Tách provider theo feature; không đặt tất cả provider trong một file.
- [ ] Không dùng global mutable state.
- [ ] Dùng `family` khi state phụ thuộc ID; dùng autoDispose hợp lý.
- [ ] Không giữ state màn hình đã đóng nếu không cần.
- [ ] Không watch provider lớn khi chỉ cần một phần state.

### 9.2. UI state
- [ ] Mỗi màn hình xác định rõ: Initial, Loading, Loaded, Empty, Error, Refreshing, Submitting.
- [ ] State là immutable.
- [ ] Phân biệt dữ liệu và trạng thái tác vụ.
- [ ] Không dùng một boolean `isLoading` cho mọi hoạt động.
- [ ] Không lưu `BuildContext` trong controller.
- [ ] UI chỉ render từ state và phát intent/action.

### 9.3. Side effects
- [ ] Navigation side effect không đặt tùy tiện trong `build()`.
- [ ] Snackbar/dialog được kích hoạt qua listener phù hợp.
- [ ] Không phát side effect nhiều lần khi widget rebuild.
- [ ] Async operation xử lý cancellation.
- [ ] Kiểm tra `context.mounted` sau `await` khi cần.

---

## Phase 10: Networking

### 10.1. Dio configuration
- [ ] Một HTTP client dùng chung.
- [ ] Cấu hình: Base URL, Connect/Receive/Send timeout, Default headers.
- [ ] Interceptor cho: Authentication, Logging, Error mapping, Token refresh, Request ID.
- [ ] Không log token và dữ liệu nhạy cảm.
- [ ] Không bật verbose log ở production.

### 10.2. API contract
- [ ] Model request và response tách biệt khi cần.
- [ ] Parse JSON type-safe. Không truyền raw JSON lên UI.
- [ ] Xử lý nullable field rõ ràng; xử lý backward compatibility.
- [ ] Mapping DTO sang domain entity.
- [ ] Chuẩn hóa pagination và error response.

### 10.3. Network resilience
- [ ] Xử lý mất kết nối, timeout, retry có giới hạn.
- [ ] Không retry request mutation một cách mù quáng.
- [ ] Chống gửi trùng request. Hủy request khi màn hình không còn cần.
- [ ] Có trạng thái offline rõ ràng.
- [ ] Đồng bộ dữ liệu khi kết nối trở lại nếu app offline-first.

---

## Phase 11: Local database và storage

### 11.1. Drift database
- [ ] Thiết kế schema; xác định primary key, foreign key.
- [ ] Tạo index cho truy vấn quan trọng.
- [ ] Dùng transaction cho thao tác nhiều bước.
- [ ] Không truy vấn toàn bộ bảng khi không cần.
- [ ] Tách DAO theo domain hoặc feature.
- [ ] Viết migration; test migration từ version cũ.
- [ ] Không xóa dữ liệu người dùng khi nâng version.

### 11.2. Cache strategy
- [ ] Xác định dữ liệu nào được cache, TTL, source of truth.
- [ ] Xác định chính sách stale data và conflict resolution.
- [ ] Chiến lược đồng bộ: Server wins / Client wins / Last-write-wins / Manual merge.
- [ ] Không để UI tự quyết định local hay remote source.

### 11.3. Secure storage
- [ ] Token lưu trong secure storage. Không lưu password dạng raw.
- [ ] Không lưu dữ liệu nhạy cảm trong shared preferences.
- [ ] Xóa token khi logout; xóa dữ liệu riêng tư khi người dùng yêu cầu.
- [ ] Xem xét mã hóa database nếu dữ liệu nhạy cảm.

---

## Phase 12: Localization

- [ ] Cấu hình Flutter ARB localization; tạo file ngôn ngữ gốc.
- [ ] Không hardcode text hiển thị.
- [ ] Hỗ trợ plural và placeholder.
- [ ] Format ngày giờ và số theo locale.
- [ ] Kiểm tra text dài hơn ở ngôn ngữ khác. Kiểm tra RTL nếu thuộc phạm vi.
- [ ] Không ghép câu từ nhiều localization key nhỏ.
- [ ] Có fallback khi thiếu translation.

---

## Phase 13: Accessibility

- [ ] Icon-only button có semantic label.
- [ ] Touch target đủ lớn. Text có contrast phù hợp.
- [ ] Không truyền tải thông tin chỉ bằng màu sắc.
- [ ] Hỗ trợ screen reader. Thứ tự focus hợp lý.
- [ ] Form field có label và error rõ ràng.
- [ ] Hỗ trợ text scaling. Animation không gây khó chịu.
- [ ] Kiểm tra reduced motion nếu cần.
- [ ] Kiểm tra app bằng accessibility scanner.

---

## Phase 14: Xây dựng từng feature

Áp dụng quy trình sau cho **mỗi** feature.

### 14.1. Trước khi code
- [ ] Use case đã được duyệt. Business rule đã rõ.
- [ ] Wireframe/design đã có. State matrix đã xác định.
- [ ] API contract đã rõ. Data model đã rõ.
- [ ] Acceptance criteria đã rõ.
- [ ] Đã xác định dependency với feature khác.

### 14.2. Domain
- [ ] Tạo entity/value object, repository contract.
- [ ] Tạo use case khi thực sự cần. Viết business validation.
- [ ] Không import Flutter hoặc package hạ tầng.

### 14.3. Data
- [ ] Tạo DTO, local data source, remote data source, mapper, repository implementation.
- [ ] Mapping exception thành failure.
- [ ] Xử lý cache và sync theo chiến lược đã thống nhất.

### 14.4. Presentation
- [ ] Tạo state, controller/provider, screen. Tách widget theo UI section.
- [ ] Dùng component và token hiện có. Không thay đổi thiết kế tùy ý.
- [ ] Không tạo shared component mới khi chưa cần.
- [ ] Cover loading, empty, error, success.
- [ ] Cover keyboard, small screen, dark mode.

### 14.5. Hoàn thành feature
- [ ] Unit test business logic. Test repository. Test controller state transitions.
- [ ] Widget test trạng thái quan trọng. Integration test luồng chính.
- [ ] Golden test component hoặc màn hình cần pixel parity.
- [ ] Cập nhật tài liệu và WBS.
- [ ] Không còn analyzer warning/error.

---

## Phase 15: Testing strategy

### 15.1. Unit test
- [ ] Test use case, repository, mapper, validator, utility quan trọng.
- [ ] Test database query và migration.
- [ ] Test network error mapping.
- [ ] Cover success, failure và edge case.

### 15.2. Riverpod/controller test
- [ ] Test initial state, loading → loaded, loading → error.
- [ ] Test refresh, submit thành công, submit thất bại.
- [ ] Test request trùng.
- [ ] Test state không cập nhật sau dispose.

### 15.3. Widget test
- [ ] Bọc widget bằng `ProviderScope`.
- [ ] Test text và action chính, loading, empty, error, validation.
- [ ] Test overflow trên màn hình nhỏ, dark mode, text scale.

### 15.4. Golden test
- [ ] Test component cơ sở, light mode, dark mode, kích thước mobile chuẩn.
- [ ] Ổn định font và rendering environment.
- [ ] Không dùng golden test cho nội dung biến động không kiểm soát.
- [ ] So sánh Flutter screen với design kit.
- [ ] Chỉ cho phép merge khi pixel difference nằm trong ngưỡng dự án, ví dụ dưới 3%.

### 15.5. Integration/E2E test
- [ ] Test bằng thao tác người dùng thực tế; resize viewport đúng kích thước thiết bị.
- [ ] Test: Cold start, Login/logout, Navigation chính, Create/update/delete,
      Offline/online, App restart, Deep link.
- [ ] Có thể dùng Flutter Web kết hợp Playwright để kiểm tra flow sớm.
- [ ] Sau cùng vẫn kiểm tra trên Android/iOS thật.

---

## Phase 16: Security

- [ ] Không commit API key, secret hoặc certificate.
- [ ] Sử dụng environment secret trong CI/CD.
- [ ] Validate dữ liệu đầu vào. Không tin dữ liệu từ client hoặc server tuyệt đối.
- [ ] Sanitize nội dung hiển thị nếu có HTML.
- [ ] Không log dữ liệu nhạy cảm. Bảo vệ token. Xử lý token hết hạn.
- [ ] Có cơ chế logout từ xa nếu cần.
- [ ] Xem xét certificate pinning với ứng dụng rủi ro cao.
- [ ] Kiểm tra dependency vulnerability.
- [ ] Obfuscate production build khi phù hợp.
- [ ] Kiểm tra quyền Android/iOS theo nguyên tắc tối thiểu.

---

## Phase 17: Performance

- [ ] Dùng `const` khi phù hợp. Giới hạn phạm vi rebuild.
- [ ] Dùng `select` khi chỉ cần một phần provider state.
- [ ] Không tính toán nặng trong `build()`. Đưa CPU nặng sang isolate.
- [ ] Pagination cho danh sách lớn. Lazy load dữ liệu.
- [ ] Cache ảnh hợp lý; resize/compress ảnh.
- [ ] Không render toàn bộ danh sách bằng `Column`.
- [ ] Tránh nested scroll không cần thiết.
- [ ] Dispose controller/subscription đúng cách.
- [ ] Profile bằng Flutter DevTools.
- [ ] Kiểm tra: Startup time, Frame rendering, Memory, Network, Database queries, App size.

---

## Phase 18: Logging, analytics và monitoring

- [ ] Tạo logging abstraction với log level: Debug / Info / Warning / Error.
- [ ] Tắt hoặc giảm log ở production.
- [ ] Tích hợp Crashlytics hoặc Sentry khi bước vào giai đoạn phát hành.
- [ ] Gửi stack trace có kiểm soát. Không gửi PII ngoài ý muốn.
- [ ] Xác định analytics events; chuẩn hóa event name và parameter.
- [ ] Theo dõi luồng chuyển đổi quan trọng.
- [ ] Theo dõi lỗi theo app version và device.
- [ ] Thiết lập alert cho crash nghiêm trọng.

---

## Phase 19: CI/CD

### 19.1. Continuous Integration
- [ ] Cài dependency.
- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze`.
- [ ] Chạy code generation; kiểm tra generated code không bị thiếu hoặc cũ.
- [ ] Chạy unit/widget tests và golden tests.
- [ ] Build Android; build iOS nếu runner hỗ trợ; build web nếu thuộc phạm vi.
- [ ] Không merge khi pipeline thất bại.

### 19.2. Pull request quality gate
- [ ] Scope PR nhỏ và rõ; có mô tả thay đổi; có liên kết WBS/issue.
- [ ] Có ảnh hoặc video với thay đổi UI; có kết quả test; có pixel diff với thay đổi UI.
- [ ] Không đổi public API không cần thiết. Không refactor ngoài phạm vi.
- [ ] Không thêm dependency không có lý do.
- [ ] Có ít nhất một reviewer phê duyệt.

### 19.3. Continuous Delivery
- [ ] Build theo flavor. Quản lý signing và version.
- [ ] Tạo artifact; upload internal testing.
- [ ] Phát hành staging trước production.
- [ ] Hỗ trợ rollback hoặc hotfix.

---

## Phase 20: Chuẩn bị phát hành

### 20.1. App metadata
- [ ] App name, App icon, Splash screen, Package ID, Version name, Build number.
- [ ] Store description, Screenshots, Feature graphic.
- [ ] Privacy policy, Support email, Terms of service nếu cần.

### 20.2. Android
- [ ] Cấu hình signing; build Android App Bundle.
- [ ] Kiểm tra permission, target SDK, ProGuard/R8.
- [ ] Kiểm tra deep link / app link, notification.
- [ ] Kiểm tra trên nhiều Android version.
- [ ] Upload internal testing; kiểm tra Play Console warning.

### 20.3. iOS
- [ ] Cấu hình bundle ID, certificate, provisioning profile, permission description.
- [ ] Kiểm tra universal link, push notification.
- [ ] Archive production build; upload TestFlight.
- [ ] Kiểm tra App Store Connect warning.

---

## Phase 21: Release checklist

- [ ] Tất cả acceptance criteria đã đạt.
- [ ] Không còn lỗi blocker hoặc critical.
- [ ] Analyzer sạch. Test suite pass. Build production thành công.
- [ ] Đã kiểm tra trên thiết bị thật; đã kiểm tra upgrade từ phiên bản trước.
- [ ] Database migration hoạt động. Deep link hoạt động. Offline behavior đúng.
- [ ] Analytics hoạt động. Crash reporting hoạt động.
- [ ] Privacy policy cập nhật. Release notes đã viết.
- [ ] Có kế hoạch rollback/hotfix. Stakeholder đã phê duyệt.

---

## Phase 22: Sau khi phát hành

- [ ] Theo dõi crash-free users, ANR, startup time.
- [ ] Theo dõi đánh giá trên store, API error rate, các flow thất bại.
- [ ] Thu thập phản hồi người dùng; phân loại bug theo severity.
- [ ] Tạo hotfix nếu cần. Review KPI sau phát hành.
- [ ] Cập nhật roadmap. Xóa feature flag đã ổn định.
- [ ] Thanh toán technical debt có kế hoạch.

---

## Definition of Done cho mỗi task

Một task chỉ được đánh dấu hoàn thành khi:

- [ ] Đúng phạm vi WBS.
- [ ] Đạt acceptance criteria.
- [ ] Không phá architecture hiện tại.
- [ ] Không phát sinh refactor ngoài phạm vi.
- [ ] Code đã format. Analyzer sạch. Test liên quan đã pass.
- [ ] UI dùng design tokens.
- [ ] Đã kiểm tra light/dark mode nếu có UI.
- [ ] Đã kiểm tra màn hình nhỏ và text scale.
- [ ] Đã kiểm tra loading, empty, error và success.
- [ ] Đã kiểm tra accessibility cơ bản.
- [ ] Đã cập nhật tài liệu và WBS.
- [ ] Đã được code review. CI pass.

---

## Thứ tự triển khai khuyến nghị

```
Business requirements
→ Use cases và business rules
→ WBS
→ Project foundation
→ Architecture boundaries
→ Theme và design tokens
→ Shared components tối thiểu
→ Router
→ Database/network foundation
→ Feature theo vertical slice
→ Automated tests
→ Pixel comparison
→ CI/CD
→ Internal testing
→ Production release
→ Monitoring và cải tiến
```
