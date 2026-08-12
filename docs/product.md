# Product requirements — memox

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Xác định sản phẩm là gì, cho ai, chạy trên đâu, và phạm vi MVP đến đâu |
| **Scope** | Vấn đề, người dùng, quyết định nền tảng, phạm vi MVP, luồng nghiệp vụ chính. Ngoài phạm vi: cách triển khai |
| **Source of truth for** | Phạm vi MVP · phân loại must/should/nice/out · quyết định platform, data posture, auth, dữ liệu nhạy cảm |
| **Depends on** | `document-conventions.md` |
| **Updated by task** | M99.19 (Import card: N1 nửa import thành task đang triển khai) |
| **Last updated** | 2026-08-12 |

## Problem

Người học từ vựng quên phần lớn những gì vừa học nếu ôn tập không đúng thời
điểm. Ôn thủ công bằng sổ tay hoặc file không cho biết *khi nào* cần ôn lại từ
nào, nên người học hoặc ôn quá sớm (lãng phí) hoặc quá muộn (đã quên).

## Target users

| Group | Context | What they need | Not the target |
|---|---|---|---|
| Người tự học từ vựng | Học lẻ trên điện thoại, thời gian rời rạc, kết nối không ổn định | Ôn đúng thời điểm, dùng được mọi lúc kể cả offline | Lớp học có giáo viên quản lý |
| Người ôn thi | Khối lượng từ lớn, có deadline | Theo dõi tiến độ, ưu tiên từ sắp quên | Người cần nội dung biên soạn sẵn |

**Đã chốt:** người dùng tự tạo nội dung, **và** app cung cấp starter deck dưới
dạng template để người dùng sao chép về (AD-07). Nội dung starter hiện tại là
fixture của dự án, chỉ phục vụ development và test — không phải nội dung
production (BR-87). Import/export vẫn ở nice-to-have.

## Core value

Ôn đúng từ vào đúng thời điểm, hoạt động đầy đủ khi không có mạng.

## Platform decisions

| Decision | Choice | Consequence |
|---|---|---|
| Android | **có** — target duy nhất của bản release đầu | min SDK 23+ (yêu cầu của `flutter_secure_storage` khi cần sau này) |
| iOS | **hoãn** — sau khi Android ổn định về UX, Drift migration, test | Không cần macOS runner trong CI giai đoạn đầu → tiết kiệm runner minutes |
| Web | **chỉ dùng cho development** | Review UI và chạy E2E/visual regression bằng Flutter Web + Playwright. **Không phải production target** — không tối ưu responsive cho desktop, không phát hành |
| Desktop | không | ngoài phạm vi hiện tại |
| Data posture | **local-first, backend-ready** | Drift là source of truth. Xem `architecture.md` |
| Authentication | **không có ở MVP, kiến trúc auth-ready** | Một local profile trên thiết bị. Xem `architecture.md` |
| Roles & permissions | không, kể cả sau khi có auth | Chỉ một loại user khi backend xuất hiện |

Hệ quả quan trọng của việc Web là dev-only: nó là **công cụ test**, không phải
target. Nghĩa là không đánh đổi thiết kế Android để Web đẹp hơn, nhưng cũng
không được dùng plugin chặn Web build — nếu Web không build được thì mất luôn
kênh E2E.

## Sensitive data

| Data | Why sensitive | Protection |
|---|---|---|
| Nội dung deck và flashcard người dùng tạo | Dữ liệu cá nhân | Chỉ trên thiết bị ở MVP. **Không log nội dung ở bất kỳ level nào** |
| Ghi chú | Dữ liệu cá nhân | Như trên |
| Lịch sử học (`study_answers`) | Suy ra được thói quen và thời gian sử dụng | Không gửi ra ngoài ở MVP; không đưa vào analytics |
| File import | Có thể chứa nội dung ngoài phạm vi app | Xử lý trong bộ nhớ ứng dụng; không để lại bản sao ở thư mục dùng chung |
| Hình ảnh, audio | Media cá nhân | Lưu trong **thư mục riêng của ứng dụng**, không phải bộ nhớ dùng chung |
| Dữ liệu backup / export | Chứa toàn bộ những thứ trên | **Chỉ tạo khi người dùng chủ động yêu cầu** — không tự động, không chạy nền |
| Email, access token, refresh token | Định danh và quyền truy cập | Chưa tồn tại ở MVP. Khi có backend: `flutter_secure_storage`, **không** lưu trong Drift, không xuất hiện trong log, xoá khi logout |

Ở MVP không có dữ liệu rời khỏi thiết bị, nên rủi ro chủ yếu là **log** — và đó
là chỗ dễ vi phạm nhất, vì log nội dung là phản xạ tự nhiên khi debug. Vì thế nó
là quy tắc (BR-32), không phải sự cẩn thận.

**Chưa mã hoá database ở MVP** — dữ liệu học từ vựng không đủ nhạy cảm để trả giá
bằng độ phức tạp của SQLCipher. Nhưng việc mở kết nối database nằm sau một chỗ
duy nhất, để bổ sung mã hoá sau là sửa một hàm (AD-08). Cần xem lại quyết định
này nếu app hỗ trợ ghi chú cá nhân tự do hoặc tài liệu công việc.

---

# MVP scope

Nguyên tắc: MVP là **một vertical slice chạy được từ Drift đến màn hình**, đủ để
chứng minh kiến trúc local-first và migration hoạt động. Không phải bản đầy đủ
tính năng.

## Must-have

| # | Feature | Done when |
|---|---|---|
| M1 | Tạo/sửa/xoá deck | Deck tồn tại sau khi restart app; xoá deck xoá cascade toàn bộ card của nó |
| M2 | Tạo/sửa/xoá card trong deck | Card có mặt trước/sau; sửa không làm mất lịch sử ôn tập |
| M3 | Phiên học theo lịch SRS | Chỉ hiện card đến hạn; đánh giá kết quả cập nhật lịch ôn lần sau |
| M4 | Danh sách deck với tiến độ | Mỗi deck hiện số card đến hạn hôm nay |
| M5 | Hoạt động đầy đủ offline | Bật chế độ máy bay, mọi chức năng trên vẫn chạy bình thường |

### StudyMode — một trục riêng, không phải thuật toán

App có **hai trục độc lập**, và việc tách chúng là quyết định sản phẩm chứ không
phải chi tiết kỹ thuật:

| Trục | Là gì | Ai chọn |
|---|---|---|
| **Thuật toán SRS** | `eight_box` · `sm2` — quyết định **khi nào** thẻ quay lại | chọn một lần lúc tạo root deck, khoá sau lượt học đầu (BR-13) |
| **StudyMode** | `browse` · `self_assess` · `match` · `guess` · `recall` · `fill` — quyết định **cách** thẻ được hỏi | không ai chọn: một phiên chạy chuỗi stage cố định của thuật toán (BR-109, BR-110) |

**Hai loại phiên, tách hẳn** (BR-142):

| | Học mới | Ôn tập |
|---|---|---|
| Thẻ | chưa học xong lần đầu | đã học xong **và** đến hạn |
| Cách hỏi | chuỗi stage cố định | một mode người dùng chọn |
| Đổi lịch | không, cho tới khi xong chuỗi | có, mỗi thẻ một lượt |

**Chỉ lần học đầu tiên mới đi qua cả chuỗi.** Từ lần thứ hai, thẻ vào ôn tập và
người học chọn cách ôn. Đó là quyết định về **áp lực**: bắt đi lại năm cách hỏi cho
một thẻ đã quen là bắt làm bài tập, không phải ôn tập.

**Chuỗi của phiên học mới** (BR-109, BR-110):

| Thuật toán | Chuỗi stage |
|---|---|
| `eight_box` | `browse` → `match` → `guess` → `recall` → `fill` |
| `sm2` | `browse` → `self_assess` |

Bốn stage chấm điểm sinh tín hiệu **nhị phân** — đúng hoặc sai — khớp tự nhiên
với hai action của `eight_box`, nhưng chỉ nuôi được hai trong bốn mức của `sm2`.
Nên `sm2` dùng `self_assess`: người học lật thẻ và tự chấm, đúng luồng M3 mô tả.

**`browse` và `self_assess` tách nhau vì chúng là hai việc khác nhau.** `browse`
hiện cả hai mặt cùng lúc để làm quen, không chấm và không đổi lịch (BR-111);
`self_assess` che mặt sau cho tới khi người học lật, rồi nhận đánh giá của chính
họ. Một cái tên ôm cả hai là thứ sẽ phải giải thích lại ở mọi test và mọi màn hình.

**Phạm vi:** `browse` và `self_assess` thuộc MVP (M3). Bốn stage chấm điểm là **định hướng đã chốt
về khái niệm, chưa phân loại must/should/nice** — chúng cần ngưỡng dữ liệu tối
thiểu riêng và một câu trả lời cho việc một lượt của chúng ghi vào lịch thế nào.
Kiến trúc chuẩn bị cho cả năm từ đầu; UI hiện đúng số mode đang có, và màn
chọn mode chỉ xuất hiện khi có mode thứ hai.

## Should-have

| # | Feature | Done when |
|---|---|---|
| S1 | Tìm kiếm card trong deck | Tìm theo nội dung mặt trước/sau |
| S2 | Thống kê ôn tập cơ bản | Số card đã ôn, streak theo ngày |
| S3 | Đảo chiều card (nghĩa → từ) | Ôn được cả hai chiều |

## Nice-to-have

| # | Feature | Notes |
|---|---|---|
| N1 | Import/export | Import CSV/TSV/XLSX **đã triển khai** (M99.19, UC-10, AD-20). Export vẫn nice-to-have |
| N2 | Nhắc nhở ôn tập hằng ngày | Cần notification permission |
| N3 | Tag/phân loại card | |

## Explicitly out of MVP

| Feature | Why deferred | Revisit when |
|---|---|---|
| Đăng nhập / tài khoản | Không có backend; thêm auth lúc này là xây UI cho thứ chưa dùng được | Khi Spring Boot backend sẵn sàng |
| Đồng bộ đa thiết bị | Cần backend và conflict resolution | Cùng lúc với auth |
| iOS | Ổn định Android trước để tránh sửa lỗi trên hai nền tảng cùng lúc | Sau khi Android ổn định về UX + migration + test |
| Phân quyền theo role | Chỉ có một loại user, kể cả sau khi có auth | Chưa có kế hoạch |
| Chia sẻ deck giữa người dùng | Cần backend | Sau đồng bộ |
| Audio / hình ảnh trong card | Kéo theo lưu trữ file, đồng bộ file, nén ảnh — một khối lượng riêng | Sau MVP |

## Điều hướng top-level

App dùng đúng **bốn** destination ở bottom navigation, thứ tự cố định:
**Thư viện (Library) · Học (Study) · Tiến độ (Progress) · Cài đặt (Settings)**.
Nhãn tab đầu là "Thư viện" — cả cây deck, thẻ bên trong và luồng starter —
trong khi branch nội bộ và màn hình gốc của nó vẫn là Decks.
Quyết định, ràng buộc placeholder và các phương án bị loại nằm ở AD-19.

- Cold start mở Decks (UC-06).
- Progress và Settings hiện chỉ là scaffold/placeholder: có tab và route
  **không** có nghĩa hai feature này đã hoàn thành. Thống kê vẫn là
  should-have (S2); tùy chọn ứng dụng chưa có nghiệp vụ nào được chốt.
- Thư viện starter (M6) là child flow bên trong tab Thư viện (branch Decks), không phải tab riêng.
- Không có tab Profile chừng nào chưa có auth/profile domain — nhất quán với
  "Đăng nhập / tài khoản" ở Explicitly out of MVP.

## Primary business flows

1. **Tạo nội dung**: mở app → tạo deck → thêm card → deck xuất hiện trong danh
   sách với số card đến hạn.
2. **Ôn tập** (luồng chính, chạy hằng ngày): mở app → thấy deck có card đến hạn
   → vào phiên ôn → xem mặt trước → lật → tự đánh giá → card được xếp lịch lại →
   hết card đến hạn → tổng kết phiên.

Luồng 2 là vertical slice đầu tiên nên xây, vì nó chạm vào toàn bộ chiều sâu
kiến trúc: Drift query có index theo hạn ôn, business logic SRS ở domain, state
matrix đầy đủ ở presentation (kể cả empty — "hôm nay không còn gì để ôn", là
trạng thái người dùng gặp thường xuyên nhất sau vài tuần).

## Quyết định đã chốt (2026-07-28)

**Thuật toán SRS: hai lựa chọn, chọn theo deck.** MVP hỗ trợ `eight_box` và
`sm2`. Mỗi deck **bắt buộc chọn một** khi tạo. Sub-deck kế thừa scheduler của
root deck và không chọn riêng.

**Scheduler bị khoá sau lượt học đầu tiên.** Trước đó đổi tự do; sau đó muốn
đổi phải **Reset learning progress**. Lý do: đổi thuật toán giữa chừng đặt ra
những câu hỏi không có câu trả lời trung thực — box 5 tương ứng ease factor nào,
history theo luật cũ còn giá trị gì. Mọi ánh xạ đều là bịa đặt. Khoá-và-reset
thừa nhận điều đó thẳng thắn và để người dùng biết rõ mình đánh đổi cái gì.

**Reset giữ nguyên** deck, sub-deck, flashcard, media, tag và nội dung; **xoá**
lịch ôn, ngày đến hạn, box/ease factor/interval, trạng thái thành thạo và phiên
đang dở. Study answers cũ được giữ để tham khảo nhưng không dùng cho chu kỳ mới.
Mỗi deck có `scheduler_generation` tăng sau mỗi lần reset, và kết quả từ session
thuộc generation cũ bị từ chối. Xem AD-09.

**Hai scheduler có hai tập action khác nhau** — đây là điểm dễ làm sai nhất:

| Scheduler | Action |
|---|---|
| `eight_box` | `forgotten`, `remembered` |
| `sm2` | `again`, `hard`, `good`, `easy` |

UI phải render nút từ `supportedActions` của scheduler thuộc deck, không hardcode.
Mỗi lượt đánh giá — kể cả lượt luyện lại trong phiên — được ghi vào study
answers kèm scheduler type và generation.

**Nội dung: starter deck quản lý như template.** Người dùng chọn dùng thì app tạo
một **bản sao** vào dữ liệu cá nhân; bản sao là deck bình thường. Cập nhật
template ở bản app mới không ghi đè nội dung người dùng đã sửa. Xem AD-07 và
UC-01. Nội dung starter hiện tại là fixture cho development/test (BR-87).

**Cấu trúc deck: cây nhiều cấp, mỗi deck chỉ chứa một loại.** Root deck chỉ chứa
deck con. Deck con mới tạo chưa xác định loại; lần tạo phần tử con đầu tiên xác
lập nó thành "chứa card" hoặc "chứa deck con", và sau đó không trộn lẫn. Người
dùng không phải chọn loại lúc tạo deck — lúc đó họ chưa biết. Xem AD-10, UC-08.

Hệ quả lên MVP scope: **M6 trở thành must-have**, vì thư viện starter là thứ
người dùng thấy đầu tiên và nó định hình toàn bộ trải nghiệm mở app lần đầu.

| # | Feature | Done when |
|---|---|---|
| M6 | Thư viện starter deck với sao chép vào dữ liệu cá nhân | Cài mới → mở app → chọn một starter deck → ôn được ngay. Sửa bản sao rồi cập nhật app lên version template mới thì nội dung đã sửa **không** bị ghi đè. Mở lại app **không** tạo deck trùng |

Nửa import của N1 đã triển khai ở M99.19 (UC-10, AD-20): thư
viện starter giải quyết "app trống lúc mới cài", nhưng không giải quyết "bộ thẻ
của tôi đang nằm trong một file" — và nhập tay từng card không phải câu trả lời
cho một file nghìn dòng. Export vẫn ở nice-to-have.
