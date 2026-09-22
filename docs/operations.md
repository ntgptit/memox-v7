# Operations — build, flavor, và những gì chưa tồn tại để phát hành

| | |
|---|---|
| **Status** | active |
| **Purpose** | Ghi lại đúng những gì đã commit về build/đóng gói/cấu hình, và nói thẳng cái gì **chưa** có — vì khoảng cách giữa "CI xanh" và "cài được lên máy người dùng" ở repo này chưa được bắc cầu |
| **Scope** | Flavor, entrypoint, ký ứng dụng, đóng gói, cấu hình runtime của cả app và `memox-api`. Ngoài phạm vi: quy trình release đầy đủ (`release-checklist.md`, thuộc Phase 20–21), gate CI (`verification.md`) |
| **Source of truth for** | Bản đồ flavor → entrypoint → applicationId · trạng thái ký release · khoảng trống đóng gói/triển khai đã kiểm |
| **Depends on** | `document-conventions.md`, `product.md`, `verification.md` |
| **Updated by task** | project-documentation FULL_SYNC (no WBS id) |
| **Last updated** | 2026-09-23 |

---

## 1 · Ba flavor, bốn entrypoint

`android/app/build.gradle.kts` khai ba flavor trên dimension `environment`:

| Flavor | applicationId | Tên hiển thị | Entrypoint |
|---|---|---|---|
| `development` | `com.ntgptit.memox.dev` | MemoX Dev | `lib/main_development.dart` |
| `staging` | `com.ntgptit.memox.staging` | MemoX Staging | `lib/main_staging.dart` |
| `production` | `com.ntgptit.memox` (base, không suffix) | MemoX | `lib/main_production.dart` |

`lib/main.dart` là entrypoint thứ tư và nó tồn tại vì một lý do cụ thể:
`flutter run` và `flutter build web` **không nhận flavor**. Nó resolve sang config
`development` để hai lệnh đó chạy được; một bản đã ship luôn đi qua một trong ba
`main_<flavor>.dart`.

Hệ quả thực tế: build Android **phải** có `--flavor`, vì Gradle không chọn được
variant nếu thiếu. Đây cũng là lý do bộ integration test yêu cầu nó.

## 2 · Ký release: chưa có, và đang dùng khoá debug

Đây là khoảng trống quan trọng nhất trong tài liệu này.

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Bản `release` **đang ký bằng khoá debug**. Kiểm trong repo: không có `.jks`,
không có `key.properties`, không có `Fastfile`. Nghĩa là:

- `flutter run --release` chạy được — đó là điều dòng TODO nhắm tới;
- một APK sinh ra từ đây **không lên Play Store được**, và cũng không nên đem
  phân phối, vì khoá debug là công khai;
- việc tạo keystore và quy trình giữ nó là việc chưa làm, thuộc Phase 20–21.

`version: 1.0.0+1` trong `pubspec.yaml` là giá trị khởi tạo, chưa có quy tắc tăng
nào được commit.

## 3 · Đóng gói: một workflow thủ công, không phải một pipeline

`.github/workflows/build-apk.yml`, trigger `workflow_dispatch` với input flavor.
Nó sinh một APK **debug-signed**, tuỳ chọn đính vào một GitHub release ở trạng
thái **draft**, tag `<flavor>-<sha8>` — không bao giờ tự publish.

Comment trong chính workflow nói rõ nó *"builds no contract, gates no merge"* —
nó không phải một gate và không nên bị đọc như một.

Không có kênh phân phối nào khác đã commit: không Play Console track, không
fastlane lane, không staged rollout.

## 4 · `memox-api`: chạy được local, không triển khai được

```bash
cd memox-api
cp .env.example .env          # rồi đặt MEMOX_DB_PASSWORD
docker compose up -d
./mvnw -Dspring-boot.run.profiles=local spring-boot:run
```

Cấu hình theo profile:

| Profile | Hành vi |
|---|---|
| `local` | `MEMOX_DB_URL` mặc định `jdbc:postgresql://localhost:5432/memox`, username mặc định, password **không** có mặc định |
| `prod` | Cả ba biến `MEMOX_DB_*` bắt buộc, **không** mặc định — thiếu là fail ngay. Hikari pool được chỉnh. Swagger UI và api-docs **tắt** |

**Không có cổng nào được override** — Spring Boot dùng mặc định 8080.

**Không có Dockerfile, không có manifest triển khai, không có CD workflow** cho
service này. `compose.yaml` dựng **database**, không đóng gói ứng dụng. Cách duy
nhất đã commit để chạy nó là Maven trực tiếp. `prod` profile sẵn sàng ở mức
Spring, nhưng không có gì trong repo gọi tới nó.

### Một cái bẫy đã được ghi lại

`compose.yaml` dùng cổng 5432 và máy này chạy sẵn service Windows
`postgresql-x64-17` ở đúng cổng đó. Chạy một trong hai, hoặc đặt `MEMOX_DB_PORT`
**và** sửa cổng bên trong `MEMOX_DB_URL` cho khớp — hai biến đó không tự nối với
nhau, và lệch nhau thì hiện ra thành `connection refused`.

## 5 · Cấu hình runtime của app

| Thứ | Ở đâu |
|---|---|
| Dart SDK | `^3.12.2` (`pubspec.yaml`) |
| Generated code | **Không commit.** `flutter pub get` + `dart run build_runner build --delete-conflicting-outputs` trước khi bất cứ thứ gì chạy |
| Localization | `l10n.yaml` — `app_en.arb` là template và fallback; `required-resource-attributes: true` nên key thiếu làm **fail build**, không degrade im lặng |
| Web | Build được là bắt buộc (kênh E2E), nhưng không phải production target (AD-04) |

## 6 · Cái gì còn thiếu để gọi là phát hành được

Nói rõ ở đây vì `docs/README.md` xếp `release-checklist.md` vào "chưa viết" và
người đọc dễ hiểu nhầm rằng chỉ thiếu tài liệu:

- keystore release và quy trình bảo quản nó;
- quy tắc tăng `versionCode`/`versionName`;
- R8/shrinking và symbolication cho crash của bản release;
- một kênh phân phối (Play Console track, staged rollout);
- với backend: bất kỳ cách đóng gói nào.

Không cái nào trong số đó là khiếm khuyết — chúng thuộc Phase 20–21 và chưa tới
lượt. Điều đáng tránh là tin rằng chúng đã xong vì CI xanh.
